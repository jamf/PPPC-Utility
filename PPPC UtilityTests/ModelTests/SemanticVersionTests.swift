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
import Testing

@testable import PPPC_Utility

@Suite
struct SemanticVersionTests {
    let version = SemanticVersion(major: 10, minor: 7, patch: 1)

    @Test
    func lessThan() {
        #expect(version < SemanticVersion(major: 10, minor: 7, patch: 4))
        #expect(version < SemanticVersion(major: 10, minor: 8, patch: 1))
        #expect(version < SemanticVersion(major: 11, minor: 7, patch: 1))
        #expect(!(version < SemanticVersion(major: 10, minor: 7, patch: 1)))
        #expect(!(version < SemanticVersion(major: 10, minor: 7, patch: 0)))
        #expect(!(version < SemanticVersion(major: 10, minor: 6, patch: 1)))
        #expect(!(version < SemanticVersion(major: 9, minor: 7, patch: 1)))
    }

    @Test
    func equality() {
        #expect(version == SemanticVersion(major: 10, minor: 7, patch: 1))
        #expect(version != SemanticVersion(major: 10, minor: 7, patch: 4))
        #expect(version != SemanticVersion(major: 10, minor: 8, patch: 1))
        #expect(version != SemanticVersion(major: 11, minor: 7, patch: 1))
    }

    @Test
    func greaterThan() {
        #expect(!(version > SemanticVersion(major: 10, minor: 7, patch: 4)))
        #expect(!(version > SemanticVersion(major: 10, minor: 8, patch: 1)))
        #expect(!(version > SemanticVersion(major: 11, minor: 7, patch: 1)))
        #expect(!(version > SemanticVersion(major: 10, minor: 7, patch: 1)))
        #expect(version > SemanticVersion(major: 10, minor: 7, patch: 0))
        #expect(version > SemanticVersion(major: 10, minor: 6, patch: 1))
        #expect(version > SemanticVersion(major: 9, minor: 7, patch: 1))
    }
}
