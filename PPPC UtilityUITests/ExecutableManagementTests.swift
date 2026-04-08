//
//  ExecutableManagementTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest

final class ExecutableManagementTests: XCTestCase {

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

    func testPreloadedExecutableAppearsInTable() throws {
        // then
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        let cells = table.tableRows
        XCTAssertGreaterThan(cells.count, 0, "Table should have at least one row from preloaded executable")
    }

    func testSelectExecutablePopulatesDetailLabels() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // when
        let firstRow = table.tableRows.firstMatch
        firstRow.click()

        // then
        let nameLabel = app.staticTexts["ExecutableNameLabel"]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5), "Name label should be visible")

        let identifierLabel = app.staticTexts["ExecutableIdentifierLabel"]
        XCTAssertTrue(identifierLabel.waitForExistence(timeout: 5), "Identifier label should be visible")
    }

    func testRemoveExecutableRemovesRow() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        let initialRowCount = table.tableRows.count
        guard initialRowCount > 0 else {
            XCTFail("Need at least one row to test removal")
            return
        }

        // when
        let firstRow = table.tableRows.firstMatch
        firstRow.click()

        let removeButton = app.buttons["RemoveExecutableButton"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 5))
        removeButton.click()

        // then
        XCTAssertEqual(table.tableRows.count, initialRowCount - 1, "Row count should decrease by one")
    }
}
