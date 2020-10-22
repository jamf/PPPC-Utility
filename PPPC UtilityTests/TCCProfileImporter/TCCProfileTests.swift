//
//  TCCProfileTests.swift
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
import XCTest

@testable import PPPC_Utility

class TCCProfileTests: XCTestCase {

    // MARK: - tests for serializing to and from xml

    func testSerializationOfComplexProfileUsingAuthorization() throws {
        // when we export to xml and reimport it should still have the same attributes
        let plistData = try TCCProfileBuilder().buildProfile(authorization: .allowStandardUserToSetSystemService).xmlData()
        let profile = try TCCProfile.parse(from: plistData)

        // then verify the config profile top level
        XCTAssertEqual("Configuration", profile.type)
        XCTAssertEqual(100, profile.version)
        XCTAssertEqual("the uuid", profile.uuid)
        XCTAssertEqual("System", profile.scope)
        XCTAssertEqual("Test Org", profile.organization)
        XCTAssertEqual("Test ID", profile.identifier)
        XCTAssertEqual("Test Name", profile.displayName)
        XCTAssertEqual("Test Desc", profile.payloadDescription)

        // then verify the payload content top level
        XCTAssertEqual(1, profile.content.count)
        profile.content.forEach { content in
            XCTAssertEqual("Content Desc 1", content.payloadDescription)
            XCTAssertEqual("Content Name 1", content.displayName)
            XCTAssertEqual("Content ID 1", content.identifier)
            XCTAssertEqual("Content Org 1", content.organization)
            XCTAssertEqual("Content type 1", content.type)
            XCTAssertEqual("Content UUID 1", content.uuid)
            XCTAssertEqual(1, content.version)

            // then verify the services key
            XCTAssertEqual(2, content.services.count)
            let allFiles = content.services["SystemPolicyAllFiles"]
            XCTAssertEqual(1, allFiles?.count)
            allFiles?.forEach { policy in
                XCTAssertEqual("policy id", policy.identifier)
                XCTAssertEqual("policy id type", policy.identifierType)
                XCTAssertEqual("policy code req", policy.codeRequirement)
                XCTAssertNil(policy.allowed)
                XCTAssertEqual(TCCPolicyAuthorizationValue.allowStandardUserToSetSystemService, policy.authorization)
                XCTAssertEqual("policy comment", policy.comment)
                XCTAssertEqual("policy receiver id", policy.receiverIdentifier)
                XCTAssertEqual("policy receiver id type", policy.receiverIdentifierType)
                XCTAssertEqual("policy receiver code req", policy.receiverCodeRequirement)
            }
        }
    }

    func testSerializationOfProfileUsingLegacyAllowedKey() throws {
        // when we export to xml and reimport it should still have the same attributes
        let plistData = try TCCProfileBuilder().buildProfile(allowed: true).xmlData()
        let profile = try TCCProfile.parse(from: plistData)

        // then verify the config profile top level
        XCTAssertEqual("Configuration", profile.type)
        XCTAssertEqual(100, profile.version)
        XCTAssertEqual("the uuid", profile.uuid)
        XCTAssertEqual("System", profile.scope)
        XCTAssertEqual("Test Org", profile.organization)
        XCTAssertEqual("Test ID", profile.identifier)
        XCTAssertEqual("Test Name", profile.displayName)
        XCTAssertEqual("Test Desc", profile.payloadDescription)

        // then verify the payload content top level
        XCTAssertEqual(1, profile.content.count)
        profile.content.forEach { content in
            XCTAssertEqual("Content Desc 1", content.payloadDescription)
            XCTAssertEqual("Content Name 1", content.displayName)
            XCTAssertEqual("Content ID 1", content.identifier)
            XCTAssertEqual("Content Org 1", content.organization)
            XCTAssertEqual("Content type 1", content.type)
            XCTAssertEqual("Content UUID 1", content.uuid)
            XCTAssertEqual(1, content.version)

            // then verify the services key
            XCTAssertEqual(2, content.services.count)
            let allFiles = content.services["SystemPolicyAllFiles"]
            XCTAssertEqual(1, allFiles?.count)
            allFiles?.forEach { policy in
                XCTAssertEqual("policy id", policy.identifier)
                XCTAssertEqual("policy id type", policy.identifierType)
                XCTAssertEqual("policy code req", policy.codeRequirement)
                XCTAssertEqual(true, policy.allowed)
                XCTAssertNil(policy.authorization)
                XCTAssertEqual("policy comment", policy.comment)
                XCTAssertEqual("policy receiver id", policy.receiverIdentifier)
                XCTAssertEqual("policy receiver id type", policy.receiverIdentifierType)
                XCTAssertEqual("policy receiver code req", policy.receiverCodeRequirement)
            }
        }
    }

    func testSerializationOfProfileWhenBothAllowedAndAuthorizationUsed() throws {
        // when we export to xml and reimport it should still have the same attributes
        let plistData = try TCCProfileBuilder().buildProfile(allowed: false, authorization: .allow).xmlData()
        let profile = try TCCProfile.parse(from: plistData)

        // then verify the config profile top level
        XCTAssertEqual("Configuration", profile.type)

        // then verify the payload content top level
        XCTAssertEqual(1, profile.content.count)
        profile.content.forEach { content in
            XCTAssertEqual("Content UUID 1", content.uuid)
            XCTAssertEqual(1, content.version)

            // then verify the services key
            XCTAssertEqual(2, content.services.count)
            let allFiles = content.services["SystemPolicyAllFiles"]
            XCTAssertEqual(1, allFiles?.count)
            allFiles?.forEach { policy in
                XCTAssertEqual(false, policy.allowed)
                XCTAssertEqual(policy.authorization, TCCPolicyAuthorizationValue.allow)
            }
        }
    }

    // unit tests for handling both Auth and allowed keys should fail?

    func testSettingLegacyAllowValueNullifiesAuthorization() {
        // given
        var tccPolicy = TCCPolicy(identifier: "id", codeRequirement: "req", receiverIdentifier: "recId", receiverCodeRequirement: "recreq")
        tccPolicy.authorization = .allow

        // when
        tccPolicy.allowed = true

        // then
        XCTAssertNil(tccPolicy.authorization)
        XCTAssertTrue(tccPolicy.allowed!)
    }

    func testSettingAuthorizationValueDoesNotNullifyAllowed() {
        // given
        var tccPolicy = TCCPolicy(identifier: "id", codeRequirement: "req", receiverIdentifier: "recId", receiverCodeRequirement: "recreq")
        tccPolicy.allowed = false

        // when
        tccPolicy.authorization = .allowStandardUserToSetSystemService

        // then
        XCTAssertEqual(tccPolicy.allowed, false, "we don't have to nil this out because we use authorization by default if present")
        XCTAssertEqual(tccPolicy.authorization, TCCPolicyAuthorizationValue.allowStandardUserToSetSystemService)
    }

}
