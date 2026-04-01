//
//  JamfProAPIClientTests.swift
//  PPPC UtilityTests
//
//  SPDX-License-Identifier: MIT
//  Copyright (c) 2023 Jamf Software

import Foundation
@preconcurrency import XCTest

@testable import PPPC_Utility

class JamfProAPIClientTests: XCTestCase {
    @MainActor func testOAuthTokenRequest() async throws {
        // given
        let authManager = NetworkAuthManager(username: "", password: "")
        let apiClient = JamfProAPIClient(serverUrlString: "https://something", tokenManager: authManager)

        // when
        let request = try apiClient.oauthTokenRequest(clientId: "mine&yours", clientSecret: "foo bar")

        // then
        let body = try XCTUnwrap(request.httpBody)
        let bodyString = String(data: body, encoding: .utf8)
        XCTAssertEqual(bodyString, "grant_type=client_credentials&client_id=mine%26yours&client_secret=foo%20bar")
    }
}
