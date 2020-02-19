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

import Cocoa

class Executable: NSObject {

    @objc dynamic var iconPath: String!

    @objc dynamic var displayName: String!
    @objc dynamic var identifier: String!
    @objc dynamic var codeRequirement: String!
    
    @objc dynamic var policy: Policy = Policy()
    @objc dynamic var appleEvents: [AppleEventRule] = []

    override init() {
        super.init()
    }

    init(identifier: String, codeRequirement: String, _ displayName: String? = nil) {
        super.init()

        self.identifier = identifier
        self.codeRequirement = codeRequirement
        if displayName != nil {
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
}


class Policy: NSObject {
    @objc dynamic var AddressBook: String = "-"
    @objc dynamic var Calendar: String = "-"
    @objc dynamic var Reminders: String = "-"
    @objc dynamic var Photos: String = "-"
    @objc dynamic var Camera: String = "-"
    @objc dynamic var Microphone: String = "-"
    @objc dynamic var Accessibility: String = "-"
    @objc dynamic var PostEvent: String = "-"
    @objc dynamic var SystemPolicyAllFiles: String = "-"
    @objc dynamic var SystemPolicySysAdminFiles: String = "-"
    @objc dynamic var FileProviderPresence: String = "-"
    @objc dynamic var ListenEvent: String = "-"
    @objc dynamic var MediaLibrary: String = "-"
    @objc dynamic var ScreenCapture: String = "-"
    @objc dynamic var SpeechRecognition: String = "-"
    @objc dynamic var SystemPolicyDesktopFolder: String = "-"
    @objc dynamic var SystemPolicyDocumentsFolder: String = "-"
    @objc dynamic var SystemPolicyDownloadsFolder: String = "-"
    @objc dynamic var SystemPolicyNetworkVolumes: String = "-"
    @objc dynamic var SystemPolicyRemovableVolumes: String = "-"
}

