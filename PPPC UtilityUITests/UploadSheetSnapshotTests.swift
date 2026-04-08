//
//  UploadSheetSnapshotTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest
import SnapshotTesting

final class UploadSheetSnapshotTests: XCTestCase {

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

    private func openUploadSheet() {
        let uploadButton = app.buttons["UploadButton"]
        XCTAssertTrue(uploadButton.waitForExistence(timeout: 5))
        uploadButton.click()
    }

    func testEmptyFormSnapshot() throws {
        // when
        openUploadSheet()

        let serverField = app.textFields["UploadServerURLField"]
        XCTAssertTrue(serverField.waitForExistence(timeout: 5))

        // then
        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "upload-sheet-empty")
    }

    func testBasicAuthFilledSnapshot() throws {
        // when
        openUploadSheet()

        // Switch to Basic Auth
        let authPicker = app.popUpButtons["UploadAuthTypePicker"]
        XCTAssertTrue(authPicker.waitForExistence(timeout: 5))
        authPicker.click()
        let basicAuth = authPicker.menuItems["Basic/Bearer Auth"]
        if basicAuth.waitForExistence(timeout: 3) {
            basicAuth.click()
        }

        // Fill fields
        let serverField = app.textFields["UploadServerURLField"]
        XCTAssertTrue(serverField.waitForExistence(timeout: 5))
        serverField.click()
        serverField.typeKey("a", modifierFlags: .command)
        serverField.typeText("https://example.jamfcloud.com")

        let usernameField = app.textFields["UploadUsernameField"]
        usernameField.click()
        usernameField.typeText("admin")

        // then
        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "upload-sheet-basic-auth-filled")
    }

    func testClientCredentialsFilledSnapshot() throws {
        // when
        openUploadSheet()

        // Ensure Client Credentials is selected
        let authPicker = app.popUpButtons["UploadAuthTypePicker"]
        XCTAssertTrue(authPicker.waitForExistence(timeout: 5))
        authPicker.click()
        let clientCreds = authPicker.menuItems["Client Credentials (v10.49+):"]
        if clientCreds.waitForExistence(timeout: 3) {
            clientCreds.click()
        }

        // Fill fields
        let serverField = app.textFields["UploadServerURLField"]
        XCTAssertTrue(serverField.waitForExistence(timeout: 5))
        serverField.click()
        serverField.typeKey("a", modifierFlags: .command)
        serverField.typeText("https://example.jamfcloud.com")

        let clientIdField = app.textFields["UploadUsernameField"]
        clientIdField.click()
        clientIdField.typeText("client-id-abc123")

        // then
        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "upload-sheet-client-credentials-filled")
    }

    func testSiteFieldsVisibleSnapshot() throws {
        // when
        openUploadSheet()

        let siteToggle = app.checkBoxes["UploadUseSiteToggle"]
        XCTAssertTrue(siteToggle.waitForExistence(timeout: 5))

        if siteToggle.value as? Int != 1 {
            siteToggle.click()
        }

        let siteIdField = app.textFields["UploadSiteIdField"]
        XCTAssertTrue(siteIdField.waitForExistence(timeout: 5))
        siteIdField.click()
        siteIdField.typeText("42")

        let siteNameField = app.textFields["UploadSiteNameField"]
        siteNameField.click()
        siteNameField.typeText("Engineering")

        // then
        let mainWindow = app.windows.firstMatch
        let screenshot = mainWindow.screenshot()
        assertSnapshot(of: screenshot.image, as: .image, named: "upload-sheet-site-fields-visible")
    }
}
