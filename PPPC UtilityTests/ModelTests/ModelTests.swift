//
//  ModelTests.swift
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

class ModelTests: XCTestCase {

    func testGetExecutableBasedOnIdentifierAndCodeRequirement_BundleIdentifierType() {
        //given
            let identifier = "com.example.App"
            let codeRequirement = "testCodeRequirement"

            let model = Model()

        //when
            let executable = model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        //then
            XCTAssertEqual(executable.displayName, "App")
            XCTAssertEqual(executable.codeRequirement, codeRequirement)
            XCTAssertEqual(executable.iconPath, IconFilePath.application)
    }

    func testGetExecutableBasedOnIdentifierAndCodeRequirement_PathIdentifierType() {
        //given
        let identifier = "/myGreatPath/Awesome/Binary"
        let codeRequirement = "testCodeRequirement"

        let model = Model()

        //when
        let executable = model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        //then
        XCTAssertEqual(executable.displayName, "Binary")
        XCTAssertEqual(executable.codeRequirement, codeRequirement)
        XCTAssertEqual(executable.iconPath, IconFilePath.binary)
    }

    func testGetExecutableFromComputerBasedOnIdentifier() {
        //given
            let identifier = "com.apple.Safari"
            let codeRequirement = "randomReq"

            let model = Model()
        //when
            let executable = model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        //then
            XCTAssertEqual(executable.displayName, "Safari")
            XCTAssertNotEqual(executable.iconPath, IconFilePath.application)
            XCTAssertNotEqual(codeRequirement, executable.codeRequirement)
    }

    func testGetExecutableFromSelectedExecutables() {
        //given
        let model = Model()

        let expectedIdentifier = "com.something.1"
        let executable = model.getExecutableFrom(identifier: expectedIdentifier, codeRequirement: "testReq")
        let executableSecond = model.getExecutableFrom(identifier: "com.something.2", codeRequirement: "testReq2")
        model.selectedExecutables = [executable, executableSecond]

        //when
        let existingExecutable = model.getExecutableFromSelectedExecutables(bundleIdentifier: "com.something.1")

        //then
        XCTAssertNotNil(existingExecutable)
        XCTAssertEqual(existingExecutable?.identifier, expectedIdentifier)
        XCTAssertEqual(existingExecutable?.displayName, "1")
        XCTAssertEqual(existingExecutable?.iconPath, IconFilePath.application)
    }

    func testGetExecutableFromSelectedExecutables_Path() {
        //given
        let model = Model()

        let expectedIdentifier = "/path/something/Special"

        let executableOneMore = model.getExecutableFrom(identifier: "/path/something/Special1", codeRequirement: "testReq")
        let executable = model.getExecutableFrom(identifier: expectedIdentifier, codeRequirement: "testReq")
        let executableSecond = model.getExecutableFrom(identifier: "com.something.2", codeRequirement: "testReq2")
        model.selectedExecutables = [executableOneMore, executable, executableSecond]

        //when
        let existingExecutable = model.getExecutableFromSelectedExecutables(bundleIdentifier: "/path/something/Special")

        //then
        XCTAssertNotNil(existingExecutable)
        XCTAssertEqual(existingExecutable?.identifier, expectedIdentifier)
        XCTAssertEqual(existingExecutable?.displayName, "Special")
        XCTAssertEqual(existingExecutable?.iconPath, IconFilePath.binary)
    }

    func testGetExecutableFromSelectedExecutables_Empty() {
        // given
        let model = Model()

        //when
        let existingExecutable = model.getExecutableFromSelectedExecutables(bundleIdentifier: "com.something.1")

        //then
        XCTAssertNil(existingExecutable)
    }

}
