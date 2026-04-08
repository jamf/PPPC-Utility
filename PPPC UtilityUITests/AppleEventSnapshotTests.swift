//
//  AppleEventSnapshotTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest
import SnapshotTesting

final class AppleEventSnapshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppleEventsTableWithRuleSnapshot() throws {
        let executablesTable = app.tables["ExecutablesTable"]
        XCTAssertTrue(executablesTable.waitForExistence(timeout: 5))

        // Setup — add an Apple Event rule
        executablesTable.tableRows.firstMatch.click()

        let addButton = app.buttons["AddAppleEventButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.click()

        let choicesTable = app.tables["AppleEventChoicesTable"]
        XCTAssertTrue(choicesTable.waitForExistence(timeout: 10))

        guard choicesTable.tableRows.count > 0 else {
            XCTFail("Choices table should have at least one row")
            return
        }
        choicesTable.tableRows.firstMatch.click()

        // then — snapshot the main window with the Apple Event rule
        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "apple-events-with-rule")
    }
}
