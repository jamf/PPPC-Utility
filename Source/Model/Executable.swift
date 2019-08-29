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

    @objc dynamic var addressBookPolicyString: String = "-"
    @objc dynamic var photosPolicyString: String = "-"
    @objc dynamic var remindersPolicyString: String = "-"
    @objc dynamic var calendarPolicyString: String = "-"
    @objc dynamic var accessibilityPolicyString: String = "-"
    @objc dynamic var postEventsPolicyString: String = "-"
    @objc dynamic var adminFilesPolicyString: String = "-"
    @objc dynamic var allFilesPolicyString: String = "-"
    @objc dynamic var cameraPolicyString: String = "-"
    @objc dynamic var microphonePolicyString: String = "-"
    @objc dynamic var fileProviderPolicyString: String = "-"
    @objc dynamic var listenEventPolicyString: String = "-"
    @objc dynamic var mediaLibraryPolicyString: String = "-"
    @objc dynamic var screenCapturePolicyString: String = "-"
    @objc dynamic var speechRecognitionPolicyString: String = "-"
    @objc dynamic var desktopFolderPolicyString: String = "-"
    @objc dynamic var documentsFolderPolicyString: String = "-"
    @objc dynamic var downloadsFolderPolicyString: String = "-"
    @objc dynamic var networkVolumesPolicyString: String = "-"
    @objc dynamic var removableVolumesPolicyString: String = "-"

    @objc dynamic var policy: [String : String] = ["addressBook": "-",
                                                  "photos": "-",
                                                  "reminders": "-",
                                                  "calendar": "-",
                                                  "accessibility": "-",
                                                  "postEvents": "-",
                                                  "adminFiles": "-",
                                                  "allFiles": "-",
                                                  "camera": "-",
                                                  "microphone": "-",
                                                  "fileProvider": "-",
                                                  "listenEvent": "-",
                                                  "mediaLibrary": "-",
                                                  "screenCapture": "-",
                                                  "speechRecognition": "-",
                                                  "desktopFolder": "-",
                                                  "documentsFolder": "-",
                                                  "downloadsFolder": "-",
                                                  "networkVolumes": "-",
                                                  "removableVolumes": "-"]
    @objc dynamic var appleEvents: [AppleEventRule] = []
}
