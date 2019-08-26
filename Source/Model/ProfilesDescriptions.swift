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
    case fileProviderPresence = "Permits the app to know which apps the user accesses managed files with"
    case listenEvent = "Permits the app to communicate events and add other objects as listeners"
    case mediaLibrary = "Permits the app to access the user’s media library"
    case microphone = "Access to the system microphone"
    case photos = "Access to pictures managed by Photos.app in ~/Pictures/.photoslibrary"
    case postEvent = "Allows the application to use CoreGraphics APIs to send CGEvents to the system event stream"
    case reminders = "Access to reminders information managed by Reminders.app"
    case screenCapture = "Permits the app to record the screen"
    case speechRecognition = "Allows the application to use the system Speech Recognition facility and to send speech data to Apple"
    case systemPolicyAllFiles = "Access to all protected files"
    case systemPolicyDesktopFolder = "Permits the app to access the user’s Desktop folder"
    case systemPolicyDocumentsFolder = "Permits the app to access the user’s Documents folder"
    case systemPolicyDownloadsFolder = "Permits the app to access the user’s Downloads folder"
    case systemPolicyNetworkVolumes = "Permits the app to access files on a network volume"
    case systemPolicyRemovableVolumes = "Permits the app to access files on a removable volume"
    case systemPolicySysAdminFiles = "Access to some files used in system administration"
}
