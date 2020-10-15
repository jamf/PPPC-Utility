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

@objc class Model: NSObject {

    var usingLegacyAllowKey = true

    @objc dynamic var current: Executable?
    @objc dynamic static let shared = Model()
    @objc dynamic var identities: [SigningIdentity] = []
    @objc dynamic var selectedExecutables: [Executable] = []

    func getAppleEventChoices(executable: Executable) -> [Executable] {
        var executables: [Executable] = []

        loadExecutable(url: URL(fileURLWithPath: "/System/Library/CoreServices/System Events.app")) { result in
            switch result {
            case .success(let executable):
                executables.append(executable)
            case .failure(let error):
                print(error)
            }
        }

        loadExecutable(url: URL(fileURLWithPath: "/System/Library/CoreServices/SystemUIServer.app")) { result in
            switch result {
            case .success(let executable):
                executables.append(executable)
            case .failure(let error):
                print(error)
            }
        }

        loadExecutable(url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")) { result in
            switch result {
            case .success(let executable):
                executables.append(executable)
            case .failure(let error):
                print(error)
            }
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
typealias LoadExecutableCompletion = ((LoadExecutableResult) -> Void)

extension Model {

    func requiresAuthorizationKey() -> Bool {
        return selectedExecutables.contains { exe -> Bool in
            return exe.policy.allPolicyValues().contains { value -> Bool in
                return value == TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue
            }
        }
    }

    /// Will convert any Authorization key values to the legacy Allowed key
    func changeToUseLegacyAllowKey() {
        usingLegacyAllowKey = true
        selectedExecutables.forEach { exe in
            if exe.policy.ListenEvent == TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue {
                exe.policy.ListenEvent = "-"
            }
            if exe.policy.ScreenCapture == TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue {
                exe.policy.ScreenCapture = "-"
            }
        }
    }

    // TODO - refactor this method so it isn't so complex
    // swiftlint:disable:next cyclomatic_complexity
    func loadExecutable(url: URL, completion: @escaping LoadExecutableCompletion) {
        let executable = Executable()

        if let bundle = Bundle(url: url) {
            guard let identifier = bundle.bundleIdentifier else {
                return completion(.failure(.identifierNotFound))
            }
            executable.identifier = identifier
            let info = bundle.infoDictionary
            executable.displayName = (info?["CFBundleName"] as? String) ?? executable.identifier
            if let resourcesURL = bundle.resourceURL {
                if let definedIconFile = info?["CFBundleIconFile"] as? String {
                    var iconURL = resourcesURL.appendingPathComponent(definedIconFile)
                    if iconURL.pathExtension.isEmpty {
                        iconURL.appendPathExtension("icns")
                    }
                    executable.iconPath = iconURL.path
                } else {
                    executable.iconPath = resourcesURL.appendingPathComponent("DefaultAppIcon.icns").path
                }

                if !FileManager.default.fileExists(atPath: executable.iconPath) {
                    switch url.pathExtension {
                    case "app":
                        executable.iconPath = IconFilePath.application
                    case "bundle":
                        executable.iconPath = IconFilePath.kext
                    case "xpc":
                        executable.iconPath = IconFilePath.kext
                    default:
                        executable.iconPath = IconFilePath.unknown
                    }
                }
            } else {
                return completion(.failure(.resourceURLNotFound))
            }
        } else {
            executable.identifier = url.path
            executable.displayName = url.lastPathComponent
            executable.iconPath = IconFilePath.binary
        }

        if let alreadyFoundExecutable = store[executable.identifier] {
            return completion(.success(alreadyFoundExecutable))
        }

        do {
            executable.codeRequirement = try SecurityWrapper.copyDesignatedRequirement(url: url)
            store[executable.identifier] = executable
            return completion(.success(executable))
        } catch {
            return completion(.failure(.codeRequirementError(description: error.localizedDescription)))
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

        return TCCProfile(organization: organization,
                          identifier: identifier,
                          displayName: displayName,
                          payloadDescription: payloadDescription,
                          services: services)
    }

    func importProfile(tccProfile: TCCProfile) {
        if let content = tccProfile.content.first {
            self.cleanUpAndRemoveDependencies()

            self.importedTCCProfile = tccProfile

            for (key, policies) in content.services {
                getExecutablesFromAllPolicies(policies: policies)

                for policy in policies {
                    let executable = getExecutableFromSelectedExecutables(bundleIdentifier: policy.identifier)
                    if key == ServicesKeys.appleEvents.rawValue {
                        if let source = executable,
                            let rIdentifier = policy.receiverIdentifier,
                            let rCodeRequirement = policy.receiverCodeRequirement {
                            let destination = getExecutableFrom(identifier: rIdentifier, codeRequirement: rCodeRequirement)
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
        var policy = TCCPolicy(identifier: executable.identifier,
                         codeRequirement: executable.codeRequirement,
                         receiverIdentifier: event?.destination.identifier,
                         receiverCodeRequirement: event?.destination.codeRequirement)
        if usingLegacyAllowKey {
            switch value {
            case TCCProfileDisplayValue.allow.rawValue:
                policy.allowed = true
            case TCCProfileDisplayValue.deny.rawValue:
                policy.allowed = false
            default:
                return nil
            }
        } else {
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
        }
        return policy
    }

    func getExecutablesFromAllPolicies(policies: [TCCPolicy]) {
        for tccPolicy in policies {
            if getExecutableFromSelectedExecutables(bundleIdentifier: tccPolicy.identifier) == nil {
                let executable = getExecutableFrom(identifier: tccPolicy.identifier, codeRequirement: tccPolicy.codeRequirement)
                self.selectedExecutables.append(executable)
            }
        }
    }

    func getExecutableFromSelectedExecutables(bundleIdentifier: String) -> Executable? {
        for executable in selectedExecutables where executable.identifier == bundleIdentifier {
            return executable
        }
        return nil
    }

    func getExecutableFrom(identifier: String, codeRequirement: String) -> Executable {
        var executable = Executable(identifier: identifier, codeRequirement: codeRequirement)
        findExecutableOnComputerUsing(bundleIdentifier: identifier) { result in
            switch result {
            case .success(let goodExecutable):
                executable = goodExecutable
            case .failure(let error):
                print(error)
            }
        }

        return executable
    }

    private func findExecutableOnComputerUsing(bundleIdentifier: String, completion: @escaping LoadExecutableCompletion) {
        var pathToLoad: String?
        if bundleIdentifier.contains("/") {
            pathToLoad = bundleIdentifier
        } else {
            if let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: bundleIdentifier) {
                pathToLoad = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
            }
        }

        if let pathForURL = pathToLoad, let fileURL = URL(string: "file://\(pathForURL)") {
            self.loadExecutable(url: fileURL) { result in
                switch result {
                case .success(let executable):
                    return completion(.success(executable))
                case .failure(let error):
                    return completion(.failure(error))
                }
            }
        }
        return completion(.failure(.executableNotFound))
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
