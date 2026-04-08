//
//  PolicySelectionTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest

final class PolicySelectionTests: XCTestCase {

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

    func testPolicyPopupsInitiallyShowDash() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // when — select the preloaded executable
        table.tableRows.firstMatch.click()

        // then — verify a subset of policy popups show "-"
        let policyIdentifiers = [
            "Policy.AddressBook",
            "Policy.Photos",
            "Policy.Calendar",
            "Policy.Accessibility",
            "Policy.SystemPolicyAllFiles"
        ]

        for identifier in policyIdentifiers {
            let popup = app.popUpButtons[identifier]
            XCTAssertTrue(popup.waitForExistence(timeout: 5), "\(identifier) popup should exist")

            let popupValue = popup.value as? String ?? ""
            XCTAssertEqual(popupValue, "-", "\(identifier) should initially show '-', got: '\(popupValue)'")
        }
    }

    func testChangePolicyPopupValue() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // when — select executable and change a policy
        table.tableRows.firstMatch.click()

        let addressBookPopup = app.popUpButtons["Policy.AddressBook"]
        XCTAssertTrue(addressBookPopup.waitForExistence(timeout: 5))

        addressBookPopup.click()
        let allowItem = addressBookPopup.menuItems["Allow"]
        if allowItem.waitForExistence(timeout: 3) {
            allowItem.click()
        }

        // then — verify value persists
        let updatedValue = addressBookPopup.value as? String ?? ""
        XCTAssertEqual(updatedValue, "Allow", "Address Book policy should now be 'Allow'")
    }

    func testPolicyValuePersistsAfterReselection() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // when — select executable and change a policy
        table.tableRows.firstMatch.click()

        let popup = app.popUpButtons["Policy.AddressBook"]
        XCTAssertTrue(popup.waitForExistence(timeout: 5))
        popup.click()

        let allowItem = popup.menuItems["Allow"]
        if allowItem.waitForExistence(timeout: 3) {
            allowItem.click()
        }

        // Deselect then reselect
        let mainWindow = app.windows.firstMatch
        mainWindow.click()
        table.tableRows.firstMatch.click()

        // then
        let reselectedValue = popup.value as? String ?? ""
        XCTAssertEqual(reselectedValue, "Allow", "Policy value should persist after reselection")
    }
}
