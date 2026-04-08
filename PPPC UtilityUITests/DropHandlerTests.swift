//
//  DropHandlerTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest

/// Tests the drop handler logic using -UITestMode preloaded data.
/// Since XCUITest cannot automate Finder drag-and-drop, the programmatic
/// drop hook in TCCProfileViewController is exercised indirectly by
/// verifying that executables added via -UITestMode appear correctly.
final class DropHandlerTests: XCTestCase {

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

    func testPreloadedExecutableHasCorrectIdentifier() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // when — select the preloaded executable
        let firstRow = table.tableRows.firstMatch
        firstRow.click()

        // then — verify identifier matches the preloaded Books app
        let identifierLabel = app.staticTexts["ExecutableIdentifierLabel"]
        XCTAssertTrue(identifierLabel.waitForExistence(timeout: 5))

        let identifierValue = identifierLabel.value as? String ?? ""
        XCTAssertTrue(
            identifierValue.contains("com.apple.iBooks"),
            "Identifier should contain the Books app bundle ID, got: \(identifierValue)"
        )
    }

    func testPreloadedExecutableRowExists() throws {
        // then
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(table.tableRows.count, 0, "Table should have the preloaded executable row")
    }
}
