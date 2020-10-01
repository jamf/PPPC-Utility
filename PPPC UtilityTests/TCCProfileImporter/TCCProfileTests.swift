//
//  TCCProfileTests.swift
//  PPPC UtilityTests
//
//  Created by Tony Eichelberger on 10/1/20.
//  Copyright © 2020 Jamf. All rights reserved.
//

import XCTest

@testable import PPPC_Utility

class TCCProfileTests: XCTestCase {

    func buildTCCPolicy() -> TCCPolicy {
        return TCCPolicy(identifier: "policy id", codeRequirement: "code req", allowed: true,
                         receiverIdentifier: nil, receiverCodeRequirement: "rec code req")
    }

    func buildTCCPolicies() -> [String: [TCCPolicy]] {
        return ["one": [buildTCCPolicy()]]
    }

    func buildTCCContent(_ contentIndex: Int) -> TCCProfile.Content {
        return TCCProfile.Content(payloadDescription: "Content Desc \(contentIndex)",
                                  displayName: "Content Name \(contentIndex)",
                                  identifier: "Content ID \(contentIndex)",
                                  organization: "Content Org \(contentIndex)",
                                  type: "Content type \(contentIndex)",
                                  uuid: "Content UUID \(contentIndex)",
                                  version: contentIndex,
                                  services: buildTCCPolicies())
    }

    func buildComplexProfile() -> TCCProfile {
        var profile = TCCProfile(organization: "Test Org",
                                 identifier: "Test ID",
                                 displayName: "Test Name",
                                 payloadDescription: "Test Desc",
                                 services: [:])
        profile.content = [buildTCCContent(1)]
        profile.type = "the type"
        profile.version = 100
        profile.uuid = "the uuid"
        profile.scope = "the scope"
        return profile
    }

    func testSerializationOfComplexProfileUsingAuthorizationInBigSur() throws {
        // when we export to xml and reimport it should still have the same attributes
        let plistData = try buildComplexProfile().xmlData()
        let profile = try TCCProfile.parse(from: plistData)

        // then
        XCTAssertEqual("the type", profile.type)
        XCTAssertEqual(100, profile.version)
        XCTAssertEqual("the uuid", profile.uuid)
        XCTAssertEqual("the scope", profile.scope)
        XCTAssertEqual("Test Org", profile.organization)
        XCTAssertEqual("Test ID", profile.identifier)
        XCTAssertEqual("Test Name", profile.displayName)
        XCTAssertEqual("Test Desc", profile.payloadDescription)

        XCTAssertEqual(1, profile.content.count)
        profile.content.forEach { content in
            XCTAssertEqual("Content Desc 1", content.payloadDescription)
            XCTAssertEqual("Content Name 1", content.displayName)
            XCTAssertEqual("Content ID 1", content.identifier)
            XCTAssertEqual("Content Org 1", content.organization)
            XCTAssertEqual("Content type 1", content.type)
            XCTAssertEqual("Content UUID 1", content.uuid)
            XCTAssertEqual(1, content.version)

            XCTAssertEqual(1, content.services.count)
            content.services.forEach { key, value in
                print(key, value)
            }

        }

    }

    func testSerializationOfProfileUsingLegacyAllowedKey() throws {
    }

    // unit tests for handling both Auth and allowed keys should fail?

}
