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
    case accessibility = "Control the application via the Accessibility subsystem"
    case addressBook = "Access to contact information managed by Contacts.app"
    case calendar = "Access to calendar information managed by Calendar.app"
    case camera = "Access to the system camera"
    case fileProviderPresence = "Allows a File Provider application to know when the user is using files managed by the File Provider"
    case listenEvent = "Allows the application to use CoreGraphics and HID APIs to receive CGEvents and HID events from all processes"
    case mediaLibrary = "Allows the application to access Apple Music, music and video activity, and the media library"
    case microphone = "Access to the system microphone"
    case photos = "Access to pictures managed by Photos.app in ~/Pictures/.photoslibrary"
    case postEvent = "Allows the application to use CoreGraphics APIs to send CGEvents to the system event stream"
    case reminders = "Access to reminders information managed by Reminders.app"
    case screenCapture = "Allows the application to read the contents of the system display"
    case speechRecognition = "Allows the application to use the system Speech Recognition facility and to send speech data to Apple"
    case systemPolicyAllFiles = "Allows the application access to all protected files, including system administration files"
    case systemPolicyDesktopFolder = "Allows the application to access files in the user's Desktop folder"
    case systemPolicyDocumentsFolder = "Allows the application to access files in the user's Documents folder"
    case systemPolicyDownloadsFolder = "Allows the application to access files in the user's Downloads folder"
    case systemPolicyNetworkVolumes = "Allows the application to access files on network volumes"
    case systemPolicyRemovableVolumes = "Allows the application to access files on removable volumes"
    case systemPolicySysAdminFiles = "Allows the application access to some files used in system administration"
}
