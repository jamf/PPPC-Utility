//
//  JamfProAPIClient.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2023 Jamf Software
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

class JamfProAPIClient: Networking {
    let applicationJson = "application/json"

    override func getBearerToken(authInfo: AuthenticationInfo) async throws -> Token {
        switch authInfo {
        case .basicAuth:
            let endpoint = "api/v1/auth/token"
            var request = try url(forEndpoint: endpoint)

            request.httpMethod = "POST"
            request.setValue(applicationJson, forHTTPHeaderField: "Accept")

            return try await loadBasicAuthorized(request: request)
        case .clientCreds(let id, let secret):
            let request = try oauthTokenRequest(clientId: id, clientSecret: secret)

            return try await loadPreAuthorized(request: request)
        }
    }

    /// Creates the OAuth client credentials token request
    /// - Parameters:
    ///   - clientId: The client ID
    ///   - clientSecret: The client secret
    /// - Returns: A `URLRequest` that is ready to send to acquire an OAuth token.
    func oauthTokenRequest(clientId: String, clientSecret: String) throws -> URLRequest {
        let endpoint = "api/oauth/token"
        var request = try url(forEndpoint: endpoint)

        request.httpMethod = "POST"
        request.setValue(applicationJson, forHTTPHeaderField: "Accept")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ]

        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        return request
    }

    // MARK: - Requests with fallback auth

    /// Make a network request and decode the response using bearer auth if possible, falling back to basic auth if needed.
    /// - Parameter request: The `URLRequest` to make
    /// - Returns: The decoded response.
    func load<T: Decodable>(request: URLRequest) async throws -> T {
        let result: T

        if authManager.bearerAuthSupported() {
            do {
                result = try await loadBearerAuthorized(request: request)
            } catch AuthError.bearerAuthNotSupported {
                // Note that `authManager` will automatically return false from future calls to `bearerAuthSupported()`
                // Possibly we're talking to Jamf Pro 10.34.x or lower and we can retry with Basic Auth
                result = try await loadBasicAuthorized(request: request)
            }
        } else {
            result = try await loadBasicAuthorized(request: request)
        }

        return result
    }

    /// Send a network request and return the response using bearer auth if possible, falling back to basic auth if needed.
    /// - Parameter request: The `URLRequest` to make
    /// - Returns: The raw data of a successful network response.
    func send(request: URLRequest) async throws -> Data {
        let result: Data

        if authManager.bearerAuthSupported() {
            do {
                result = try await sendBearerAuthorized(request: request)
            } catch AuthError.bearerAuthNotSupported {
                // Note that authManager will automatically return false from future calls to ``bearerAuthSupported()``
                // Possibly we're talking to Jamf Pro 10.34.x or lower and we can retry with Basic Auth
                result = try await sendBasicAuthorized(request: request)
            }
        } else {
            result = try await sendBasicAuthorized(request: request)
        }

        return result
    }

    // MARK: - Useful API endpoints

    /// Reads the Jamf Pro organization name
    ///
    /// Requires "Read Activation Code" permission in the API
    /// - Parameter profileData: The prepared profile data
    func getOrganizationName() async throws -> String {
        let endpoint = "JSSResource/activationcode"
        var request = try url(forEndpoint: endpoint)

        request.httpMethod = "GET"
        request.setValue(applicationJson, forHTTPHeaderField: "Accept")

        let info: ActivationCode
        info = try await load(request: request)

        return info.activationCode.organizationName
    }

    /// Gets the Jamf Pro version
    ///
    /// No specific permissions required.
    /// - Returns: The Jamf Pro server version
    func getJamfProVersion() async throws -> JamfProVersion {
        let endpoint = "api/v1/jamf-pro-version"
        var request = try url(forEndpoint: endpoint)

        request.httpMethod = "GET"
        request.setValue(applicationJson, forHTTPHeaderField: "Accept")

        let info: JamfProVersion
        do {
            info = try await load(request: request)
        } catch is NetworkingError {
            // Possibly we are talking to Jamf Pro v10.22 or lower and we can grab the version from a meta tag on the login page.
            let simpleRequest = try url(forEndpoint: "")
            let (data, _) = try await URLSession.shared.data(for: simpleRequest)
            info = try JamfProVersion(fromHTMLString: String(data: data, encoding: .utf8))
        }

        return info
    }

    /// Uploads a computer configuration profile
    ///
    /// Requires "Create macOS Configuration Profiles" permission in the API
    /// - Parameter profileData: The prepared profile data
    func upload(computerConfigProfile profileData: Data) async throws {
        let endpoint = "JSSResource/osxconfigurationprofiles"
        var request = try url(forEndpoint: endpoint)

        request.httpMethod = "POST"
        request.httpBody = profileData
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("text/xml", forHTTPHeaderField: "Accept")

        _ = try await send(request: request)
    }
}
