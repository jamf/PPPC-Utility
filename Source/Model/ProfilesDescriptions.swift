//
//  ProfilesDescriptions.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2019 Jamf Software
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

enum ProfilesDescriptions: String {
    case accessibility = "Allows the app to be controlled with the Accessibility subsystem\nMDM Key: Accessibility"
    case addressBook = "Allows the app to access contact information managed by Contacts\nMDM Key: AddressBook"
    case calendar = "Allows the app to access calendar information managed by Calendar\nMDM Key: Calendar"
    case camera = "Allows the app to access the camera\nMDM Key: Camera"
    case fileProviderPresence = "Allows a File Provider application to know when the user is using files managed by the File Provider\nMDM Key: FileProviderPresence"
    case listenEvent = "Allows the application to use CoreGraphics and HID APIs to receive CGEvents and HID events from all processes\nMDM Key: ListenEvent"
    case mediaLibrary = "Allows the application to access Apple Music, music and video activity, and the media library\nMDM Key: MediaLibrary"
    case microphone = "Allows the app to access the microphone\nMDM Key: Microphone"
    case photos = "Allows the app to access the pictures managed by Photos\nMDM Key: Photos"
    case postEvent = "Allows the app to use CoreGraphics APIs to send CGEvents to the system event stream\nMDM Key: PostEvent"
    case reminders = "Allows the app to access the reminder information managed by Reminders\nMDM Key: Reminders"
    case screenCapture = "Allows the application to read the contents of the system display\nMDM Key: ScreenCapture"
    case speechRecognition = "Allows the application to use the system Speech Recognition facility and to send speech data to Apple\nMDM Key: SpeechRecognition"
    case systemPolicyAllFiles = "Allows the app to access all protected files, including system administration files\nMDM Key: SystemPolicyAllFiles"
    case systemPolicyDesktopFolder = "Allows the application to access files in the user's Desktop folder\nMDM Key: SystemPolicyDesktopFolder"
    case systemPolicyDocumentsFolder = "Allows the application to access files in the user's Documents folder\nMDM Key: SystemPolicyDocumentsFolder"
    case systemPolicyDownloadsFolder = "Allows the application to access files in the user's Downloads folder\nMDM Key: SystemPolicyDownloadsFolder"
    case systemPolicyNetworkVolumes = "Allows the application to access files on network volumes\nMDM Key: SystemPolicyNetworkVolumes"
    case systemPolicyRemovableVolumes = "Allows the application to access files on removable volumes\nMDM Key: SystemPolicyRemovableVolumes"
    case systemPolicySysAdminFiles = "Allows the app to access some files used in system administration\nMDM Key: SystemPolicySysAdminFiles"
}
