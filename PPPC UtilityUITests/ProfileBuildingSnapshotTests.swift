//
//  ProfileBuildingSnapshotTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest
import SnapshotTesting

final class ProfileBuildingSnapshotTests: XCTestCase {

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

    func testMainWindowWithExecutableSnapshot() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // when — select the preloaded executable
        table.tableRows.firstMatch.click()

        // then
        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "main-window-with-executable")
    }

    func testMainWindowWithPolicySetSnapshot() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // when — select executable and set a policy
        table.tableRows.firstMatch.click()

        let popup = app.popUpButtons["Policy.AddressBook"]
        XCTAssertTrue(popup.waitForExistence(timeout: 5))
        popup.click()

        let allowItem = popup.menuItems["Allow"]
        if allowItem.waitForExistence(timeout: 3) {
            allowItem.click()
        }

        // then
        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "main-window-with-policy-set")
    }
}
