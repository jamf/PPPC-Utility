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

// MARK: - getJamfProVersion

@Suite("JamfProAPIClient getJamfProVersion", .serialized)
final class JamfProAPIClientVersionTests {

    deinit { MockURLProtocol.reset() }

    @Test("getJamfProVersion decodes JSON response")
    func getVersionFromJSON() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            if path.contains("jamf-pro-version") {
                let json = #"{"version":"10.40.0-t1695913581"}"#
                return (.ok(url: request.url!), Data(json.utf8))
            }
            throw URLError(.badURL)
        }

        let client = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)

        // when
        let version = try await client.getJamfProVersion()

        // then
        #expect(version.version == "10.40.0-t1695913581")
        #expect(version.mainVersionInfo() == "10.40.0")
    }

    @Test("Falls back to parsing HTML login page when version API endpoint returns 404")
    func getVersionFallsBackToHTML() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            if path.contains("jamf-pro-version") {
                return (.status(404, url: request.url!), Data())
            }
            // HTML login page fallback
            let html = #"<html><meta name="version" content="10.22.0-t123"></html>"#
            return (.ok(url: request.url!), Data(html.utf8))
        }

        let client = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)

        // when
        let version = try await client.getJamfProVersion()

        // then
        #expect(version.version == "10.22.0")
    }
}

// MARK: - getOrganizationName

@Suite("JamfProAPIClient getOrganizationName", .serialized)
final class JamfProAPIClientOrgTests {

    deinit { MockURLProtocol.reset() }

    @Test("getOrganizationName decodes activation code response")
    func getOrgNameDecodesResponse() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            if path.contains("activationcode") {
                let json = #"{"activation_code":{"organization_name":"Acme Corp","code":"ABC123"}}"#
                return (.ok(url: request.url!), Data(json.utf8))
            }
            throw URLError(.badURL)
        }

        let client = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)

        // when
        let orgName = try await client.getOrganizationName()

        // then
        #expect(orgName == "Acme Corp")
    }
}

// MARK: - getBearerToken

@Suite("JamfProAPIClient getBearerToken", .serialized)
final class JamfProAPIClientTokenTests {

    deinit { MockURLProtocol.reset() }

    @Test("getBearerToken with basic auth sends POST to auth/token")
    func getBearerTokenBasicAuth() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "secret")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                // then — verify it's a POST with Basic auth
                #expect(request.httpMethod == "POST")
                let authHeader = request.value(forHTTPHeaderField: "Authorization") ?? ""
                #expect(authHeader.hasPrefix("Basic "))
                let tokenJSON = #"{"token":"new-token-123","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            throw URLError(.badURL)
        }

        let client = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)

        // when
        let token = try await client.getBearerToken(authInfo: .basicAuth(username: "admin", password: "secret"))

        // then
        #expect(token.value == "new-token-123")
    }

    @Test("getBearerToken with client credentials sends form-encoded POST to oauth/token")
    func getBearerTokenClientCreds() async throws {
        let authManager = NetworkAuthManager(username: "", password: "")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("oauth/token") {
                // then — verify it's a POST
                #expect(request.httpMethod == "POST")
                let tokenJSON = #"{"access_token":"oauth-token-456","expires_in":3600}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            throw URLError(.badURL)
        }

        let client = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)

        // when
        let token = try await client.getBearerToken(authInfo: .clientCreds(id: "my-id", secret: "my-secret"))

        // then
        #expect(token.value == "oauth-token-456")
    }
}

// MARK: - load with fallback

@Suite("JamfProAPIClient load fallback", .serialized)
final class JamfProAPIClientLoadFallbackTests {

    deinit { MockURLProtocol.reset() }

    @Test("Falls back to basic auth when bearer token endpoint returns 404, indicating pre-10.35 Jamf Pro")
    func loadFallsBackToBasicAuth() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                // Token endpoint returns 404 → bearerAuthNotSupported
                return (.status(404, url: request.url!), Data())
            }
            if path.contains("activationcode") {
                let authHeader = request.value(forHTTPHeaderField: "Authorization") ?? ""
                if authHeader.hasPrefix("Basic ") {
                    let json = #"{"activation_code":{"organization_name":"Fallback Corp","code":"XYZ"}}"#
                    return (.ok(url: request.url!), Data(json.utf8))
                }
                return (.status(401, url: request.url!), Data())
            }
            throw URLError(.badURL)
        }

        let client = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)

        // when
        let orgName = try await client.getOrganizationName()

        // then
        #expect(orgName == "Fallback Corp")
    }
}
