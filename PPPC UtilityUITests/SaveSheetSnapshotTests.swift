//
//  SaveSheetSnapshotTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest
import SnapshotTesting

final class SaveSheetSnapshotTests: XCTestCase {

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

    func testSaveSheetDefaultStateSnapshot() throws {
        // when — trigger save sheet
        let saveButton = app.buttons["SaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.click()

        // then — wait for sheet to appear
        let payloadNameField = app.textFields["SavePayloadNameField"]
        XCTAssertTrue(payloadNameField.waitForExistence(timeout: 5))

        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "save-sheet-default")
    }

    func testSaveSheetFilledStateSnapshot() throws {
        // when — trigger save sheet and fill fields
        let saveButton = app.buttons["SaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.click()

        let payloadNameField = app.textFields["SavePayloadNameField"]
        XCTAssertTrue(payloadNameField.waitForExistence(timeout: 5))
        payloadNameField.click()
        payloadNameField.typeText("Test Profile")

        let organizationField = app.textFields["SaveOrganizationField"]
        XCTAssertTrue(organizationField.waitForExistence(timeout: 5))
        organizationField.click()
        organizationField.typeText("Test Org")

        // then
        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "save-sheet-filled")
    }
}
