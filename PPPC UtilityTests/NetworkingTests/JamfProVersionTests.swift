//
//  JamfProVersionTests.swift
//  PPPC UtilityTests
//
//  MIT License
//
//  Copyright (c) 2026 Jamf Software
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
import Testing

@testable import PPPC_Utility

@Suite
struct JamfProVersionTests {
    @Test("mainVersionInfo strips non-numeric suffix")
    func mainVersionInfoStripsSuffix() throws {
        let data = Data("{\"version\":\"10.7.1-b123\"}".utf8)
        let version = try JSONDecoder().decode(JamfProVersion.self, from: data)

        // when
        let main = version.mainVersionInfo()

        // then
        #expect(main == "10.7.1")
    }

    @Test("semantic parses major, minor, and patch components")
    func semanticParsesComponents() throws {
        let data = Data("{\"version\":\"10.7.1-b123\"}".utf8)
        let version = try JSONDecoder().decode(JamfProVersion.self, from: data)

        // when
        let semantic = version.semantic()

        // then
        #expect(semantic == SemanticVersion(major: 10, minor: 7, patch: 1))
    }

    @Test("Init from HTML string parses valid version")
    func initFromHTMLStringParsesVersion() throws {
        let html = "<html><head><meta name=\"version\" content=\"10.7.1-123\"></head></html>"

        // when
        let parsed = try JamfProVersion(fromHTMLString: html)

        // then
        #expect(parsed.version == "10.7.1")
    }

    @Test("Init from HTML string throws on nil, missing tag, or malformed version")
    func initFromHTMLStringThrowsOnMissingOrMalformed() {
        // when/then
        #expect(throws: NSError.self) {
            _ = try JamfProVersion(fromHTMLString: nil)
        }
        #expect(throws: NSError.self) {
            _ = try JamfProVersion(fromHTMLString: "<html></html>")
        }
        #expect(throws: NSError.self) {
            _ = try JamfProVersion(fromHTMLString: "<meta name=\"version\" content=\"10.7-123\">")
        }
    }
}
