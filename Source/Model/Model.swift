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
                    executable.iconPath = resourcesURL.appendingPathComponent("AppIcon.icns").path
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
        var services = TCCServices()
        
        selectedExecutables.forEach { executable in
            if let policy = policyFromString(executable: executable, value: executable.addressBookPolicyString) {
                services.addressBook = services.addressBook ?? []
                services.addressBook?.append(policy)
            }
            
            if let policy = policyFromString(executable: executable, value: executable.photosPolicyString) {
                services.photos = services.photos ?? []
                services.photos?.append(policy)
            }
            
            if let policy = policyFromString(executable: executable, value: executable.remindersPolicyString) {
                services.reminders = services.reminders ?? []
                services.reminders?.append(policy)
            }
            
            if let policy = policyFromString(executable: executable, value: executable.calendarPolicyString) {
                services.calendar = services.calendar ?? []
                services.calendar?.append(policy)
            }
            
            
            if let policy = policyFromString(executable: executable, value: executable.accessibilityPolicyString) {
                services.accessibility = services.accessibility ?? []
                services.accessibility?.append(policy)
            }
            
            
            if let policy = policyFromString(executable: executable, value: executable.postEventsPolicyString) {
                services.postEvent = services.postEvent ?? []
                services.postEvent?.append(policy)
            }
            
            if let policy = policyFromString(executable: executable, value: executable.adminFilesPolicyString) {
                services.adminFiles = services.adminFiles ?? []
                services.adminFiles?.append(policy)
            }
            
            if let policy = policyFromString(executable: executable, value: executable.allFilesPolicyString) {
                services.allFiles = services.allFiles ?? []
                services.allFiles?.append(policy)
            }
            
            if let policy = policyFromString(executable: executable, value: executable.cameraPolicyString) {
                services.camera = services.camera ?? []
                services.camera?.append(policy)
            }
            
            if let policy = policyFromString(executable: executable, value: executable.microphonePolicyString) {
                services.microphone = services.microphone ?? []
                services.microphone?.append(policy)
            }
            
            if let policy = policyFromString(executable: executable, value: executable.fileProviderPolicyString) {
                services.fileProviderPresence = services.fileProviderPresence ?? []
                services.fileProviderPresence?.append(policy)
            }

            if let policy = policyFromString(executable: executable, value: executable.listenEventPolicyString) {
                services.listenEvent = services.listenEvent ?? []
                services.listenEvent?.append(policy)
            }

            if let policy = policyFromString(executable: executable, value: executable.mediaLibraryPolicyString) {
                services.mediaLibrary = services.mediaLibrary ?? []
                services.mediaLibrary?.append(policy)
            }

            if let policy = policyFromString(executable: executable, value: executable.screenCapturePolicyString) {
                services.screenCapture = services.screenCapture ?? []
                services.screenCapture?.append(policy)
            }

            if let policy = policyFromString(executable: executable, value: executable.speechRecognitionPolicyString) {
                services.speechRecognition = services.speechRecognition ?? []
                services.speechRecognition?.append(policy)
            }

            if let policy = policyFromString(executable: executable, value: executable.desktopFolderPolicyString) {
                services.desktopFolder = services.desktopFolder ?? []
                services.desktopFolder?.append(policy)
            }

            if let policy = policyFromString(executable: executable, value: executable.documentsFolderPolicyString) {
                services.documentsFolder = services.documentsFolder ?? []
                services.documentsFolder?.append(policy)
            }

            if let policy = policyFromString(executable: executable, value: executable.downloadsFolderPolicyString) {
                services.downloadsFolder = services.downloadsFolder ?? []
                services.downloadsFolder?.append(policy)
            }

            if let policy = policyFromString(executable: executable, value: executable.networkVolumesPolicyString) {
                services.networkVolumes = services.networkVolumes ?? []
                services.networkVolumes?.append(policy)
            }

            if let policy = policyFromString(executable: executable, value: executable.removableVolumesPolicyString) {
                services.removableVolumes = services.removableVolumes ?? []
                services.removableVolumes?.append(policy)
            }

            executable.appleEvents.forEach { event in
                let policy = TCCPolicy(identifier: executable.identifier,
                                       codeRequirement: executable.codeRequirement,
                                       allowed: event.value,
                                       receiverIdentifier: event.destination.identifier,
                                       receiverCodeRequirement: event.destination.codeRequirement)
                services.appleEvents = services.appleEvents ?? []
                services.appleEvents?.append(policy)
                
            }
        }
        
        return TCCProfile(organization: organization,
                          identifier: identifier,
                          displayName: displayName,
                          payloadDescription: payloadDescription,
                          services: services)
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
}
