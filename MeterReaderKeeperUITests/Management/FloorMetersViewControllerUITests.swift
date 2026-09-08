//
//  FloorMetersViewControllerUITests.swift
//  MeterReaderKeeperUITests
//
//  Created 9/1/26 — this screen (added 8/28/26) had no UI test coverage
//  yet. One file per view controller, mirroring the app target's own
//  folder hierarchy under this target. Converted 9/2/26 to a mixed
//  shared/isolated launch strategy — see "UI test performance: shared
//  launches (2026-09-02)" in project memory.
//

import XCTest

/// Mirrors `Source/Screens/Management/FloorMetersViewController.swift`.
///
/// Four tests below (table shows, add button pre-selects floor, edit
/// button opens Edit Floor, tapping a meter row opens Edit Meter) never
/// mutate the fixture, so they share one seeded launch.
/// `testSwipeToDeleteMeterRemovesItFromList` deletes a meter, so it keeps
/// its own fresh, isolated launch exactly as before.
final class FloorMetersViewControllerUITests: XCTestCase {

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
    }

    /// Navigates Home -> Management -> Floors segment -> first floor row
    /// on the class's shared seeded launch, resetting to Home first so
    /// tests stay order-independent.
    private func openFirstFloorShared() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
        try UITestAppLauncher.returnToHome(app)

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        let managementTable = app.tables["Management.tableView"]
        try requireUITest(managementTable.waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.segmentedControls["Management.segmentedControl"].buttons["Floors"].tap()
        try requireUITest(managementTable.cells.firstMatch.waitForExistence(timeout: 5), "No floor rows appeared")
        managementTable.cells.firstMatch.tap()

        try requireUITest(app.tables["FloorMeters.tableView"].waitForExistence(timeout: 5), "FloorMeters.tableView never appeared")
        return app
    }

    /// Navigates Home -> Management -> Floors segment -> first floor row
    /// on a fresh, isolated seeded launch — for the test that deletes a
    /// meter from the list.
    private func openFirstFloorIsolated() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true)
        let app = launcher.app

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        let managementTable = app.tables["Management.tableView"]
        try requireUITest(managementTable.waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.segmentedControls["Management.segmentedControl"].buttons["Floors"].tap()
        try requireUITest(managementTable.cells.firstMatch.waitForExistence(timeout: 5), "No floor rows appeared")
        managementTable.cells.firstMatch.tap()

        try requireUITest(app.tables["FloorMeters.tableView"].waitForExistence(timeout: 5), "FloorMeters.tableView never appeared")
        return app
    }

    /// opening a floor with meters shows its table, not the empty-state label
    func testOpeningFloorWithMetersShowsTable() throws {
        let app = try openFirstFloorShared()
        let table = app.tables["FloorMeters.tableView"]

        XCTAssertTrue(table.cells.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["FloorMeters.emptyStateLabel"].exists)
    }

    /// the Add button opens Add Meter with this floor already selected
    func testAddButtonOpensAddMeterWithFloorPreSelected() throws {
        let app = try openFirstFloorShared()
        app.navigationBars.buttons["FloorMeters.addButton"].tap()

        try requireUITest(app.navigationBars["Add Meter"].waitForExistence(timeout: 5), "Add Meter screen never appeared")
        let buildingField = app.textFields["AddEditMeter.buildingTextField"]
        let floorField = app.textFields["AddEditMeter.floorTextField"]
        try requireUITest(buildingField.waitForExistence(timeout: 5), "AddEditMeter.buildingTextField never appeared")
        XCTAssertNotEqual(buildingField.value as? String, "")
        XCTAssertNotEqual(floorField.value as? String, "")
    }

    /// the Edit (pencil) button opens the floor's own number/map-image form
    func testEditFloorButtonOpensEditFloor() throws {
        let app = try openFirstFloorShared()
        app.navigationBars.buttons["FloorMeters.editFloorButton"].tap()

        XCTAssertTrue(app.navigationBars["Edit Floor"].waitForExistence(timeout: 5))
    }

    /// tapping a meter row opens Edit Meter with its name populated
    func testTappingMeterRowOpensEditMeter() throws {
        let app = try openFirstFloorShared()
        let table = app.tables["FloorMeters.tableView"]
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No meter rows appeared")
        table.cells.firstMatch.tap()

        try requireUITest(app.navigationBars["Edit Meter"].waitForExistence(timeout: 5), "Edit Meter screen never appeared")
        let nameField = app.textFields["AddEditMeter.nameTextField"]
        try requireUITest(nameField.waitForExistence(timeout: 5), "AddEditMeter.nameTextField never appeared")
        XCTAssertNotEqual(nameField.value as? String, "")
    }

    /// swiping a meter row to delete shows the confirmation alert, and
    /// confirming removes it from the list
    func testSwipeToDeleteMeterRemovesItFromList() throws {
        let app = try openFirstFloorIsolated()
        let table = app.tables["FloorMeters.tableView"]
        let firstCell = table.cells.firstMatch
        try requireUITest(firstCell.waitForExistence(timeout: 5), "No meter rows appeared")
        let meterName = firstCell.staticTexts.firstMatch.label

        firstCell.swipeLeft()
        let deleteButton = table.buttons["Delete"]
        try requireUITest(deleteButton.waitForExistence(timeout: 5), "Swipe-to-delete Delete button never appeared")
        deleteButton.tap()

        let alert = app.alerts["Delete Meter"]
        try requireUITest(alert.waitForExistence(timeout: 5), "Delete Meter confirmation never appeared")
        alert.buttons["Delete"].tap()

        XCTAssertFalse(table.staticTexts[meterName].waitForExistence(timeout: 3))
    }
}
