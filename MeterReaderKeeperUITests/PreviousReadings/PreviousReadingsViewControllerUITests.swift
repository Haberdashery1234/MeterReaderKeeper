//
//  PreviousReadingsViewControllerUITests.swift
//  MeterReaderKeeperUITests
//

import XCTest

/// Mirrors `Source/Screens/PreviousReadings/PreviousReadingsViewController.swift`.
///
/// Every test below only navigates, filters, and reads — none of them
/// mutate the seeded fixture — so the whole class shares one ~20s seeded
/// launch instead of each test paying it independently.
final class PreviousReadingsViewControllerUITests: XCTestCase {

    private static var sharedLauncher: UITestAppLauncher!

    override class func setUp() {
        super.setUp()
        sharedLauncher = try! UITestAppLauncher(seeded: true)
    }

    override class func tearDown() {
        sharedLauncher = nil
        super.tearDown()
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try UITestAppLauncher.returnToHome(Self.sharedLauncher.app)
    }

    /// Navigates Home -> "Previous Readings" on the class's shared seeded
    /// launch (its readings are all historical, so they're visible
    /// immediately under the default "All" date filter).
    private func openPreviousReadings() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
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

    /// tapping a meter row opens that meter's Meter History screen
    func testTappingMeterRowOpensMeterHistory() throws {
        let app = try openPreviousReadings()
        let table = app.tables["PreviousReadings.tableView"]
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No reading rows appeared")
        table.cells.firstMatch.tap()

        XCTAssertTrue(app.staticTexts["MeterHistory.buildingValueLabel"].waitForExistence(timeout: 5))
    }
}
