//
//  SemanticVersionTests.swift
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
@testable import PPPC_Utility
@preconcurrency import XCTest

class SemanticVersionTests: XCTestCase {
    func testLessThan() {
        // given
        let version = SemanticVersion(major: 10, minor: 7, patch: 1)

        // when
        let shouldBeLessThan = version < SemanticVersion(major: 10, minor: 7, patch: 4)
        let shouldBeLessThan2 = version < SemanticVersion(major: 10, minor: 8, patch: 1)
        let shouldBeLessThan3 = version < SemanticVersion(major: 11, minor: 7, patch: 1)
        let shouldNotBeLessThan = version < SemanticVersion(major: 10, minor: 7, patch: 1)
        let shouldNotBeLessThan2 = version < SemanticVersion(major: 10, minor: 7, patch: 0)
        let shouldNotBeLessThan3 = version < SemanticVersion(major: 10, minor: 6, patch: 1)
        let shouldNotBeLessThan4 = version < SemanticVersion(major: 9, minor: 7, patch: 1)

        // then
        XCTAssertTrue(shouldBeLessThan)
        XCTAssertTrue(shouldBeLessThan2)
        XCTAssertTrue(shouldBeLessThan3)
        XCTAssertFalse(shouldNotBeLessThan)
        XCTAssertFalse(shouldNotBeLessThan2)
        XCTAssertFalse(shouldNotBeLessThan3)
        XCTAssertFalse(shouldNotBeLessThan4)
    }

    func testEquality() {
        // given
        let version = SemanticVersion(major: 10, minor: 7, patch: 1)

        // when
        let shouldBeEqual = version == SemanticVersion(major: 10, minor: 7, patch: 1)
        let shouldBeNotEqual = version == SemanticVersion(major: 10, minor: 7, patch: 4)
        let shouldBeNotEqual2 = version == SemanticVersion(major: 10, minor: 8, patch: 1)
        let shouldBeNotEqual3 = version == SemanticVersion(major: 11, minor: 7, patch: 1)

        // then
        XCTAssertTrue(shouldBeEqual)
        XCTAssertFalse(shouldBeNotEqual)
        XCTAssertFalse(shouldBeNotEqual2)
        XCTAssertFalse(shouldBeNotEqual3)
    }

    func testGreaterThan() {
        // given
        let version = SemanticVersion(major: 10, minor: 7, patch: 1)

        // when
        let shouldNotBeGreaterThan = version > SemanticVersion(major: 10, minor: 7, patch: 4)
        let shouldNotBeGreaterThan2 = version > SemanticVersion(major: 10, minor: 8, patch: 1)
        let shouldNotBeGreaterThan3 = version > SemanticVersion(major: 11, minor: 7, patch: 1)
        let shouldNotBeGreaterThan4 = version > SemanticVersion(major: 10, minor: 7, patch: 1)
        let shouldBeGreaterThan = version > SemanticVersion(major: 10, minor: 7, patch: 0)
        let shouldBeGreaterThan2 = version > SemanticVersion(major: 10, minor: 6, patch: 1)
        let shouldBeGreaterThan3 = version > SemanticVersion(major: 9, minor: 7, patch: 1)

        // then
        XCTAssertFalse(shouldNotBeGreaterThan)
        XCTAssertFalse(shouldNotBeGreaterThan2)
        XCTAssertFalse(shouldNotBeGreaterThan3)
        XCTAssertFalse(shouldNotBeGreaterThan4)
        XCTAssertTrue(shouldBeGreaterThan)
        XCTAssertTrue(shouldBeGreaterThan2)
        XCTAssertTrue(shouldBeGreaterThan3)
    }
}
