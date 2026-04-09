//
//  NetworkingTests.swift
//  PPPC UtilityTests
//
//  SPDX-License-Identifier: MIT
//  Copyright (c) 2023 Jamf Software

import Foundation
import Testing

@testable import PPPC_Utility

// MARK: - url(forEndpoint:)

@Suite("Networking URL construction")
struct NetworkingURLTests {

    @Test("Constructs URL from valid server string and endpoint")
    func validURL() throws {
        let authManager = NetworkAuthManager(username: "u", password: "p")
        let networking = Networking(serverUrlString: "https://jamf.example.com", tokenManager: authManager)

        // when
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // then
        #expect(request.url?.absoluteString == "https://jamf.example.com/api/v1/resource")
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
        #expect(request.timeoutInterval == 45.0)
    }

    @Test("Throws badServerUrl for invalid server string")
    func badServerURL() {
        let authManager = NetworkAuthManager(username: "u", password: "p")
        let networking = Networking(serverUrlString: "", tokenManager: authManager)

        // when/then
        #expect(throws: NetworkingError.badServerUrl("")) {
            _ = try networking.url(forEndpoint: "anything")
        }
    }
}

// MARK: - loadPreAuthorized

@Suite("Networking loadPreAuthorized", .serialized)
final class NetworkingLoadPreAuthorizedTests {

    deinit { MockURLProtocol.reset() }

    @Test("Returns decoded value on 200")
    func decodesOn200() async throws {
        let authManager = NetworkAuthManager(username: "u", password: "p")
        let session = URLSession.mock { request in
            let json = #"{"version":"11.0.0"}"#
            return (.ok(url: request.url!), Data(json.utf8))
        }

        let networking = Networking(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/jamf-pro-version")

        // when
        let result: JamfProVersion = try await networking.loadPreAuthorized(request: request)

        // then
        #expect(result.version == "11.0.0")
    }

    @Test("Throws invalidUsernamePassword on 401")
    func throwsOn401() async throws {
        let authManager = NetworkAuthManager(username: "u", password: "p")
        let session = URLSession.mock { request in
            return (.status(401, url: request.url!), Data())
        }

        let networking = Networking(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when/then
        await #expect(throws: AuthError.invalidUsernamePassword) {
            let _: JamfProVersion = try await networking.loadPreAuthorized(request: request)
        }
    }

    @Test("Throws serverResponse on 500")
    func throwsOn500() async throws {
        let authManager = NetworkAuthManager(username: "u", password: "p")
        let session = URLSession.mock { request in
            return (.status(500, url: request.url!), Data())
        }

        let networking = Networking(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when/then
        await #expect(throws: NetworkingError.self) {
            let _: JamfProVersion = try await networking.loadPreAuthorized(request: request)
        }
    }
}

// MARK: - loadBearerAuthorized

@Suite("Networking loadBearerAuthorized", .serialized)
final class NetworkingLoadBearerAuthorizedTests {

    deinit { MockURLProtocol.reset() }

    @Test("Returns decoded value on 200")
    func decodesOn200() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            let json = #"{"version":"11.0.0"}"#
            return (.ok(url: request.url!), Data(json.utf8))
        }

        let networking = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/jamf-pro-version")

        // when
        let result: JamfProVersion = try await networking.loadBearerAuthorized(request: request)

        // then
        #expect(result.version == "11.0.0")
    }

    @Test("Refreshes the bearer token and retries when server returns 401 on first attempt")
    func retriesOnceOn401() async throws {
        nonisolated(unsafe) var tokenCallCount = 0
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                tokenCallCount += 1
                if tokenCallCount == 1 {
                    // First token — will be rejected by the API
                    let tokenJSON = #"{"token":"stale","expires":"2099-01-01T00:00:00.000Z"}"#
                    return (.ok(url: request.url!), Data(tokenJSON.utf8))
                }
                // Refreshed token — will be accepted
                let tokenJSON = #"{"token":"refreshed","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            // API endpoint: reject "stale", accept "refreshed"
            let auth = request.value(forHTTPHeaderField: "Authorization") ?? ""
            if auth.contains("refreshed") {
                let json = #"{"version":"11.0.0"}"#
                return (.ok(url: request.url!), Data(json.utf8))
            }
            return (.status(401, url: request.url!), Data())
        }

        let networking = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/jamf-pro-version")

        // when
        let result: JamfProVersion = try await networking.loadBearerAuthorized(request: request)

        // then
        #expect(result.version == "11.0.0")
    }

    @Test("Throws invalidToken when server returns 401 on both the initial and retry attempts")
    func throwsOnSecond401() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"refreshed","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            return (.status(401, url: request.url!), Data())
        }

        let networking = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when/then
        await #expect(throws: AuthError.invalidToken) {
            let _: JamfProVersion = try await networking.loadBearerAuthorized(request: request)
        }
    }
}

