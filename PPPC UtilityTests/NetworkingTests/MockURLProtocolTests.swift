//
//  MockURLProtocolTests.swift
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

import Testing
import Foundation
@testable import PPPC_Utility

@Suite("MockURLProtocol", .serialized)
struct MockURLProtocolTests {

    @Test("Injected session intercepts requests and returns expected data")
    func injectedSessionInterceptsRequests() async throws {
        let expectedBody = Data("hello".utf8)
        let session = URLSession.mock { request in
            let url = request.url!
            return (.ok(url: url), expectedBody)
        }
        defer { MockURLProtocol.reset() }

        // when
        let url = URL(string: "https://example.com/test")!
        let (data, response) = try await session.data(for: URLRequest(url: url))

        // then
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        #expect(data == expectedBody)
    }

    @Test("Handler can return error status codes")
    func handlerReturnsErrorStatusCode() async throws {
        let session = URLSession.mock { request in
            let url = request.url!
            return (.status(401, url: url), Data())
        }
        defer { MockURLProtocol.reset() }

        // when
        let url = URL(string: "https://example.com/auth")!
        let (_, response) = try await session.data(for: URLRequest(url: url))

        // then
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 401)
    }

    @Test("Reset clears the handler")
    func resetClearsHandler() async {
        let session = URLSession.mock { request in
            let url = request.url!
            return (.ok(url: url), Data())
        }

        // when
        MockURLProtocol.reset()

        // then
        let url = URL(string: "https://example.com/test")!
        do {
            _ = try await session.data(for: URLRequest(url: url))
            Issue.record("Expected request to fail after reset")
        } catch {
            // Expected — no handler registered
        }
    }
}
