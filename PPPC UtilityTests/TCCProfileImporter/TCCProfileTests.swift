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

    // MARK: - build testing objects 

    func buildTCCPolicy(allowed: Bool?, authorization: TCCPolicyAuthorizationValue?) -> TCCPolicy {
        var policy = TCCPolicy(identifier: "policy id", codeRequirement: "policy code req",
                               receiverIdentifier: "policy receiver id", receiverCodeRequirement: "policy receiver code req")
        policy.comment = "policy comment"
        policy.identifierType = "policy id type"
        policy.receiverIdentifierType = "policy receiver id type"
        policy.allowed = allowed
        policy.authorization = authorization
        return policy
    }

    func buildTCCPolicies(allowed: Bool?, authorization: TCCPolicyAuthorizationValue?) -> [String: [TCCPolicy]] {
        return ["one": [buildTCCPolicy(allowed: allowed, authorization: authorization)]]
    }

    func buildTCCContent(_ contentIndex: Int, allowed: Bool?, authorization: TCCPolicyAuthorizationValue?) -> TCCProfile.Content {
        return TCCProfile.Content(payloadDescription: "Content Desc \(contentIndex)",
                                  displayName: "Content Name \(contentIndex)",
                                  identifier: "Content ID \(contentIndex)",
                                  organization: "Content Org \(contentIndex)",
                                  type: "Content type \(contentIndex)",
                                  uuid: "Content UUID \(contentIndex)",
                                  version: contentIndex,
                                  services: buildTCCPolicies(allowed: allowed, authorization: authorization))
    }

    func buildProfile(allowed: Bool? = nil, authorization: TCCPolicyAuthorizationValue? = nil) -> TCCProfile {
        var profile = TCCProfile(organization: "Test Org",
                                 identifier: "Test ID",
                                 displayName: "Test Name",
                                 payloadDescription: "Test Desc",
                                 services: [:])
        profile.content = [buildTCCContent(1, allowed: allowed, authorization: authorization)]
        profile.type = "the type"
        profile.version = 100
        profile.uuid = "the uuid"
        profile.scope = "the scope"
        return profile
    }

    // MARK: - tests for serializing to and from xml

    func testSerializationOfComplexProfileUsingAuthorization() throws {
        // when we export to xml and reimport it should still have the same attributes
        let plistData = try buildProfile(authorization: .allowStandardUserToSetSystemService).xmlData()
        let profile = try TCCProfile.parse(from: plistData)

        // then verify the config profile top level
        XCTAssertEqual("the type", profile.type)
        XCTAssertEqual(100, profile.version)
        XCTAssertEqual("the uuid", profile.uuid)
        XCTAssertEqual("the scope", profile.scope)
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
            XCTAssertEqual(1, content.services.count)
            content.services.forEach { event, policies in
                // then verify the policies for each event
                XCTAssertEqual("one", event)
                XCTAssertEqual(1, policies.count)
                policies.forEach { policy in
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
    }

    func testSerializationOfProfileUsingLegacyAllowedKey() throws {
        // when we export to xml and reimport it should still have the same attributes
        let plistData = try buildProfile(allowed: true).xmlData()
        let profile = try TCCProfile.parse(from: plistData)

        // then verify the config profile top level
        XCTAssertEqual("the type", profile.type)
        XCTAssertEqual(100, profile.version)
        XCTAssertEqual("the uuid", profile.uuid)
        XCTAssertEqual("the scope", profile.scope)
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
            XCTAssertEqual(1, content.services.count)
            content.services.forEach { event, policies in
                // then verify the policies for each event
                XCTAssertEqual("one", event)
                XCTAssertEqual(1, policies.count)
                policies.forEach { policy in
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
    }

    // unit tests for handling both Auth and allowed keys should fail?

}
