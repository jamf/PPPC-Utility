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

class Model : NSObject {
    
    @objc dynamic var current: Executable?
    
    @objc dynamic static let shared = Model()
    @objc dynamic var identities: [SigningIdentity] = []
    @objc dynamic var selectedExecutables: [Executable] = []
    
    func getAppleEventChoices(executable: Executable) -> [Executable] {
        var executables: [Executable] = []
        if let executable = loadExecutable(url: URL(fileURLWithPath: "/System/Library/CoreServices/System Events.app")) {
            executables.append(executable)
        }
        
        if let executable = loadExecutable(url: URL(fileURLWithPath: "/System/Library/CoreServices/SystemUIServer.app")) {
            executables.append(executable)
        }
        
        if let executable = loadExecutable(url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")) {
            executables.append(executable)
        }
        
        let others = store.values.filter({ $0 != executable && !Set(executables).contains($0) })
        executables.append(contentsOf: others)

        return executables
    }

    var store: [String:Executable] = [:]
    public var importedTCCProfile: TCCProfile?
}

//  MARK: Loading executable

struct IconFilePath {
    static let binary = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ExecutableBinaryIcon.icns"
    static let application = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"
    static let kext = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"
    static let unknown = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericQuestionMarkIcon.icns"
}

extension Model {
    
    func loadExecutable(url: URL) -> Executable? {
        let executable = Executable()

        if let bundle = Bundle(url: url) {
            guard let identifier = bundle.bundleIdentifier else { return nil }
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
                    case "app":     executable.iconPath = IconFilePath.application
                    case "bundle":  executable.iconPath = IconFilePath.kext
                    case "xpc":     executable.iconPath = IconFilePath.kext
                    default:        executable.iconPath = IconFilePath.unknown
                    }
                }
            } else {
                return nil
            }
        } else {
            executable.identifier = url.path
            executable.displayName = url.lastPathComponent
            executable.iconPath = IconFilePath.binary
        }
        
        if let alreadyFoundExecutable = store[executable.identifier] {
            return alreadyFoundExecutable
        }
        
        do {
            executable.codeRequirement = try SecurityWrapper.copyDesignatedRequirement(url: url)
            store[executable.identifier] = executable
            return executable
        } catch {
            print("Failed to get designated requirement with error: \(error)")
            return nil
        }
    }
}

//  MARK: Exporting Profile

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
                let policy = TCCPolicy(identifier: executable.identifier,
                                       codeRequirement: executable.codeRequirement,
                                       allowed: event.value,
                                       receiverIdentifier: event.destination.identifier,
                                       receiverCodeRequirement: event.destination.codeRequirement)
                let appleEventsKey = ServicesKeys.appleEvents.rawValue
                services[appleEventsKey] = services[appleEventsKey] ?? []
                services[appleEventsKey]?.append(policy)
                
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
                        if let source = executable, let rIdentifier = policy.receiverIdentifier, let rCodeRequirement = policy.receiverCodeRequirement {
                            let destination = getExecutableFrom(identifier: rIdentifier, codeRequirement: rCodeRequirement)
                            let appleEvent = AppleEventRule(source: source, destination: destination, value: policy.allowed)
                            executable?.appleEvents.appendIfNew(appleEvent)
                        }
                    } else {
                        if policy.allowed {
                            executable?.policy.setValue("Allow", forKey: key)
                        } else {
                            executable?.policy.setValue("Deny", forKey: key)
                        }
                    }
                }
            }
        }
    }

    func policyFromString(executable: Executable, value: String) -> TCCPolicy? {
        let allowed: Bool
        switch value {
        case "Allow":   allowed = true
        case "Deny":    allowed = false
        default:        return nil
        }
        return TCCPolicy(identifier: executable.identifier,
                         codeRequirement: executable.codeRequirement,
                         allowed: allowed)
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
        for executable in selectedExecutables {
            if (executable.identifier == bundleIdentifier) {
                return executable
            }
        }
        return nil
    }

    
    func getExecutableFrom(identifier: String, codeRequirement: String) -> Executable {
        var executable = Executable(identifier: identifier, codeRequirement: codeRequirement)
        if let destExecutableFromComputer = findExecutableOnComputerUsing(bundleIdentifier: identifier) {
            executable = destExecutableFromComputer
        }
        return executable
    }

    private func findExecutableOnComputerUsing(bundleIdentifier: String) -> Executable?  {
        var pathToLoad: String?
        if bundleIdentifier.contains("/") {
            pathToLoad = bundleIdentifier
        } else {
            if let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: bundleIdentifier) {
                pathToLoad = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
            }
        }

        if let pathForURL = pathToLoad, let fileURL = URL(string: "file://\(pathForURL)") {
            let executable = self.loadExecutable(url: fileURL)
            return executable
        }
        return nil
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
