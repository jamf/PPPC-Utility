//
//  Token.swift
//  PPPC Utility
//
//  SPDX-License-Identifier: MIT
//  Copyright (c) 2023 Jamf Software

import Foundation

/// Network authentication token for Jamf Pro connection.
///
/// Decodes network response for authentication tokens from Jamf Pro for both the newer OAuth client credentials flow
/// and the older basic-auth-based flow.
struct Token: Decodable {
    let value: String
    let expiresAt: Date?

    var isValid: Bool {
        if let expiration = expiresAt {
            return expiration > Date()
        }

        return true
    }

    enum OAuthTokenCodingKeys: String, CodingKey {
        case value = "access_token"
        case expire = "expires_in"
    }

    enum BasicAuthCodingKeys: String, CodingKey {
        case value = "token"
        case expireTime = "expires"
    }

    init(from decoder: Decoder) throws {
        // First try to decode with oauth client credentials token response
        let container = try decoder.container(keyedBy: OAuthTokenCodingKeys.self)
        let possibleValue = try? container.decode(String.self, forKey: .value)
        if let value = possibleValue {
            self.value = value
            let expireIn = try container.decode(Double.self, forKey: .expire)
            self.expiresAt = Date().addingTimeInterval(expireIn)
            return
        }

        // If that fails try to decode with basic auth token response
        let container1 = try decoder.container(keyedBy: BasicAuthCodingKeys.self)
        self.value = try container1.decode(String.self, forKey: .value)
        let expireTime = try container1.decode(String.self, forKey: .expireTime)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.expiresAt = formatter.date(from: expireTime)
    }

    init(value: String, expiresAt: Date) {
        self.value = value
        self.expiresAt = expiresAt
    }
}
