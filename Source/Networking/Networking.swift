//
//  Networking.swift
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

/// Problems at the networking error throw this type of error.
enum NetworkingError: Error, Equatable, Sendable {
    /// The server URL cannot be converted into a standard URL.
    ///
    /// The associated value is the given server URL.
    case badServerUrl(String)

    /// If the server returns anything outside of 200...299 this is the error thrown.
    ///
    /// The first associated value is the HTTP response code.  The second associated value is the full URL that was attempted.
    case serverResponse(Int, String)

    /// This is thrown if a subclass does not implement ``getBearerToken(authInfo:)`` and then attempts to use bearer tokens.
    case unimplemented
}

class Networking: @unchecked Sendable {
    let authManager: NetworkAuthManager
    let serverUrlString: String

    init(serverUrlString: String, tokenManager: NetworkAuthManager) {
        self.serverUrlString = serverUrlString
        self.authManager = tokenManager
    }

    /// Subclasses must override this to do a network call to return a bearer token.
    /// - Returns: A token
    func getBearerToken(authInfo: AuthenticationInfo) async throws -> Token {
        throw NetworkingError.unimplemented
    }

    /// Create a `URLRequest` for the endpoint based on the `serverUrlString`
    /// - Parameter endpoint: The endpoint URL path
    /// - Returns: A `URLRequest` representing the endpoint on the server
    /// - Throws: May throw a `NetworkingError.badServerUrl` error
    func url(forEndpoint endpoint: String) throws -> URLRequest {
        guard let serverURL = URL(string: serverUrlString) else {
            throw NetworkingError.badServerUrl(serverUrlString)
        }
        let url = serverURL.appendingPathComponent(endpoint)

        return URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 45.0)
    }

	/// Sends a `URLRequest` and decodes a response to an endpoint.
	/// - Parameter request: A request that already has authorization info.
	/// - Returns: The result.
	func loadPreAuthorized<T: Decodable>(request: URLRequest) async throws -> T {
		let (data, urlResponse) = try await URLSession.shared.data(for: request)

		if let httpResponse = urlResponse as? HTTPURLResponse {
			if httpResponse.statusCode == 401 {
				throw AuthError.invalidUsernamePassword
			} else if !(200...299).contains(httpResponse.statusCode) {
				throw NetworkingError.serverResponse(httpResponse.statusCode, request.url?.absoluteString ?? "")
			}
		}

		let decoder = JSONDecoder()
		let response = try decoder.decode(T.self, from: data)

		return response
	}

	/// Sends a `URLRequest` and decodes a response to a Basic Auth protected endpoint.
    /// - Parameter request: A request that does not yet include authorization info.
    /// - Returns: The result.
    func loadBasicAuthorized<T: Decodable>(request: URLRequest) async throws -> T {
        let authorizedRequest = try await authorizeBasic(request: request)
        let (data, urlResponse) = try await URLSession.shared.data(for: authorizedRequest)

        if let httpResponse = urlResponse as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                throw AuthError.invalidUsernamePassword
            } else if !(200...299).contains(httpResponse.statusCode) {
                throw NetworkingError.serverResponse(httpResponse.statusCode, request.url?.absoluteString ?? "")
            }
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(T.self, from: data)

        return response
    }

    /// Sends a `URLRequest` and decodes a response to a Bearer Auth protected endpoint.
    /// - Parameter request: A request that does not yet include authorization info.
    /// - Returns: The result.
    func loadBearerAuthorized<T: Decodable>(request: URLRequest, allowRetryForAuth: Bool = true) async throws -> T {
        let authorizedRequest = try await authorizeBearer(request: request)
        let (data, urlResponse) = try await URLSession.shared.data(for: authorizedRequest)

        if let httpResponse = urlResponse as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                if allowRetryForAuth {
                    _ = try await authManager.refreshToken(networking: self)
                    return try await loadBearerAuthorized(request: request, allowRetryForAuth: false)
                }

                throw AuthError.invalidToken
            } else if !(200...299).contains(httpResponse.statusCode) {
                throw NetworkingError.serverResponse(httpResponse.statusCode, request.url?.absoluteString ?? "")
            }
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(T.self, from: data)

        return response
    }

    /// Sends a `URLRequest` to a Bearer Auth protected endpoint and returns any response.
    /// - Parameter request: A request that does not yet include authorization info.
    /// - Returns: The result.
    func sendBearerAuthorized(request: URLRequest, allowRetryForAuth: Bool = true) async throws -> Data {
        let authorizedRequest = try await authorizeBearer(request: request)
        let (data, urlResponse) = try await URLSession.shared.data(for: authorizedRequest)

        if let httpResponse = urlResponse as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                if allowRetryForAuth {
                    _ = try await authManager.refreshToken(networking: self)
                    return try await loadBearerAuthorized(request: request, allowRetryForAuth: false)
                }

                throw AuthError.invalidToken
            } else if !(200...299).contains(httpResponse.statusCode) {
                throw NetworkingError.serverResponse(httpResponse.statusCode, request.url?.absoluteString ?? "")
            }
        }

        return data
    }

    /// Sends a `URLRequest` to a Basic Auth protected endpoint and returns any response.
    /// - Parameter request: A request that does not yet include authorization info.
    /// - Returns: The result.
    func sendBasicAuthorized(request: URLRequest) async throws -> Data {
        let authorizedRequest = try await authorizeBasic(request: request)
        let (data, urlResponse) = try await URLSession.shared.data(for: authorizedRequest)

        if let httpResponse = urlResponse as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                throw AuthError.invalidUsernamePassword
            } else if !(200...299).contains(httpResponse.statusCode) {
                throw NetworkingError.serverResponse(httpResponse.statusCode, request.url?.absoluteString ?? "")
            }
        }

        return data
    }

    /// Given a `URLRequest`, adds a bearer token from the ``authManager``
    /// - Parameter request: A URLRequest
    /// - Returns: The request with the bearer token added
    private func authorizeBearer(request: URLRequest) async throws -> URLRequest {
        let token = try await authManager.validToken(networking: self)
        var newRequest = request
        newRequest.setValue("Bearer \(token.value)", forHTTPHeaderField: "Authorization")
        return newRequest
    }

    /// Given a `URLRequest`, adds a basic authorization header with info from the ``authManager``
    /// - Parameter request: A URLRequest
    /// - Returns: The request with the bearer token added
    private func authorizeBasic(request: URLRequest) async throws -> URLRequest {
        let basicValue = try authManager.basicAuthString()
        var newRequest = request
        newRequest.setValue("Basic \(basicValue)", forHTTPHeaderField: "Authorization")
        return newRequest
    }
}
