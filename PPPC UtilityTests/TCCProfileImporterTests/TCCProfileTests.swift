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
import Foundation
import Testing

@testable import PPPC_Utility

private final class BundleLocator {}

@Suite
struct TCCProfileTests {

    // MARK: - tests for serializing to and from xml

    @Test
    func serializationOfComplexProfileUsingAuthorization() throws {
        // when we export to xml and reimport it should still have the same attributes
        let plistData = try TCCProfileBuilder().buildProfile(authorization: .allowStandardUserToSetSystemService).xmlData()
        let profile = try TCCProfile.parse(from: plistData)

        // then verify the config profile top level
        #expect(profile.type == "Configuration")
        #expect(profile.version == 100)
        #expect(profile.uuid == "the uuid")
        #expect(profile.scope == "System")
        #expect(profile.organization == "Test Org")
        #expect(profile.identifier == "Test ID")
        #expect(profile.displayName == "Test Name")
        #expect(profile.payloadDescription == "Test Desc")

        // then verify the payload content top level
        #expect(profile.content.count == 1)
        profile.content.forEach { content in
            #expect(content.payloadDescription == "Content Desc 1")
            #expect(content.displayName == "Content Name 1")
            #expect(content.identifier == "Content ID 1")
            #expect(content.organization == "Content Org 1")
            #expect(content.type == "Content type 1")
            #expect(content.uuid == "Content UUID 1")
            #expect(content.version == 1)

            // then verify the services key
            #expect(content.services.count == 2)
            let allFiles = content.services["SystemPolicyAllFiles"]
            #expect(allFiles?.count == 1)
            allFiles?.forEach { policy in
                #expect(policy.identifier == "policy id")
                #expect(policy.identifierType == "policy id type")
                #expect(policy.codeRequirement == "policy code req")
                #expect(policy.allowed == nil)
                #expect(policy.authorization == .allowStandardUserToSetSystemService)
                #expect(policy.comment == "policy comment")
                #expect(policy.receiverIdentifier == "policy receiver id")
                #expect(policy.receiverIdentifierType == "policy receiver id type")
                #expect(policy.receiverCodeRequirement == "policy receiver code req")
            }
        }
    }

    @Test
    func serializationOfProfileUsingLegacyAllowedKey() throws {
        // when we export to xml and reimport it should still have the same attributes
        let plistData = try TCCProfileBuilder().buildProfile(allowed: true).xmlData()
        let profile = try TCCProfile.parse(from: plistData)

        // then verify the config profile top level
        #expect(profile.type == "Configuration")
        #expect(profile.version == 100)
        #expect(profile.uuid == "the uuid")
        #expect(profile.scope == "System")
        #expect(profile.organization == "Test Org")
        #expect(profile.identifier == "Test ID")
        #expect(profile.displayName == "Test Name")
        #expect(profile.payloadDescription == "Test Desc")

        // then verify the payload content top level
        #expect(profile.content.count == 1)
        profile.content.forEach { content in
            #expect(content.payloadDescription == "Content Desc 1")
            #expect(content.displayName == "Content Name 1")
            #expect(content.identifier == "Content ID 1")
            #expect(content.organization == "Content Org 1")
            #expect(content.type == "Content type 1")
            #expect(content.uuid == "Content UUID 1")
            #expect(content.version == 1)

            // then verify the services key
            #expect(content.services.count == 2)
            let allFiles = content.services["SystemPolicyAllFiles"]
            #expect(allFiles?.count == 1)
            allFiles?.forEach { policy in
                #expect(policy.identifier == "policy id")
                #expect(policy.identifierType == "policy id type")
                #expect(policy.codeRequirement == "policy code req")
                #expect(policy.allowed == true)
                #expect(policy.authorization == nil)
                #expect(policy.comment == "policy comment")
                #expect(policy.receiverIdentifier == "policy receiver id")
                #expect(policy.receiverIdentifierType == "policy receiver id type")
                #expect(policy.receiverCodeRequirement == "policy receiver code req")
            }
        }
    }

    @Test
    func serializationOfProfileWhenBothAllowedAndAuthorizationUsed() throws {
        // when we export to xml and reimport it should still have the same attributes
        let plistData = try TCCProfileBuilder().buildProfile(allowed: false, authorization: .allow).xmlData()
        let profile = try TCCProfile.parse(from: plistData)

        // then verify the config profile top level
        #expect(profile.type == "Configuration")

        // then verify the payload content top level
        #expect(profile.content.count == 1)
        profile.content.forEach { content in
            #expect(content.uuid == "Content UUID 1")
            #expect(content.version == 1)

            // then verify the services key
            #expect(content.services.count == 2)
            let allFiles = content.services["SystemPolicyAllFiles"]
            #expect(allFiles?.count == 1)
            allFiles?.forEach { policy in
                #expect(policy.allowed == false)
                #expect(policy.authorization == .allow)
            }
        }
    }

    // unit tests for handling both Auth and allowed keys should fail?

    @Test
    func settingLegacyAllowValueNullifiesAuthorization() {
        var tccPolicy = TCCPolicy(identifier: "id", codeRequirement: "req", receiverIdentifier: "recId", receiverCodeRequirement: "recreq")
        tccPolicy.authorization = .allow

        // when
        tccPolicy.allowed = true

        // then
        #expect(tccPolicy.authorization == nil)
        #expect(tccPolicy.allowed == true)
    }

    @Test
    func settingAuthorizationValueDoesNotNullifyAllowed() {
        var tccPolicy = TCCPolicy(identifier: "id", codeRequirement: "req", receiverIdentifier: "recId", receiverCodeRequirement: "recreq")
        tccPolicy.allowed = false

        // when
        tccPolicy.authorization = .allowStandardUserToSetSystemService

        // then
        #expect(tccPolicy.allowed == false, "we don't have to nil this out because we use authorization by default if present")
        #expect(tccPolicy.authorization == .allowStandardUserToSetSystemService)
    }

    @Test
    func jamfProAPIData() async throws {
        let tccProfile = TCCProfileBuilder().buildProfile(allowed: false, authorization: .allow)
        let expected = try loadTextFile(fileName: "TestTCCProfileForJamfProAPI").trimmingCharacters(in: .whitespacesAndNewlines)

        // when
        let data = try await tccProfile.jamfProAPIData(signingIdentity: nil, site: nil)

        // then
        let xmlString = String(data: data, encoding: .utf8)
        #expect(xmlString == expected)
    }

    private func loadTextFile(fileName: String) throws -> String {
        let testBundle = Bundle(for: BundleLocator.self)
        let resourceURL = try #require(testBundle.url(forResource: fileName, withExtension: "txt"))
        return try String(contentsOf: resourceURL)
    }
}
