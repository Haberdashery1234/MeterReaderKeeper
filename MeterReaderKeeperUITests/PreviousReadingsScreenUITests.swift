//
//  PreviousReadingsScreenUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26.
//

import XCTest

/// Mirrors `Source/Screens/PreviousReadings/PreviousReadingsViewController.swift`.
final class PreviousReadingsScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Navigates Home -> "Previous Readings", with the fixed fixture
    /// already seeded (its readings are all historical, so they're visible
    /// immediately under the default "All" date filter).
    private func openPreviousReadings() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true)
        let app = launcher.app

        let previousReadingsButton = app.buttons["Previous Readings"]
        try requireUITest(previousReadingsButton.waitForExistence(timeout: 5), "Previous Readings button never appeared")
        previousReadingsButton.tap()

        try requireUITest(app.tables["PreviousReadings.tableView"].waitForExistence(timeout: 5), "PreviousReadings.tableView never appeared")
        return app
    }

    /// opening Previous Readings lists the seeded readings under the default "All" date filter
    func testOpensWithAllReadingsListed() throws {
        let app = try openPreviousReadings()
        let table = app.tables["PreviousReadings.tableView"]
        XCTAssertTrue(table.cells.firstMatch.waitForExistence(timeout: 5))
    }

    /// switching to the Building segment shows the building filter and hides the date filter
    func testBuildingSegmentShowsBuildingFilter() throws {
        let app = try openPreviousReadings()
        app.segmentedControls["PreviousReadings.segmentedControl"].buttons["Building"].tap()

        XCTAssertTrue(app.textFields["PreviousReadings.buildingTextField"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["PreviousReadings.dateTextField"].exists)
    }

    /// selecting a building in the Building filter updates the field to its name
    func testSelectingBuildingUpdatesFilterField() throws {
        let app = try openPreviousReadings()
        app.segmentedControls["PreviousReadings.segmentedControl"].buttons["Building"].tap()

        let buildingField = app.textFields["PreviousReadings.buildingTextField"]
        try requireUITest(buildingField.waitForExistence(timeout: 5), "PreviousReadings.buildingTextField never appeared")
        buildingField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "121 Seaport")

        XCTAssertEqual(buildingField.value as? String, "121 Seaport")
    }
}
