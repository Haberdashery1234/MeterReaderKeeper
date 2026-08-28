//
//  AddEditReadingScreenUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26.
//

import XCTest

/// Mirrors `Source/Screens/ReadingsFlow/AddEditReadingViewController.swift`.
final class AddEditReadingScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Navigates Home -> Take Readings -> "121 Seaport" -> first meter row,
    /// with the fixed fixture already seeded. Every seeded reading is
    /// historical, so the first meter on the default floor always routes
    /// to "Add Reading".
    private func openAddReading() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true)
        let app = launcher.app

        let takeReadingsButton = app.buttons["Take Readings"]
        try requireUITest(takeReadingsButton.waitForExistence(timeout: 5), "Take Readings button never appeared")
        takeReadingsButton.tap()

        let sheet = app.sheets["Select Building"]
        try requireUITest(sheet.waitForExistence(timeout: 5), "Select Building sheet never appeared")
        sheet.buttons["121 Seaport"].tap()

        let table = app.tables["ReadingsMain.tableView"]
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No meter rows appeared")
        table.cells.firstMatch.tap()

        try requireUITest(app.navigationBars["Add Reading"].waitForExistence(timeout: 5), "Add Reading screen never appeared")
        return app
    }

    /// saving a valid reading returns to the meters list
    func testSavingValidReadingReturnsToList() throws {
        let app = try openAddReading()

        let readingField = app.textFields["AddEditReading.readingTextField"]
        try requireUITest(readingField.waitForExistence(timeout: 5), "AddEditReading.readingTextField never appeared")
        readingField.tap()
        readingField.typeText("123.45")

        app.buttons["AddEditReading.saveButton"].tap()

        XCTAssertTrue(app.tables["ReadingsMain.tableView"].waitForExistence(timeout: 5))
    }

    /// saving a blank reading shows the Missing Reading alert
    func testSavingBlankReadingShowsAlert() throws {
        let app = try openAddReading()

        try requireUITest(app.textFields["AddEditReading.readingTextField"].waitForExistence(timeout: 5), "AddEditReading.readingTextField never appeared")
        app.buttons["AddEditReading.saveButton"].tap()

        let alert = app.alerts["Missing Reading"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }
}
