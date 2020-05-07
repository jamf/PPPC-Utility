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
import XCTest

@testable import PPPC_Utility

class TCCProfileImporterTests: XCTestCase {

    func testBrokenSignedTCCProfile() {
        let tccProfileImporter = TCCProfileImporter()

        let resourceURL = getResourceProfile(fileName: "TestTCCProfileSigned-Broken")

        tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL, { tccProfileResult in
            switch tccProfileResult {
            case .success:
                XCTFail("Broken Signed Profile, it shouldn't be success")
            case .failure(let tccProfileError):
                XCTAssertTrue(tccProfileError.localizedDescription.contains("The given data was not a valid property list."))
            }
        })
    }

    func testEmptyContentTCCProfile() {
        let tccProfileImporter = TCCProfileImporter()

        let resourceURL = getResourceProfile(fileName: "TestTCCUnsignedProfile-Empty")

        let expectedTCCProfileError = TCCProfileImportError.invalidProfileFile(description: "PayloadContent")

        tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL, { tccProfileResult in
            switch tccProfileResult {
            case .success:
                XCTFail("Empty Content, it shouldn't be success")
            case .failure(let tccProfileError):
                XCTAssertEqual(tccProfileError.localizedDescription, expectedTCCProfileError.localizedDescription)
            }
        })
    }

    func testCorrectUnsignedProfileContentData() {
        let tccProfileImporter = TCCProfileImporter()

        let resourceURL = getResourceProfile(fileName: "TestTCCUnsignedProfile")

        tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL, { tccProfileResult in
            switch tccProfileResult {
            case .success(let tccProfile):
                XCTAssertNotNil(tccProfile.content)
                XCTAssertNotNil(tccProfile.content[0].services)
            case .failure(let tccProfileError):
                XCTFail("Unable to read tccProfile \(tccProfileError.localizedDescription)")
            }
        })
    }

    func testBrokenUnsignedProfile() {
        let tccProfileImporter = TCCProfileImporter()

        let resourceURL = getResourceProfile(fileName: "TestTCCUnsignedProfile-Broken")

        let expectedTCCProfileError = TCCProfileImportError.invalidProfileFile(description: "The given data was not a valid property list.")

        tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL, { tccProfileResult in
            switch tccProfileResult {
            case .success:
                XCTFail("Broken Unsigned Profile, it shouldn't be success")
            case .failure(let tccProfileError):
                XCTAssertEqual(tccProfileError.localizedDescription, expectedTCCProfileError.localizedDescription)
            }
        })
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
