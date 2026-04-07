//
//  TCCPolicyTests.swift
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
struct TCCPolicyTests {
    @Test("Identifier type is bundleID for bundle identifier")
    func identifierTypeBundleID() {
        // when
        let policy = TCCPolicy(identifier: "com.example.App", codeRequirement: "req")

        // then
        #expect(policy.identifierType == .bundleID)
        #expect(policy.receiverIdentifierType == nil)
    }

    @Test("Identifier type is path for path identifier")
    func identifierTypePath() {
        // when
        let policy = TCCPolicy(identifier: "/Applications/App.app/Contents/MacOS/App", codeRequirement: "req")

        // then
        #expect(policy.identifierType == .path)
    }

    @Test("Receiver identifier type is auto-detected")
    func receiverIdentifierTypeDetected() {
        // when
        let policy = TCCPolicy(
            identifier: "com.example.Source",
            codeRequirement: "sourceReq",
            receiverIdentifier: "/Applications/Target.app/Contents/MacOS/Target",
            receiverCodeRequirement: "targetReq")

        // then
        #expect(policy.receiverIdentifierType == .path)
    }
}
