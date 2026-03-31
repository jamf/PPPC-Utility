//
//  TCCProfileImporterTests.swift
//  PPPC UtilityTests
//
//  MIT License
//
//  Copyright (c) 2019 Jamf Software
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

class TCCProfileImporterTests: XCTestCase {

    @MainActor func testMalformedTCCProfile() async {
        let tccProfileImporter = TCCProfileImporter()

        let resourceURL = getResourceProfile(fileName: "TestTCCProfileSigned-Broken")

        do {
            _ = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
            XCTFail("Malformed profile should not succeed")
        } catch {
            if case TCCProfileImportError.invalidProfileFile = error { } else {
                XCTFail("Expected invalidProfileFile error, got \(error)")
            }
        }
    }

    @MainActor func testEmptyContentTCCProfile() async {
        let tccProfileImporter = TCCProfileImporter()

        let resourceURL = getResourceProfile(fileName: "TestTCCUnsignedProfile-Empty")

        let expectedTCCProfileError = TCCProfileImportError.invalidProfileFile(description: "PayloadContent")

        do {
            _ = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
            XCTFail("Empty Content, it shouldn't be success")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedTCCProfileError.localizedDescription)
        }
    }

    @MainActor func testCorrectUnsignedProfileContentData() async throws {
        let tccProfileImporter = TCCProfileImporter()

        let resourceURL = getResourceProfile(fileName: "TestTCCUnsignedProfile")

        let tccProfile = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
        XCTAssertNotNil(tccProfile.content)
        XCTAssertNotNil(tccProfile.content[0].services)
    }

    @MainActor func testCorrectUnsignedProfileContentDataAllLowercase() async throws {
        let tccProfileImporter = TCCProfileImporter()

        let resourceURL = getResourceProfile(fileName: "TestTCCUnsignedProfile-allLower")

        let tccProfile = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
        XCTAssertNotNil(tccProfile.content)
        XCTAssertNotNil(tccProfile.content[0].services)
    }

    @MainActor func testBrokenUnsignedProfile() async {
        let tccProfileImporter = TCCProfileImporter()

        let resourceURL = getResourceProfile(fileName: "TestTCCUnsignedProfile-Broken")

        let expectedTCCProfileError = TCCProfileImportError.invalidProfileFile(description: "The given data was not a valid property list.")

        do {
            _ = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
            XCTFail("Broken Unsigned Profile, it shouldn't be success")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedTCCProfileError.localizedDescription)
        }
    }

    private func getResourceProfile(fileName: String) -> URL {
        let testBundle = Bundle(for: type(of: self))
        guard let resourceURL = testBundle.url(forResource: fileName, withExtension: "mobileconfig") else {
            XCTFail("Resource file should exists")
            return URL(fileURLWithPath: "invalidPath")
        }
        return resourceURL
    }
}
