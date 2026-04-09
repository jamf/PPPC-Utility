//
//  UploadManagerTests.swift
//  PPPC UtilityTests
//
//  SPDX-License-Identifier: MIT
//  Copyright (c) 2023 Jamf Software

import Foundation
import Testing

@testable import PPPC_Utility

// MARK: - verifyConnection

@Suite("UploadManager verifyConnection", .serialized)
final class UploadManagerVerifyConnectionTests {

    deinit { MockURLProtocol.reset() }

    @Test("Returns mustSign false when Jamf Pro version is 10.7.1 or later")
    func modernVersionDoesNotRequireSigning() async throws {
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
            if path.contains("activationcode") {
                let json = #"{"activation_code":{"organization_name":"Acme Corp","code":"ABC123"}}"#
                return (.ok(url: request.url!), Data(json.utf8))
            }
            throw URLError(.badURL)
        }

        let manager = UploadManager(serverURL: "https://jamf.example.com", session: session)

        // when
        let info = try await manager.verifyConnection(authManager: authManager)

        // then
        #expect(info.mustSign == false)
        #expect(info.organization == "Acme Corp")
    }

    @Test("Returns mustSign true when Jamf Pro version is below 10.7.1")
    func legacyVersionRequiresSigning() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            if path.contains("jamf-pro-version") {
                let json = #"{"version":"10.6.0"}"#
                return (.ok(url: request.url!), Data(json.utf8))
            }
            if path.contains("activationcode") {
                let json = #"{"activation_code":{"organization_name":"Legacy Inc","code":"XYZ"}}"#
                return (.ok(url: request.url!), Data(json.utf8))
            }
            throw URLError(.badURL)
        }

        let manager = UploadManager(serverURL: "https://jamf.example.com", session: session)

        // when
        let info = try await manager.verifyConnection(authManager: authManager)

        // then
        #expect(info.mustSign == true)
        #expect(info.organization == "Legacy Inc")
    }

    @Test("Throws credential error when authentication fails")
    func throwsCredentialError() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "wrong")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            return (.status(401, url: request.url!), Data())
        }

        let manager = UploadManager(serverURL: "https://jamf.example.com", session: session)

        // when/then
        await #expect {
            try await manager.verifyConnection(authManager: authManager)
        } throws: { error in
            guard case UploadManager.VerificationError.anyError(let message) = error else { return false }
            return message == "Invalid credentials."
        }
    }

    @Test("Throws unavailable error when server returns a non-auth failure")
    func throwsUnavailableError() async throws {
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            return (.status(500, url: request.url!), Data())
        }

        let manager = UploadManager(serverURL: "https://jamf.example.com", session: session)

        // when/then
        await #expect {
            try await manager.verifyConnection(authManager: authManager)
        } throws: { error in
            guard case UploadManager.VerificationError.anyError(let message) = error else { return false }
            return message == "Jamf Pro server is unavailable."
        }
    }
}

// MARK: - upload

@Suite("UploadManager upload", .serialized)
final class UploadManagerUploadTests {

    deinit { MockURLProtocol.reset() }

    /// Reads the HTTP body from a URLRequest, falling back to httpBodyStream
    /// when URLProtocol delivers the body as a stream rather than inline data.
    nonisolated private static func bodyData(from request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: 4096)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }

    @Test("Uploaded XML excludes site element when no site is provided")
    func uploadWithoutSite() async throws {
        nonisolated(unsafe) var capturedBody: Data?
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            if path.hasSuffix("osxconfigurationprofiles") {
                capturedBody = UploadManagerUploadTests.bodyData(from: request)
                return (.ok(url: request.url!), Data())
            }
            throw URLError(.badURL)
        }

        let manager = UploadManager(serverURL: "https://jamf.example.com", session: session)
        let profile = TCCProfileBuilder().buildProfile(allowed: false, authorization: .allow)

        // when
        try await manager.upload(profile: profile, authMgr: authManager, siteInfo: nil, signingIdentity: nil)

        // then
        let body = try #require(capturedBody, "Expected the profile body to be captured from the upload request")
        let doc = try XMLDocument(data: body)
        let root = try #require(doc.rootElement())
        let general = try #require(root.elements(forName: "general").first)
        #expect(general.elements(forName: "site").isEmpty, "No site element should be present when siteInfo is nil")
    }

    @Test("Uploaded XML includes correct site element when site is provided")
    func uploadWithSite() async throws {
        nonisolated(unsafe) var capturedBody: Data?
        let authManager = NetworkAuthManager(username: "admin", password: "pass")
        let session = URLSession.mock { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("auth/token") {
                let tokenJSON = #"{"token":"abc","expires":"2099-01-01T00:00:00.000Z"}"#
                return (.ok(url: request.url!), Data(tokenJSON.utf8))
            }
            if path.hasSuffix("osxconfigurationprofiles") {
                capturedBody = UploadManagerUploadTests.bodyData(from: request)
                return (.ok(url: request.url!), Data())
            }
            throw URLError(.badURL)
        }

        let manager = UploadManager(serverURL: "https://jamf.example.com", session: session)
        let profile = TCCProfileBuilder().buildProfile(allowed: false, authorization: .allow)

        // when
        try await manager.upload(profile: profile, authMgr: authManager, siteInfo: ("42", "Test Site"), signingIdentity: nil)

        // then
        let body = try #require(capturedBody, "Expected the profile body to be captured from the upload request")
        let doc = try XMLDocument(data: body)
        let root = try #require(doc.rootElement())
        let general = try #require(root.elements(forName: "general").first)
        let site = try #require(general.elements(forName: "site").first, "Site element should be present")
        #expect(site.elements(forName: "id").first?.stringValue == "42")
        #expect(site.elements(forName: "name").first?.stringValue == "Test Site")
    }
}
