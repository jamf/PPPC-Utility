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

    @Test("Display name uses last component of bundle identifier")
    func generateDisplayNameBundleIdentifier() {
        // when
        let displayName = executable.generateDisplayName(identifier: "com.example.MyApp")

        // then
        #expect(displayName == "MyApp")
    }

    @Test("Display name uses last component of path identifier")
    func generateDisplayNamePathIdentifier() {
        // when
        let displayName = executable.generateDisplayName(identifier: "/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal")

        // then
        #expect(displayName == "Terminal")
    }

    @Test("Display name returns identifier when single component")
    func generateDisplayNameSingleComponent() {
        // when
        let displayName = executable.generateDisplayName(identifier: "Terminal")

        // then
        #expect(displayName == "Terminal")
    }

    @Test("Icon path is application for bundle identifier")
    func generateIconPathForBundleIdentifier() {
        // when
        let iconPath = executable.generateIconPath(identifier: "com.example.MyApp")

        // then
        #expect(iconPath == IconFilePath.application)
    }

    @Test("Icon path is binary for path identifier")
    func generateIconPathForPathIdentifier() {
        // when
        let iconPath = executable.generateIconPath(identifier: "/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal")

        // then
        #expect(iconPath == IconFilePath.binary)
    }

    @Test("All policy values default to dash")
    func allPolicyValuesAreDefaults() {
        let policy = Policy()

        // when
        let values = policy.allPolicyValues()

        // then
        #expect(values.count == 20)
        #expect(values.allSatisfy { $0 == "-" })
    }
}
