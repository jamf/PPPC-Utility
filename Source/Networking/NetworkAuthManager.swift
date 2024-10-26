//
//  NetworkAuthManager.swift
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

/// API authentication errors
enum AuthError: Error, Equatable {
    /// When using a bearer token but the bearer token is not accepted by the server for the actual network call.
    case invalidToken

    /// When the username/password provided are empty or do not work when used with the server.
    case invalidUsernamePassword

    /// The server does not support Bearer Authentication for the API; this happens for Jamf Pro less than v10.34.
    case bearerAuthNotSupported
}

/// Support two main ways to authenticate to the Jamf Pro API.
enum AuthenticationInfo {
	case basicAuth(username: String, password: String)

	case clientCreds(id: String, secret: String)
}

/// This actor ensures that only one token refresh occurs at the same time.
actor NetworkAuthManager {
	private let authInfo: AuthenticationInfo

    private var currentToken: Token?
    private var refreshTask: Task<Token, Error>?

    private var supportsBearerAuth = true

    init(username: String, password: String) {
		authInfo = .basicAuth(username: username, password: password)
    }

	init(clientId: String, clientSecret: String) {
		authInfo = .clientCreds(id: clientId, secret: clientSecret)
	}

	func validToken(networking: Networking) async throws -> Token {
        if let task = refreshTask {
            // A refresh is already running; we'll use those results when ready.
            return try await task.value
        }

        if let token = currentToken,
           token.isValid {
            return token
        }

        return try await refreshToken(networking: networking)
    }

    func refreshToken(networking: Networking) async throws -> Token {
        if let task = refreshTask {
            // A refresh is already running; we'll use those results when ready.
            return try await task.value
        }

        // Initiate a refresh.
        let task = Task { () throws -> Token in
            defer { refreshTask = nil }

            do {
				let newToken = try await networking.getBearerToken(authInfo: authInfo)
                currentToken = newToken
                return newToken
            } catch NetworkingError.serverResponse(let responseCode, _) where responseCode == 404 {
                // If we got a 404 while trying to get a bearer token the server doesn't support bearer tokens.
                supportsBearerAuth = false
                throw AuthError.bearerAuthNotSupported
            } catch NetworkingError.serverResponse(let responseCode, _) where responseCode == 401 {
                // If we got a 401 while trying to get a bearer token the username/password was bad.
                throw AuthError.invalidUsernamePassword
            }
        }

        refreshTask = task

        return try await task.value
    }

    /// If bearer authentication is not actually supported, after the first network call trying to use bearer auth this will return false.
    ///
    /// The default is that bearer authentication is supported.  After the first network call attempting to use bearer auth, if the
    /// server does not actually support it this will return false.
    /// - Returns: True if bearer auth is supported.
    func bearerAuthSupported() async -> Bool {
        return supportsBearerAuth
    }

    /// Properly encodes the username and password for use in Basic authentication.
    ///
    /// This doesn't mutate any state and only accesses `let` constants so it doesn't need to be actor isolated.
    /// - Returns: The encoded data string for use with Basic Auth.
    nonisolated func basicAuthString() throws -> String {
		guard case .basicAuth(let username, let password) = authInfo,
			  !username.isEmpty && !password.isEmpty else {
            throw AuthError.invalidUsernamePassword
        }
        return Data("\(username):\(password)".utf8).base64EncodedString()
    }
}
