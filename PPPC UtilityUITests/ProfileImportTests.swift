//
//  ProfileImportTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest

/// Tests profile import via the -UITestMode preloaded profile.
/// Since NSOpenPanel cannot be automated by XCUITest, these tests
/// verify the state after the app loads with preloaded data.
final class ProfileImportTests: XCTestCase {

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

    func testExecutablesTablePopulatedAfterImport() throws {
        // then
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(table.tableRows.count, 0, "Executables table should be populated")
    }

    func testImportedExecutableShowsCorrectName() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // when
        table.tableRows.firstMatch.click()

        // then
        let nameLabel = app.staticTexts["ExecutableNameLabel"]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5))

        let name = nameLabel.value as? String ?? ""
        XCTAssertFalse(name.isEmpty, "Executable name should not be empty")
    }

    func testImportedExecutableShowsIdentifier() throws {
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        // when
        table.tableRows.firstMatch.click()

        // then
        let identifierLabel = app.staticTexts["ExecutableIdentifierLabel"]
        XCTAssertTrue(identifierLabel.waitForExistence(timeout: 5))

        let identifier = identifierLabel.value as? String ?? ""
        XCTAssertFalse(identifier.isEmpty, "Executable identifier should not be empty")
    }
}
