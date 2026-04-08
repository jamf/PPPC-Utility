//
//  MainWindowSnapshotTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest
import SnapshotTesting

final class MainWindowSnapshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testEmptyMainWindowSnapshot() throws {
        // then
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))

        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "empty-main-window")
    }
}
