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
            #expect(content.services.count == 5)
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
            #expect(content.services.count == 5)
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
            #expect(content.services.count == 5)
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

    @Test("jamfProAPIData XML contains expected structure and no site element when site is nil")
    func jamfProAPIDataXMLStructureWithoutSite() async throws {
        let profile = TCCProfileBuilder().buildProfile(allowed: false, authorization: .allow)

        // when
        let data = try await profile.jamfProAPIData(signingIdentity: nil, site: nil)

        // then
        let doc = try XMLDocument(data: data)
        let root = try #require(doc.rootElement())
        #expect(root.name == "os_x_configuration_profile")
        let general = try #require(root.elements(forName: "general").first)
        #expect(general.elements(forName: "payloads").count == 1)
        #expect(general.elements(forName: "name").first?.stringValue == "Test Name")
        #expect(general.elements(forName: "description").first?.stringValue == "Test Desc")
        #expect(general.elements(forName: "site").isEmpty, "No site element when site parameter is nil")
    }

    @Test("jamfProAPIData XML includes correct site element when site is provided")
    func jamfProAPIDataXMLStructureWithSite() async throws {
        let profile = TCCProfileBuilder().buildProfile(allowed: false, authorization: .allow)

        // when
        let data = try await profile.jamfProAPIData(signingIdentity: nil, site: ("42", "Test Site"))

        // then
        let doc = try XMLDocument(data: data)
        let root = try #require(doc.rootElement())
        #expect(root.name == "os_x_configuration_profile")
        let general = try #require(root.elements(forName: "general").first)
        let site = try #require(general.elements(forName: "site").first, "Site element should be present")
        #expect(site.elements(forName: "id").first?.stringValue == "42")
        #expect(site.elements(forName: "name").first?.stringValue == "Test Site")
        #expect(general.elements(forName: "payloads").count == 1)
        #expect(general.elements(forName: "name").first?.stringValue == "Test Name")
        #expect(general.elements(forName: "description").first?.stringValue == "Test Desc")
    }

    private func loadTextFile(fileName: String) throws -> String {
        let testBundle = Bundle(for: BundleLocator.self)
        let resourceURL = try #require(testBundle.url(forResource: fileName, withExtension: "txt"))
        return try String(contentsOf: resourceURL)
    }
}
