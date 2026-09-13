//
//  MeterHistoryViewControllerUITests.swift
//  MeterReaderKeeperUITests
//

import XCTest

/// Mirrors `Source/Screens/MeterHistory/MeterHistoryViewController.swift`.
///
/// Both tests below only navigate and read — neither mutates the seeded
/// fixture — so the class shares one ~20s seeded launch instead of each
/// test paying it independently.
final class MeterHistoryViewControllerUITests: XCTestCase {

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

    /// Navigates Home -> "Previous Readings" -> first reading row on the
    /// class's shared seeded launch.
    private func openMeterHistory() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
        let previousReadingsButton = app.buttons["Previous Readings"]
        try requireUITest(previousReadingsButton.waitForExistence(timeout: 5), "Previous Readings button never appeared")
        previousReadingsButton.tap()

        let table = app.tables["PreviousReadings.tableView"]
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No reading rows appeared")
        table.cells.firstMatch.tap()

        try requireUITest(app.staticTexts["MeterHistory.buildingValueLabel"].waitForExistence(timeout: 5), "MeterHistory.buildingValueLabel never appeared")
        return app
    }

    /// opening a meter's history shows its building, floor, and latest
    /// reading value — none left at the placeholder em dash
    func testOpeningShowsBuildingFloorAndLatestReading() throws {
        let app = try openMeterHistory()

        let buildingValue = app.staticTexts["MeterHistory.buildingValueLabel"]
        let floorValue = app.staticTexts["MeterHistory.floorValueLabel"]
        let latestReadingValue = app.staticTexts["MeterHistory.latestReadingValueLabel"]

        XCTAssertNotEqual(buildingValue.label, "")
        XCTAssertNotEqual(buildingValue.label, "\u{2013}")
        XCTAssertTrue(floorValue.label.hasPrefix("Floor "))
        XCTAssertNotEqual(latestReadingValue.label, "\u{2013}")
    }

    /// a seeded meter (multiple historical readings, per `SeedFixture.json`)
    /// has enough history to plot usage, so the "no readings" empty-state
    /// label stays hidden
    func testSeededMeterHidesEmptyState() throws {
        let app = try openMeterHistory()

        // waitForExistence first, so a slow first layout pass doesn't read
        // as "hidden" before the label's had a chance to update at all.
        _ = app.staticTexts["MeterHistory.latestReadingValueLabel"].waitForExistence(timeout: 5)
        XCTAssertFalse(app.staticTexts["MeterHistory.noReadingsLabel"].exists)
    }
}
