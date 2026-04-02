//
//  Model.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2018 Jamf Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Cocoa
import OSLog

@objc class Model: NSObject {

    @objc dynamic var current: Executable?
    @objc dynamic static let shared: Model = {
        MainActor.assumeIsolated { Model() }
    }()
    @objc dynamic var identities: [SigningIdentity] = []
    @objc dynamic var selectedExecutables: [Executable] = []

    let logger = Logger.Model

    func getAppleEventChoices(executable: Executable) async -> [Executable] {
        var executables: [Executable] = []

        do {
            executables.append(try await loadExecutable(url: URL(fileURLWithPath: "/System/Library/CoreServices/System Events.app")))
        } catch {
            self.logger.error("\(error)")
        }

        do {
            executables.append(try await loadExecutable(url: URL(fileURLWithPath: "/System/Library/CoreServices/SystemUIServer.app")))
        } catch {
            self.logger.error("\(error)")
        }

        do {
            executables.append(try await loadExecutable(url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")))
        } catch {
            self.logger.error("\(error)")
        }

        let others = store.values.filter { $0 != executable && !Set(executables).contains($0) }
        executables.append(contentsOf: others)

        return executables
    }

    var store: [String: Executable] = [:]
    public var importedTCCProfile: TCCProfile?
}

// MARK: Loading executable

struct IconFilePath {
    static let binary = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ExecutableBinaryIcon.icns"
    static let application = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"
    static let kext = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"
    static let unknown = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericQuestionMarkIcon.icns"
}

typealias LoadExecutableResult = Result<Executable, LoadExecutableError>

extension Model {

    func loadExecutable(url: URL) async throws -> Executable {
        let executable = Executable()

        if let bundle = Bundle(url: url) {
            switch populateFromBundle(executable, bundle: bundle, url: url) {
            case .failure(let error):
                throw error
            case .success:
                break
            }
        } else {
            populateFromPath(executable, url: url)
        }

        if let alreadyFoundExecutable = store[executable.identifier] {
            return alreadyFoundExecutable
        }

        do {
            executable.codeRequirement = try await SecurityWrapper.copyDesignatedRequirement(url: url)
            store[executable.identifier] = executable
            return executable
        } catch {
            throw LoadExecutableError.codeRequirementError(description: error.localizedDescription)
        }
    }

    private func populateFromBundle(_ executable: Executable, bundle: Bundle, url: URL) -> Result<Void, LoadExecutableError> {
        guard let identifier = bundle.bundleIdentifier else {
            return .failure(.identifierNotFound)
        }
        executable.identifier = identifier

        let info = bundle.infoDictionary
        executable.displayName = (info?["CFBundleName"] as? String) ?? executable.identifier

        guard let resourcesURL = bundle.resourceURL else {
            return .failure(.resourceURLNotFound)
        }

        executable.iconPath = resolveIconPath(info: info, resourcesURL: resourcesURL, url: url)
        return .success(())
    }

    private func populateFromPath(_ executable: Executable, url: URL) {
        executable.identifier = url.path
        executable.displayName = url.lastPathComponent
        executable.iconPath = IconFilePath.binary
    }

    private func resolveIconPath(info: [String: Any]?, resourcesURL: URL, url: URL) -> String {
        let candidatePath: String

        if let definedIconFile = info?["CFBundleIconFile"] as? String {
            var iconURL = resourcesURL.appendingPathComponent(definedIconFile)
            if iconURL.pathExtension.isEmpty {
                iconURL.appendPathExtension("icns")
            }
            candidatePath = iconURL.path
        } else {
            candidatePath = resourcesURL.appendingPathComponent("DefaultAppIcon.icns").path
        }

        if FileManager.default.fileExists(atPath: candidatePath) {
            return candidatePath
        }

        return fallbackIconPath(for: url.pathExtension)
    }

    private func fallbackIconPath(for pathExtension: String) -> String {
        switch pathExtension {
        case "app":
            return IconFilePath.application
        case "bundle", "xpc":
            return IconFilePath.kext
        default:
            return IconFilePath.unknown
        }
    }

}

// MARK: Exporting Profile

extension Model {

    func exportProfile(organization: String, identifier: String, displayName: String, payloadDescription: String) -> TCCProfile {
        var services = [String: [TCCPolicy]]()

        selectedExecutables.forEach { executable in

            let mirroredServices = Mirror(reflecting: executable.policy)

            for attr in mirroredServices.children {
                if let key = attr.label, let value = attr.value as? String {
                    if let policyToAppend = policyFromString(executable: executable, value: value) {
                        services[key] = services[key] ?? []
                        services[key]?.append(policyToAppend)
                    }
                }
            }

            executable.appleEvents.forEach { event in
                let policy = policyFromString(executable: executable, value: event.valueString, event: event)
                if let policy = policy {
                    let appleEventsKey = ServicesKeys.appleEvents.rawValue
                    services[appleEventsKey] = services[appleEventsKey] ?? []
                    services[appleEventsKey]?.append(policy)
                }
            }
        }

        return TCCProfile(
            organization: organization,
            identifier: identifier,
            displayName: displayName,
            payloadDescription: payloadDescription,
            services: services)
    }

    func importProfile(tccProfile: TCCProfile) async {
        if let content = tccProfile.content.first {
            self.cleanUpAndRemoveDependencies()

            self.importedTCCProfile = tccProfile

            for (key, policies) in content.services {
                await getExecutablesFromAllPolicies(policies: policies)

                for policy in policies {
                    let executable = getExecutableFromSelectedExecutables(bundleIdentifier: policy.identifier)
                    if key == ServicesKeys.appleEvents.rawValue {
                        if let source = executable,
                            let rIdentifier = policy.receiverIdentifier,
                            let rCodeRequirement = policy.receiverCodeRequirement
                        {
                            let destination = await getExecutableFrom(identifier: rIdentifier, codeRequirement: rCodeRequirement)
                            let allowed: Bool = (policy.allowed == true || policy.authorization == TCCPolicyAuthorizationValue.allow)
                            let appleEvent = AppleEventRule(source: source, destination: destination, value: allowed)
                            executable?.appleEvents.appendIfNew(appleEvent)
                        }
                    } else {
                        if policy.authorization == .allow || policy.allowed == true {
                            executable?.policy.setValue(TCCProfileDisplayValue.allow.rawValue, forKey: key)
                        } else if policy.authorization == .allowStandardUserToSetSystemService {
                            executable?.policy.setValue(TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue, forKey: key)
                        } else {
                            executable?.policy.setValue(TCCProfileDisplayValue.deny.rawValue, forKey: key)
                        }
                    }
                }
            }
        }
    }

    func policyFromString(executable: Executable, value: String, event: AppleEventRule? = nil) -> TCCPolicy? {
        var policy = TCCPolicy(
            identifier: executable.identifier,
            codeRequirement: executable.codeRequirement,
            receiverIdentifier: event?.destination.identifier,
            receiverCodeRequirement: event?.destination.codeRequirement)
        switch value {
        case TCCProfileDisplayValue.allow.rawValue:
            policy.authorization = .allow
        case TCCProfileDisplayValue.deny.rawValue:
            policy.authorization = .deny
        case TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue:
            policy.authorization = .allowStandardUserToSetSystemService
        default:
            return nil
        }
        return policy
    }

    func getExecutablesFromAllPolicies(policies: [TCCPolicy]) async {
        for tccPolicy in policies where getExecutableFromSelectedExecutables(bundleIdentifier: tccPolicy.identifier) == nil {
            let executable = await getExecutableFrom(identifier: tccPolicy.identifier, codeRequirement: tccPolicy.codeRequirement)
            self.selectedExecutables.append(executable)
        }
    }

    func getExecutableFromSelectedExecutables(bundleIdentifier: String) -> Executable? {
        for executable in selectedExecutables where executable.identifier == bundleIdentifier {
            return executable
        }
        return nil
    }

    func getExecutableFrom(identifier: String, codeRequirement: String) async -> Executable {
        var executable = Executable(identifier: identifier, codeRequirement: codeRequirement)
        do {
            executable = try await findExecutable(bundleIdentifier: identifier)
        } catch {
            self.logger.error("\(error)")
        }

        return executable
    }

    private func findExecutable(bundleIdentifier: String) async throws -> Executable {
        var urlToLoad: URL?
        if bundleIdentifier.contains("/") {
            urlToLoad = URL(string: "file://\(bundleIdentifier)")
        } else {
            urlToLoad = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        }

        if let fileURL = urlToLoad {
            return try await self.loadExecutable(url: fileURL)
        }
        throw LoadExecutableError.executableNotFound
    }

    private func cleanUpAndRemoveDependencies() {
        for executable in self.selectedExecutables {
            executable.appleEvents = []
            executable.policy = Policy()
        }
        self.selectedExecutables = []
        self.current = nil
        self.store.removeAll()
        self.importedTCCProfile = nil
    }
}
