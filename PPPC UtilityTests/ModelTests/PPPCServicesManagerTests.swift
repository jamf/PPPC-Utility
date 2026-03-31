//
//  PPPCServicesManagerTests.swift
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

class PPPCServicesManagerTests: XCTestCase {

    @MainActor func testLoadAllServices() async {
        // given/when
        let actual = PPPCServicesManager()

        // then
        XCTAssertEqual(actual.allServices.count, 21)
    }

    @MainActor func testUserHelp_withEntitlements() async throws {
        // given
        let services = PPPCServicesManager()
        let service = try XCTUnwrap(services.allServices["Camera"])

        // when
        let actual = service.userHelp

        // then
        XCTAssertEqual(actual, "Use to deny specified apps access to the camera.\n\nMDM Key: Camera\nRelated entitlements: [\"com.apple.developer.avfoundation.multitasking-camera-access\", \"com.apple.security.device.camera\"]")
    }

    @MainActor func testUserHelp_withoutEntitlements() async throws {
        // given
        let services = PPPCServicesManager()
        let service = try XCTUnwrap(services.allServices["ScreenCapture"])

        // when
        let actual = service.userHelp

        // then
        XCTAssertEqual(actual, "Deny specified apps access to capture (read) the contents of the system display.\n\nMDM Key: ScreenCapture")
    }

    @MainActor func testCameraIsDenyOnly() async throws {
        // given
        let services = PPPCServicesManager()
        let service = try XCTUnwrap(services.allServices["Camera"])

        // when
        let actual = try XCTUnwrap(service.denyOnly)

        // then
        XCTAssertTrue(actual)
    }

    @MainActor func testScreenCaptureAllowsStandardUsers() async throws {
        // given
        let services = PPPCServicesManager()
        let service = try XCTUnwrap(services.allServices["ScreenCapture"])

        // when
        let actual = try XCTUnwrap(service.allowStandardUsers)

        // then
        XCTAssertTrue(actual)
    }
}
