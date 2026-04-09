//
//  AppLaunchTests.swift
//  PPPC UtilityUITests
//
//  MIT License
//
//  Copyright (c) 2018 Jamf Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest

final class AppLaunchTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func testMainWindowAndTables() {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "Main window should exist after launch")
        XCTAssertTrue(window.isHittable, "Main window should be hittable")

        let executablesTable = app.tables["ExecutablesTable"]
        XCTAssertTrue(executablesTable.waitForExistence(timeout: 5), "Executables table should exist")

        let appleEventsTable = app.tables["AppleEventsTable"]
        XCTAssertTrue(appleEventsTable.waitForExistence(timeout: 5), "Apple Events table should exist")
    }

    func testToolbarButtons() {
        let saveButton = app.buttons["SaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button should exist")
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled with no executables")

        let uploadButton = app.buttons["UploadButton"]
        XCTAssertTrue(uploadButton.waitForExistence(timeout: 5), "Upload button should exist")
        XCTAssertFalse(uploadButton.isEnabled, "Upload button should be disabled with no executables")

        let addExecutableButton = app.buttons["AddExecutableButton"]
        XCTAssertTrue(addExecutableButton.waitForExistence(timeout: 5), "Add executable button should exist")
        XCTAssertTrue(addExecutableButton.isEnabled, "Add executable button should always be enabled")

        let removeExecutableButton = app.buttons["RemoveExecutableButton"]
        XCTAssertTrue(removeExecutableButton.waitForExistence(timeout: 5), "Remove executable button should exist")
        XCTAssertFalse(removeExecutableButton.isEnabled, "Remove executable button should be disabled with no selection")

        let addAppleEventButton = app.buttons["AddAppleEventButton"]
        XCTAssertTrue(addAppleEventButton.waitForExistence(timeout: 5), "Add Apple Event button should exist")
        XCTAssertFalse(addAppleEventButton.isEnabled, "Add Apple Event button should be disabled with no executable selected")

        let removeAppleEventButton = app.buttons["RemoveAppleEventButton"]
        XCTAssertTrue(removeAppleEventButton.waitForExistence(timeout: 5), "Remove Apple Event button should exist")
        XCTAssertFalse(removeAppleEventButton.isEnabled, "Remove Apple Event button should be disabled with no selection")
    }

    func testServicePopupsExistInExpectedOrder() {
        app.terminate()
        app.launchArguments = ["-UITestMode"]
        app.launch()

        let expectedPopUpOrder = [
            "AccessibilityPopUp",
            "AdminFilesPopUp",
            "AppBundlesPopUp",
            "AppDataPopUp",
            "BluetoothAlwaysPopUp",
            "CalendarPopUp",
            "CameraPopUp",
            "AddressBookPopUp",
            "DesktopFolderPopUp",
            "DocumentsFolderPopUp",
            "DownloadsFolderPopUp",
            "FileProviderPresencePopUp",
            "AllFilesPopUp",
            "ListenEventPopUp",
            "MediaLibraryPopUp",
            "MicrophonePopUp",
            "NetworkVolumesPopUp",
            "PhotosPopUp",
            "PostEventsPopUp",
            "RemindersPopUp",
            "RemovableVolumesPopUp",
            "ScreenCapturePopUp",
            "SpeechRecognitionPopUp"
        ]

        var previousY = -CGFloat.greatestFiniteMagnitude
        for identifier in expectedPopUpOrder {
            let popUp = app.popUpButtons[identifier]
            XCTAssertTrue(popUp.waitForExistence(timeout: 5), "\(identifier) should exist")
            let currentY = popUp.frame.origin.y
            XCTAssertGreaterThan(currentY, previousY, "\(identifier) should appear below the previous popup")
            previousY = currentY
        }
    }
}