// MARK: - sendBearerAuthorized

@Suite("Networking sendBearerAuthorized", .serialized)
final class NetworkingSendBearerAuthorizedTests {

    deinit { MockURLProtocol.reset() }

    @Test("Returns data on 200")
    func returnsDataOn200() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            return (.ok(url: request.url!), Data("OK".utf8))
        }

        let networking = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when
        let data = try await networking.sendBearerAuthorized(request: request)

        // then
        #expect(String(data: data, encoding: .utf8) == "OK")
    }

    @Test("Refreshes the bearer token and retries when server returns 401 on first attempt")
    func retriesOnceOn401() async throws {
        nonisolated(unsafe) var tokenCallCount = 0
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                tokenCallCount += 1
                if tokenCallCount == 1 {
                    let tokenJSON = #"{"token":"stale","expires":"2099-01-01T00:00:00.000Z"}"#
                    return (.ok(url: request.url!), Data(tokenJSON.utf8))
                }
                let tokenJSON = #"{"token":"refreshed","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            let auth = request.value(forHTTPHeaderField: "Authorization") ?? ""
            if auth.contains("refreshed") {
                return (.ok(url: request.url!), Data("OK".utf8))
            }
            return (.status(401, url: request.url!), Data())
        }

        let networking = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when
        let data = try await networking.sendBearerAuthorized(request: request)

        // then
        #expect(String(data: data, encoding: .utf8) == "OK")
    }

    @Test("Throws invalidToken when server returns 401 on both the initial and retry attempts")
    func throwsOnSecond401() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"refreshed","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            return (.status(401, url: request.url!), Data())
        }

        let networking = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when/then
        await #expect(throws: AuthError.invalidToken) {
            try await networking.sendBearerAuthorized(request: request)
        }
    }

    @Test("Throws serverResponse on 500")
    func throwsOn500() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            return (.status(500, url: request.url!), Data())
        }

        let networking = JamfProAPIClient(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when/then
        await #expect(throws: NetworkingError.self) {
            try await networking.sendBearerAuthorized(request: request)
        }
    }
}

// MARK: - sendBasicAuthorized

@Suite("Networking sendBasicAuthorized", .serialized)
final class NetworkingSendBasicAuthorizedTests {

    deinit { MockURLProtocol.reset() }

    @Test("Returns data on 200")
    func returnsDataOn200() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let authHeader = request.value(forHTTPHeaderField: "Authorization") ?? ""
            #expect(authHeader.hasPrefix("Basic "))
            return (.ok(url: request.url!), Data("success".utf8))
        }

        let networking = Networking(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when
        let data = try await networking.sendBasicAuthorized(request: request)

        // then
        #expect(String(data: data, encoding: .utf8) == "success")
    }

    @Test("Throws invalidUsernamePassword on 401")
    func throwsOn401() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            return (.status(401, url: request.url!), Data())
        }

        let networking = Networking(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when/then
        await #expect(throws: AuthError.invalidUsernamePassword) {
            try await networking.sendBasicAuthorized(request: request)
        }
    }

    @Test("Throws serverResponse on 403")
    func throwsOn403() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            return (.status(403, url: request.url!), Data())
        }

        let networking = Networking(serverUrlString: "https://jamf.example.com", tokenManager: authManager, session: session)
        let request = try networking.url(forEndpoint: "api/v1/resource")

        // when/then
        await #expect(throws: NetworkingError.self) {
            try await networking.sendBasicAuthorized(request: request)
        }
    }
}
