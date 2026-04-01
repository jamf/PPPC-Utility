//
//  TokenTests.swift
//  PPPC UtilityTests
//
//  MIT License
//
//  Copyright (c) 2022 Jamf Software
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
@preconcurrency import XCTest

@testable import PPPC_Utility

class TokenTests: XCTestCase {
    func testPastIsNotValid() throws {
        // given
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expiration = try XCTUnwrap(formatter.date(from: "2021-06-22T22:05:58.81Z"))
        let token = Token(value: "abc", expiresAt: expiration)

        // when
        let valid = token.isValid

        // then
        XCTAssertFalse(valid)
    }

    func testFutureIsValid() throws {
        // given
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expiration = try XCTUnwrap(formatter.date(from: "2750-06-22T22:05:58.81Z"))
        let token = Token(value: "abc", expiresAt: expiration)

        // when
        let valid = token.isValid

        // then
        XCTAssertTrue(valid)
    }

    // MARK: - Decoding

    func testDecodeBasicAuthToken() throws {
        // given
        let jsonText = """
            {
            	"token": "abc",
            	"expires": "2750-06-22T22:05:58.81Z"
            }
            """
        let jsonData = try XCTUnwrap(jsonText.data(using: .utf8))
        let decoder = JSONDecoder()

        // when
        let actual = try decoder.decode(Token.self, from: jsonData)

        // then
        XCTAssertEqual(actual.value, "abc")
        XCTAssertNotNil(actual.expiresAt)
        XCTAssertTrue(actual.isValid)
    }

    func testDecodeExpiredBasicAuthToken() throws {
        // given
        let jsonText = """
            {
            	"token": "abc",
            	"expires": "1970-10-24T22:05:58.81Z"
            }
            """
        let jsonData = try XCTUnwrap(jsonText.data(using: .utf8))
        let decoder = JSONDecoder()

        // when
        let actual = try decoder.decode(Token.self, from: jsonData)

        // then
        XCTAssertEqual(actual.value, "abc")
        XCTAssertNotNil(actual.expiresAt)
        XCTAssertFalse(actual.isValid)
    }

    func testDecodeClientCredentialsAuthToken() throws {
        // given
        let jsonText = """
            {
            	"access_token": "abc",
            	"scope": "api-role:2",
            	"token_type": "Bearer",
            	"expires_in": 599
            }
            """
        let jsonData = try XCTUnwrap(jsonText.data(using: .utf8))
        let decoder = JSONDecoder()

        // when
        let actual = try decoder.decode(Token.self, from: jsonData)

        // then
        XCTAssertEqual(actual.value, "abc")
        XCTAssertNotNil(actual.expiresAt)
        XCTAssertTrue(actual.isValid)
    }
}
