//
//  TCCProfileBuilder.swift
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

@testable import PPPC_Utility

class TCCProfileBuilder: NSObject {

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
        return ["SystemPolicyAllFiles": [buildTCCPolicy(allowed: allowed, authorization: authorization)]]
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
        profile.version = 100
        profile.uuid = "the uuid"
        return profile
    }

}
