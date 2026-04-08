//
//  SaveSheetTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest

final class SaveSheetTests: XCTestCase {

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

    func testSaveSheetFieldsPresent() throws {
        // when — trigger save sheet
        let saveButton = app.buttons["SaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.click()

        // then — verify fields are present
        let payloadNameField = app.textFields["SavePayloadNameField"]
        XCTAssertTrue(payloadNameField.waitForExistence(timeout: 5), "Payload name field should be present")

        let organizationField = app.textFields["SaveOrganizationField"]
        XCTAssertTrue(organizationField.waitForExistence(timeout: 5), "Organization field should be present")

        let identityPopUp = app.popUpButtons["SaveSigningIdentityPopUp"]
        XCTAssertTrue(identityPopUp.waitForExistence(timeout: 5), "Signing identity popup should be present")

        let sheetSaveButton = app.buttons["SaveSheetSaveButton"]
        XCTAssertTrue(sheetSaveButton.waitForExistence(timeout: 5), "Save button should be present")
    }

    func testSaveButtonDisabledWhenFieldsEmpty() throws {
        // when — trigger save sheet
        let saveButton = app.buttons["SaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.click()

        // then — save should be disabled when required fields are empty
        let sheetSaveButton = app.buttons["SaveSheetSaveButton"]
        XCTAssertTrue(sheetSaveButton.waitForExistence(timeout: 5))

        // Clear any existing values
        let payloadNameField = app.textFields["SavePayloadNameField"]
        if payloadNameField.waitForExistence(timeout: 5) {
            payloadNameField.click()
            payloadNameField.typeKey("a", modifierFlags: .command)
            payloadNameField.typeText("")
        }

        XCTAssertFalse(sheetSaveButton.isEnabled, "Save button should be disabled when fields are empty")
    }

    func testSaveButtonEnabledWhenFieldsFilled() throws {
        // when — trigger save sheet
        let saveButton = app.buttons["SaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.click()

        // Fill required fields
        let payloadNameField = app.textFields["SavePayloadNameField"]
        XCTAssertTrue(payloadNameField.waitForExistence(timeout: 5))
        payloadNameField.click()
        payloadNameField.typeText("Test Profile Name")

        let organizationField = app.textFields["SaveOrganizationField"]
        XCTAssertTrue(organizationField.waitForExistence(timeout: 5))
        organizationField.click()
        organizationField.typeText("Test Organization")

        // then
        let sheetSaveButton = app.buttons["SaveSheetSaveButton"]
        XCTAssertTrue(sheetSaveButton.waitForExistence(timeout: 5))
        XCTAssertTrue(sheetSaveButton.isEnabled, "Save button should be enabled when required fields are filled")
    }
}
