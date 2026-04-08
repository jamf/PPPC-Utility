//
//  FullWorkflowSnapshotTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest
import SnapshotTesting

/// End-to-end light-mode snapshots of key screens as a visual regression baseline.
final class FullWorkflowSnapshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        app.launchArguments.append("-UITestStubNetwork")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Empty State

    func testEmptyStateSnapshot() throws {
        // Launch without UITestMode for empty state
        let freshApp = XCUIApplication()
        freshApp.launch()

        let mainWindow = freshApp.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))

        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "workflow-01-empty-state")
    }

    // MARK: - Executable Added

    func testExecutableAddedSnapshot() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // Select the preloaded executable
        table.tableRows.firstMatch.click()

        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "workflow-02-executable-added")
    }

    // MARK: - Policies Configured

    func testPoliciesConfiguredSnapshot() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        table.tableRows.firstMatch.click()

        // Set some policies
        let addressBookPopup = app.popUpButtons["Policy.AddressBook"]
        XCTAssertTrue(addressBookPopup.waitForExistence(timeout: 5))
        addressBookPopup.click()
        let allowItem = addressBookPopup.menuItems["Allow"]
        if allowItem.waitForExistence(timeout: 3) {
            allowItem.click()
        }

        let cameraPopup = app.popUpButtons["Policy.Camera"]
        XCTAssertTrue(cameraPopup.waitForExistence(timeout: 5))
        cameraPopup.click()
        let denyItem = cameraPopup.menuItems["Deny"]
        if denyItem.waitForExistence(timeout: 3) {
            denyItem.click()
        }

        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "workflow-03-policies-configured")
    }

    // MARK: - Apple Event Added

    func testAppleEventAddedSnapshot() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        table.tableRows.firstMatch.click()

        // Add an Apple Event
        let addButton = app.buttons["AddAppleEventButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.click()

        let choicesTable = app.tables["AppleEventChoicesTable"]
        XCTAssertTrue(choicesTable.waitForExistence(timeout: 10))

        guard choicesTable.tableRows.count > 0 else {
            XCTFail("Choices table should have rows")
            return
        }
        choicesTable.tableRows.firstMatch.click()

        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "workflow-04-apple-event-added")
    }

    // MARK: - Save Sheet

    func testSaveSheetSnapshot() throws {
        let saveButton = app.buttons["SaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.click()

        let payloadNameField = app.textFields["SavePayloadNameField"]
        XCTAssertTrue(payloadNameField.waitForExistence(timeout: 5))

        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "workflow-05-save-sheet")
    }

    // MARK: - Upload Sheet

    func testUploadSheetSnapshot() throws {
        // Dismiss save sheet if open, then open upload sheet
        let uploadButton = app.buttons["UploadButton"]
        XCTAssertTrue(uploadButton.waitForExistence(timeout: 5))
        uploadButton.click()

        let serverField = app.textFields["UploadServerURLField"]
        XCTAssertTrue(serverField.waitForExistence(timeout: 5))

        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "workflow-06-upload-sheet")
    }
}
