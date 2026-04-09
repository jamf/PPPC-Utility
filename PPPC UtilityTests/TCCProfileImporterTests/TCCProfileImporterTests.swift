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

        do {
            _ = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
            Issue.record("Malformed profile should not succeed")
        } catch {
            if case TCCProfileImportError.invalidProfileFile = error {
            } else {
                Issue.record("Expected invalidProfileFile error, got \(error)")
            }
        }
    }

    @Test
    func emptyContentTCCProfile() throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCUnsignedProfile-Empty")
        let expectedTCCProfileError = TCCProfileImportError.invalidProfileFile(description: "PayloadContent")

        do {
            _ = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
            Issue.record("Empty Content, it shouldn't be success")
        } catch {
            #expect(error.localizedDescription == expectedTCCProfileError.localizedDescription)
        }
    }

    @Test
    func correctUnsignedProfileContentData() throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCUnsignedProfile")

        let tccProfile = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
        #expect(!tccProfile.content.isEmpty)
        #expect(!tccProfile.content[0].services.isEmpty)
        #expect(tccProfile.content[0].services.count >= 24, "Profile should contain at least 24 services including 3 new keys")
    }

    @Test("Legacy profile without new keys imports with dash defaults")
    func legacyProfileImportsWithDashDefaults() async throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCUnsignedProfile-Legacy")
        let tccProfile = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)

        // when
        let model = Model()
        await model.importProfile(tccProfile: tccProfile)

        // then
        for executable in model.selectedExecutables {
            #expect(executable.policy.BluetoothAlways == "-", "BluetoothAlways should default to dash for legacy profiles")
            #expect(executable.policy.SystemPolicyAppBundles == "-", "SystemPolicyAppBundles should default to dash for legacy profiles")
            #expect(executable.policy.SystemPolicyAppData == "-", "SystemPolicyAppData should default to dash for legacy profiles")
        }
    }

    @Test
    func correctUnsignedProfileContentDataAllLowercase() throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCUnsignedProfile-allLower")

        let tccProfile = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
        #expect(!tccProfile.content.isEmpty)
        #expect(!tccProfile.content[0].services.isEmpty)
    }

    @Test
    func brokenUnsignedProfile() throws {
        let tccProfileImporter = TCCProfileImporter()
        let resourceURL = try getResourceProfile(fileName: "TestTCCUnsignedProfile-Broken")
        let expectedTCCProfileError = TCCProfileImportError.invalidProfileFile(description: "The given data was not a valid property list.")

        do {
            _ = try tccProfileImporter.decodeTCCProfile(fileUrl: resourceURL)
            Issue.record("Broken Unsigned Profile, it shouldn't be success")
        } catch {
            #expect(error.localizedDescription == expectedTCCProfileError.localizedDescription)
        }
    }

    private func getResourceProfile(fileName: String) throws -> URL {
        let testBundle = Bundle(for: BundleLocator.self)
        return try #require(testBundle.url(forResource: fileName, withExtension: "mobileconfig"))
    }
}
