//
//  ExecutableTests.swift
//  PPPC UtilityTests
//
//  MIT License
//
//  Copyright (c) 2026 Jamf Software
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
import Testing

@testable import PPPC_Utility

@Suite
struct ExecutableTests {
    let executable = Executable()

    @Test(
        "Display name uses last component of identifier",
        arguments: [
            ("com.example.MyApp", "MyApp"),
            ("/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal", "Terminal"),
            ("Terminal", "Terminal")
        ])
    func generateDisplayName(identifier: String, expected: String) {
        // when
        let displayName = executable.generateDisplayName(identifier: identifier)

        // then
        #expect(displayName == expected)
    }

    @Test(
        "Icon path matches identifier type",
        arguments: [
            ("com.example.MyApp", "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"),
            ("/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal", "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ExecutableBinaryIcon.icns")
        ])
    func generateIconPath(identifier: String, expected: String) {
        // when
        let iconPath = executable.generateIconPath(identifier: identifier)

        // then
        #expect(iconPath == expected)
    }

    @Test("All policy properties default to dash")
    func policyPropertiesDefaultToDash() {
        let policy = Policy()

        // then
        #expect(policy.Accessibility == "-")
        #expect(policy.AddressBook == "-")
        #expect(policy.BluetoothAlways == "-")
        #expect(policy.Calendar == "-")
        #expect(policy.Camera == "-")
        #expect(policy.FileProviderPresence == "-")
        #expect(policy.ListenEvent == "-")
        #expect(policy.MediaLibrary == "-")
        #expect(policy.Microphone == "-")
        #expect(policy.Photos == "-")
        #expect(policy.PostEvent == "-")
        #expect(policy.Reminders == "-")
        #expect(policy.ScreenCapture == "-")
        #expect(policy.SpeechRecognition == "-")
        #expect(policy.SystemPolicyAllFiles == "-")
        #expect(policy.SystemPolicyAppBundles == "-")
        #expect(policy.SystemPolicyAppData == "-")
        #expect(policy.SystemPolicyDesktopFolder == "-")
        #expect(policy.SystemPolicyDocumentsFolder == "-")
        #expect(policy.SystemPolicyDownloadsFolder == "-")
        #expect(policy.SystemPolicyNetworkVolumes == "-")
        #expect(policy.SystemPolicyRemovableVolumes == "-")
        #expect(policy.SystemPolicySysAdminFiles == "-")
    }
}
