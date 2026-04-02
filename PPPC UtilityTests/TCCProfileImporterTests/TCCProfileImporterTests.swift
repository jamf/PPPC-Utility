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
import Testing

@testable import PPPC_Utility

private final class BundleLocator {}

@Suite
struct TCCProfileImporterTests {

    @Test
    func malformedTCCProfile() throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCProfileSigned-Broken")

        tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL) { tccProfileResult in
            switch tccProfileResult {
            case .success:
                Issue.record("Malformed profile should not succeed")
            case .failure(let tccProfileError):
                if case TCCProfileImportError.invalidProfileFile = tccProfileError {
                } else {
                    Issue.record("Expected invalidProfileFile error, got \(tccProfileError)")
                }
            }
        }
    }

    @Test
    func emptyContentTCCProfile() throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCUnsignedProfile-Empty")
        let expectedTCCProfileError = TCCProfileImportError.invalidProfileFile(description: "PayloadContent")

        tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL) { tccProfileResult in
            switch tccProfileResult {
            case .success:
                Issue.record("Empty Content, it shouldn't be success")
            case .failure(let tccProfileError):
                #expect(tccProfileError.localizedDescription == expectedTCCProfileError.localizedDescription)
            }
        }
    }

    @Test
    func correctUnsignedProfileContentData() throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCUnsignedProfile")

        tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL) { tccProfileResult in
            switch tccProfileResult {
            case .success(let tccProfile):
                #expect(!tccProfile.content.isEmpty)
                #expect(!tccProfile.content[0].services.isEmpty)
            case .failure(let tccProfileError):
                Issue.record("Unable to read tccProfile \(tccProfileError.localizedDescription)")
            }
        }
    }

    @Test
    func correctUnsignedProfileContentDataAllLowercase() throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCUnsignedProfile-allLower")

        tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL) { tccProfileResult in
            switch tccProfileResult {
            case .success(let tccProfile):
                #expect(!tccProfile.content.isEmpty)
                #expect(!tccProfile.content[0].services.isEmpty)
            case .failure(let tccProfileError):
                Issue.record("Unable to read tccProfile \(tccProfileError.localizedDescription)")
            }
        }
    }

    @Test
    func brokenUnsignedProfile() throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCUnsignedProfile-Broken")
        let expectedTCCProfileError = TCCProfileImportError.invalidProfileFile(description: "The given data was not a valid property list.")

        tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL) { tccProfileResult in
            switch tccProfileResult {
            case .success:
                Issue.record("Broken Unsigned Profile, it shouldn't be success")
            case .failure(let tccProfileError):
                #expect(tccProfileError.localizedDescription == expectedTCCProfileError.localizedDescription)
            }
        }
    }

    private func getResourceProfile(fileName: String) throws -> URL {
        let testBundle = Bundle(for: BundleLocator.self)
        return try #require(testBundle.url(forResource: fileName, withExtension: "mobileconfig"))
    }
}
