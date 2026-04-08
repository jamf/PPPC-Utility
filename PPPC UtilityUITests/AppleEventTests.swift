//
//  AppleEventTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest

final class AppleEventTests: XCTestCase {

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

    func testAddAppleEventButtonOpensSheet() throws {
        let executablesTable = app.tables["ExecutablesTable"]
        XCTAssertTrue(executablesTable.waitForExistence(timeout: 5))

        // when — select an executable and click Add Apple Event
        executablesTable.tableRows.firstMatch.click()

        let addButton = app.buttons["AddAppleEventButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.click()

        // then — the Apple Event choices sheet should appear
        let choicesTable = app.tables["AppleEventChoicesTable"]
        XCTAssertTrue(choicesTable.waitForExistence(timeout: 10), "Apple Event choices table should appear")
    }

    func testSelectDestinationCreatesAppleEventRule() throws {
        let executablesTable = app.tables["ExecutablesTable"]
        XCTAssertTrue(executablesTable.waitForExistence(timeout: 5))

        // when — select executable, add Apple Event, pick a destination
        executablesTable.tableRows.firstMatch.click()

        let addButton = app.buttons["AddAppleEventButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.click()

        let choicesTable = app.tables["AppleEventChoicesTable"]
        XCTAssertTrue(choicesTable.waitForExistence(timeout: 10))

        // Select first choice (e.g. System Events)
        guard choicesTable.tableRows.count > 0 else {
            XCTFail("Choices table should have at least one row")
            return
        }
        choicesTable.tableRows.firstMatch.click()

        // then — Apple Events table should have a rule
        let appleEventsTable = app.tables["AppleEventsTable"]
        XCTAssertTrue(appleEventsTable.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(appleEventsTable.tableRows.count, 0, "Apple Events table should have at least one rule")
    }

    func testRemoveAppleEventRule() throws {
        let executablesTable = app.tables["ExecutablesTable"]
        XCTAssertTrue(executablesTable.waitForExistence(timeout: 5))

        // Setup — add an Apple Event rule first
        executablesTable.tableRows.firstMatch.click()

        let addButton = app.buttons["AddAppleEventButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.click()

        let choicesTable = app.tables["AppleEventChoicesTable"]
        XCTAssertTrue(choicesTable.waitForExistence(timeout: 10))

        guard choicesTable.tableRows.count > 0 else {
            XCTFail("Choices table should have at least one row")
            return
        }
        choicesTable.tableRows.firstMatch.click()

        let appleEventsTable = app.tables["AppleEventsTable"]
        XCTAssertTrue(appleEventsTable.waitForExistence(timeout: 5))

        let initialCount = appleEventsTable.tableRows.count
        guard initialCount > 0 else {
            XCTFail("Should have at least one Apple Event rule to remove")
            return
        }

        // when — select and remove the rule
        appleEventsTable.tableRows.firstMatch.click()

        let removeButton = app.buttons["RemoveAppleEventButton"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 5))
        removeButton.click()

        // then
        XCTAssertEqual(appleEventsTable.tableRows.count, initialCount - 1, "Apple Events count should decrease by one")
    }
}
