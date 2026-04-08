//
//  AppLaunchTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import XCTest

final class AppLaunchTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppLaunches() throws {
        // then
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window")
    }

    func testMainWindowExists() throws {
        // then
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.exists, "Main window should exist")
        XCTAssertTrue(mainWindow.isHittable, "Main window should be hittable")
    }

    func testExecutablesTableVisible() throws {
        // then
        let table = app.tables["ExecutablesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5), "Executables table should be visible")
    }

    func testAppleEventsTableVisible() throws {
        // then
        let table = app.tables["AppleEventsTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5), "Apple Events table should be visible")
    }

    func testSaveButtonPresent() throws {
        // then
        let button = app.buttons["SaveButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Save button should be present")
    }

    func testUploadButtonPresent() throws {
        // then
        let button = app.buttons["UploadButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Upload button should be present")
    }

    func testAddAppleEventButtonPresent() throws {
        // then
        let button = app.buttons["AddAppleEventButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Add Apple Event button should be present")
    }

    func testRemoveAppleEventButtonPresent() throws {
        // then
        let button = app.buttons["RemoveAppleEventButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Remove Apple Event button should be present")
    }

    func testRemoveExecutableButtonPresent() throws {
        // then
        let button = app.buttons["RemoveExecutableButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Remove executable button should be present")
    }
}
