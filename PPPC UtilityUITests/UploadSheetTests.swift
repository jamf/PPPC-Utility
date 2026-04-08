//
//  UploadSheetTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest

final class UploadSheetTests: XCTestCase {

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

    func testUploadSheetFieldsPresent() throws {
        // when
        openUploadSheet()

        // then
        let serverField = app.textFields["UploadServerURLField"]
        XCTAssertTrue(serverField.waitForExistence(timeout: 5), "Server URL field should be present")

        let usernameField = app.textFields["UploadUsernameField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5), "Username field should be present")

        let orgField = app.textFields["UploadOrganizationField"]
        XCTAssertTrue(orgField.waitForExistence(timeout: 5), "Organization field should be present")

        let payloadNameField = app.textFields["UploadPayloadNameField"]
        XCTAssertTrue(payloadNameField.waitForExistence(timeout: 5), "Payload name field should be present")

        let cancelButton = app.buttons["UploadCancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Cancel button should be present")

        let actionButton = app.buttons["UploadActionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5), "Action button should be present")
    }

    func testActionButtonDisabledWithEmptyURL() throws {
        // when
        openUploadSheet()

        let serverField = app.textFields["UploadServerURLField"]
        XCTAssertTrue(serverField.waitForExistence(timeout: 5))

        // Clear the server field
        serverField.click()
        serverField.typeKey("a", modifierFlags: .command)
        serverField.typeText("")

        // then
        let actionButton = app.buttons["UploadActionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
        XCTAssertFalse(actionButton.isEnabled, "Action button should be disabled with empty URL")
    }

    func testActionButtonEnabledWithURLAndCredentials() throws {
        // when
        openUploadSheet()

        let serverField = app.textFields["UploadServerURLField"]
        XCTAssertTrue(serverField.waitForExistence(timeout: 5))
        serverField.click()
        serverField.typeKey("a", modifierFlags: .command)
        serverField.typeText("https://example.jamfcloud.com")

        let usernameField = app.textFields["UploadUsernameField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5))
        usernameField.click()
        usernameField.typeText("testuser")

        let passwordField = app.secureTextFields["UploadPasswordField"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.click()
        passwordField.typeText("testpassword")

        // then
        let actionButton = app.buttons["UploadActionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
        XCTAssertTrue(actionButton.isEnabled, "Action button should be enabled with URL and credentials")
    }

    func testAuthTypePickerSwitchesFields() throws {
        // when
        openUploadSheet()

        let authPicker = app.popUpButtons["UploadAuthTypePicker"]
        XCTAssertTrue(authPicker.waitForExistence(timeout: 5))

        // Switch to Basic Auth
        authPicker.click()
        let basicAuth = authPicker.menuItems["Basic/Bearer Auth"]
        if basicAuth.waitForExistence(timeout: 3) {
            basicAuth.click()
        }

        // then
        let usernameField = app.textFields["UploadUsernameField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5), "Username field should be present for Basic Auth")
    }

    func testUseSiteToggleShowsSiteFields() throws {
        // when
        openUploadSheet()

        let siteToggle = app.checkBoxes["UploadUseSiteToggle"]
        XCTAssertTrue(siteToggle.waitForExistence(timeout: 5))

        // Enable "Use Site"
        if siteToggle.value as? Int != 1 {
            siteToggle.click()
        }

        // then
        let siteIdField = app.textFields["UploadSiteIdField"]
        XCTAssertTrue(siteIdField.waitForExistence(timeout: 5))
        XCTAssertTrue(siteIdField.isEnabled, "Site ID field should be enabled when Use Site is on")

        let siteNameField = app.textFields["UploadSiteNameField"]
        XCTAssertTrue(siteNameField.waitForExistence(timeout: 5))
        XCTAssertTrue(siteNameField.isEnabled, "Site Name field should be enabled when Use Site is on")
    }

    func testUseSiteToggleHidesSiteFields() throws {
        // when
        openUploadSheet()

        let siteToggle = app.checkBoxes["UploadUseSiteToggle"]
        XCTAssertTrue(siteToggle.waitForExistence(timeout: 5))

        // Ensure "Use Site" is off
        if siteToggle.value as? Int == 1 {
            siteToggle.click()
        }

        // then
        let siteIdField = app.textFields["UploadSiteIdField"]
        XCTAssertTrue(siteIdField.waitForExistence(timeout: 5))
        XCTAssertFalse(siteIdField.isEnabled, "Site ID field should be disabled when Use Site is off")

        let siteNameField = app.textFields["UploadSiteNameField"]
        XCTAssertTrue(siteNameField.waitForExistence(timeout: 5))
        XCTAssertFalse(siteNameField.isEnabled, "Site Name field should be disabled when Use Site is off")
    }

    func testCancelDismissesSheet() throws {
        // when
        openUploadSheet()

        let cancelButton = app.buttons["UploadCancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.click()

        // then — the upload fields should no longer be visible
        let serverField = app.textFields["UploadServerURLField"]
        XCTAssertFalse(serverField.waitForExistence(timeout: 3), "Upload sheet should be dismissed")
    }
}
