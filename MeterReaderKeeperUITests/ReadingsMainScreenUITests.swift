//
//  ReadingsMainScreenUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26.
//

import XCTest

/// Mirrors `Source/Screens/ReadingsFlow/ReadingsMainViewController.swift`.
final class ReadingsMainScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Navigates Home -> "Take Readings" -> "121 Seaport". The seeded
    /// fixture has 4 buildings, so "Take Readings" always presents a
    /// "Select Building" action sheet rather than jumping straight in.
    private func openReadings() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true)
        let app = launcher.app

        let takeReadingsButton = app.buttons["Take Readings"]
        try requireUITest(takeReadingsButton.waitForExistence(timeout: 5), "Take Readings button never appeared")
        takeReadingsButton.tap()

        let sheet = app.sheets["Select Building"]
        try requireUITest(sheet.waitForExistence(timeout: 5), "Select Building sheet never appeared")
        sheet.buttons["121 Seaport"].tap()

        try requireUITest(app.tables["ReadingsMain.tableView"].waitForExistence(timeout: 5), "ReadingsMain.tableView never appeared")
        return app
    }

    /// opening Readings for a building shows a floor selection and its meters
    func testOpensWithFloorAndMeters() throws {
        let app = try openReadings()

        let floorField = app.textFields["ReadingsMain.floorTextField"]
        XCTAssertTrue(floorField.waitForExistence(timeout: 5))
        XCTAssertTrue((floorField.value as? String)?.hasPrefix("Floor ") == true)

        let table = app.tables["ReadingsMain.tableView"]
        XCTAssertTrue(table.cells.firstMatch.waitForExistence(timeout: 5))
    }

    /// tapping a meter with no reading today opens Add Reading
    func testTappingMeterOpensAddReading() throws {
        let app = try openReadings()
        let table = app.tables["ReadingsMain.tableView"]
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No meter rows appeared")
        table.cells.firstMatch.tap()

        // Every seeded reading is historical, so the first meter on the
        // default floor always routes to "Add Reading" rather than "Edit".
        XCTAssertTrue(app.navigationBars["Add Reading"].waitForExistence(timeout: 5))
    }

    /// scan button shows the QR Scanner placeholder alert
    func testScanButtonShowsPlaceholderAlert() throws {
        let app = try openReadings()
        app.navigationBars.buttons["ReadingsMain.scanButton"].tap()

        let alert = app.alerts["QR Scanner"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }
}
