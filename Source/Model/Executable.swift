//
//  Executable.swift
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

import Foundation

@Observable
class Executable: Identifiable, Equatable, Hashable {
    let id = UUID()

    var iconPath: String = ""
    var displayName: String = ""
    var identifier: String = ""
    var codeRequirement: String = ""

    var policy: Policy = Policy()
    var appleEvents: [AppleEventRule] = []

    init() {}

    init(identifier: String, codeRequirement: String, _ displayName: String? = nil) {
        self.identifier = identifier
        self.codeRequirement = codeRequirement
        if let displayName = displayName {
            self.displayName = displayName
        } else {
            self.displayName = generateDisplayName(identifier: identifier)
        }
        self.iconPath = generateIconPath(identifier: identifier)
    }

    func generateDisplayName(identifier: String) -> String {
        var separatedBy = "."
        if identifier.contains("/") {
            separatedBy = "/"
        }
        let partNames = identifier.components(separatedBy: separatedBy)

        return partNames.last ?? identifier
    }

    func generateIconPath(identifier: String) -> String {
        if identifier.contains("/") {
            return IconFilePath.binary
        } else {
            return IconFilePath.application
        }
    }

    static func == (lhs: Executable, rhs: Executable) -> Bool {
        lhs.identifier == rhs.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

@Observable
class Policy {
    // swiftlint:disable identifier_name
    var AddressBook: String = "-"
    var Calendar: String = "-"
    var Reminders: String = "-"
    var Photos: String = "-"
    var Camera: String = "-"
    var Microphone: String = "-"
    var Accessibility: String = "-"
    var PostEvent: String = "-"
    var SystemPolicyAllFiles: String = "-"
    var SystemPolicySysAdminFiles: String = "-"
    var FileProviderPresence: String = "-"
    var ListenEvent: String = "-"
    var MediaLibrary: String = "-"
    var ScreenCapture: String = "-"
    var SpeechRecognition: String = "-"
    var SystemPolicyDesktopFolder: String = "-"
    var SystemPolicyDocumentsFolder: String = "-"
    var SystemPolicyDownloadsFolder: String = "-"
    var SystemPolicyNetworkVolumes: String = "-"
    var SystemPolicyRemovableVolumes: String = "-"
    // swiftlint:enable identifier_name

    func allPolicyValues() -> [String] {
        return [
            AddressBook, Calendar, Reminders, Photos, Camera, Microphone,
            Accessibility, PostEvent, SystemPolicyAllFiles, SystemPolicySysAdminFiles,
            FileProviderPresence, ListenEvent, MediaLibrary, ScreenCapture,
            SpeechRecognition, SystemPolicyDesktopFolder, SystemPolicyDocumentsFolder,
            SystemPolicyDownloadsFolder, SystemPolicyNetworkVolumes, SystemPolicyRemovableVolumes
        ]
    }

    subscript(key: String) -> String {
        get {
            switch key {
            case "AddressBook": return AddressBook
            case "Calendar": return Calendar
            case "Reminders": return Reminders
            case "Photos": return Photos
            case "Camera": return Camera
            case "Microphone": return Microphone
            case "Accessibility": return Accessibility
            case "PostEvent": return PostEvent
            case "SystemPolicyAllFiles": return SystemPolicyAllFiles
            case "SystemPolicySysAdminFiles": return SystemPolicySysAdminFiles
            case "FileProviderPresence": return FileProviderPresence
            case "ListenEvent": return ListenEvent
            case "MediaLibrary": return MediaLibrary
            case "ScreenCapture": return ScreenCapture
            case "SpeechRecognition": return SpeechRecognition
            case "SystemPolicyDesktopFolder": return SystemPolicyDesktopFolder
            case "SystemPolicyDocumentsFolder": return SystemPolicyDocumentsFolder
            case "SystemPolicyDownloadsFolder": return SystemPolicyDownloadsFolder
            case "SystemPolicyNetworkVolumes": return SystemPolicyNetworkVolumes
            case "SystemPolicyRemovableVolumes": return SystemPolicyRemovableVolumes
            default: return "-"
            }
        }
        set {
            switch key {
            case "AddressBook": AddressBook = newValue
            case "Calendar": Calendar = newValue
            case "Reminders": Reminders = newValue
            case "Photos": Photos = newValue
            case "Camera": Camera = newValue
            case "Microphone": Microphone = newValue
            case "Accessibility": Accessibility = newValue
            case "PostEvent": PostEvent = newValue
            case "SystemPolicyAllFiles": SystemPolicyAllFiles = newValue
            case "SystemPolicySysAdminFiles": SystemPolicySysAdminFiles = newValue
            case "FileProviderPresence": FileProviderPresence = newValue
            case "ListenEvent": ListenEvent = newValue
            case "MediaLibrary": MediaLibrary = newValue
            case "ScreenCapture": ScreenCapture = newValue
            case "SpeechRecognition": SpeechRecognition = newValue
            case "SystemPolicyDesktopFolder": SystemPolicyDesktopFolder = newValue
            case "SystemPolicyDocumentsFolder": SystemPolicyDocumentsFolder = newValue
            case "SystemPolicyDownloadsFolder": SystemPolicyDownloadsFolder = newValue
            case "SystemPolicyNetworkVolumes": SystemPolicyNetworkVolumes = newValue
            case "SystemPolicyRemovableVolumes": SystemPolicyRemovableVolumes = newValue
            default: break
            }
        }
    }
}
