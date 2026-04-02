//
//  JamfProAPIClientTests.swift
//  PPPC UtilityTests
//
//  SPDX-License-Identifier: MIT
//  Copyright (c) 2023 Jamf Software

import Foundation
import Testing

@testable import PPPC_Utility

@Suite
struct JamfProAPIClientTests {
    @Test
    func oAuthTokenRequest() throws {
        let authManager = NetworkAuthManager(username: "", password: "")
        let apiClient = JamfProAPIClient(serverUrlString: "https://something", tokenManager: authManager)

        // when
        let request = try apiClient.oauthTokenRequest(clientId: "mine&yours", clientSecret: "foo bar")

        // then
        let body = try #require(request.httpBody)
        let bodyString = String(data: body, encoding: .utf8)
        #expect(bodyString == "grant_type=client_credentials&client_id=mine%26yours&client_secret=foo%20bar")
    }
}
