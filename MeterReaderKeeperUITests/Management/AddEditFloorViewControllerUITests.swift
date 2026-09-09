//
//  AddEditFloorViewControllerUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26. Reorganized 9/1/26 into one UI test file per view
//  controller, mirroring the app target's own folder hierarchy under this
//  target. Converted 9/2/26 to a mixed shared/isolated launch strategy —
//  see "UI test performance: shared launches (2026-09-02)" in project
//  memory.
//
//  There is no "Add Floor" entry point anywhere in the app's UI — floors
//  are created only by setting a building's floor count (see
//  `AddEditBuildingViewControllerUITests`). Tapping a floor row on
//  Management opens the Floor Meters screen instead of this form directly
//  (2026-08-28) — this form is reached from there via its Edit button, so
//  these tests cover the edit flow exclusively, one tap further in than
//  before.
//

import XCTest

/// `testClearingFloorNumberShowsAlert` and `testEditFormPrePopulatesBuilding`
/// never save anything, so they share one seeded launch.
/// `testEditingFloorNumberUpdatesList` does save a floor-number change, so
/// it keeps its own fresh, isolated launch exactly as before.
final class AddEditFloorViewControllerUITests: XCTestCase {

    private static var sharedLauncher: UITestAppLauncher!

    override class func setUp() {
        super.setUp()
        sharedLauncher = try! UITestAppLauncher(seeded: true, fixtureName: UITestAppLauncher.minimalFixtureName)
    }

    override class func tearDown() {
        sharedLauncher = nil
        super.tearDown()
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Navigates Home -> Management -> Floors segment -> first floor row
    /// -> Floor Meters screen -> its Edit button on the class's shared
    /// seeded launch, resetting to Home first so tests stay
    /// order-independent.
    private func openFirstFloorShared() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
        try UITestAppLauncher.returnToHome(app)

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        let table = app.tables["Management.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.segmentedControls["Management.segmentedControl"].buttons["Floors"].tap()
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No floor rows appeared")
        table.cells.firstMatch.tap()

        let floorMetersTable = app.tables["FloorMeters.tableView"]
        try requireUITest(floorMetersTable.waitForExistence(timeout: 5), "FloorMeters.tableView never appeared")
        app.navigationBars.buttons["FloorMeters.editFloorButton"].tap()

        try requireUITest(app.navigationBars["Edit Floor"].waitForExistence(timeout: 5), "Edit Floor screen never appeared")
        return app
    }

    /// Same navigation as `openFirstFloorShared()`, but on a fresh,
    /// isolated seeded launch — for the test that saves a floor-number
    /// change.
    private func openFirstFloorIsolated() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true, fixtureName: UITestAppLauncher.minimalFixtureName)
        let app = launcher.app

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        let table = app.tables["Management.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.segmentedControls["Management.segmentedControl"].buttons["Floors"].tap()
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No floor rows appeared")
        table.cells.firstMatch.tap()

        let floorMetersTable = app.tables["FloorMeters.tableView"]
        try requireUITest(floorMetersTable.waitForExistence(timeout: 5), "FloorMeters.tableView never appeared")
        app.navigationBars.buttons["FloorMeters.editFloorButton"].tap()

        try requireUITest(app.navigationBars["Edit Floor"].waitForExistence(timeout: 5), "Edit Floor screen never appeared")
        return app
    }

    /// editing a floor's number and saving updates it, both on the Floor
    /// Meters screen it pops back to and on the Management list behind it
    func testEditingFloorNumberUpdatesList() throws {
        let app = try openFirstFloorIsolated()

        let floorField = app.textFields["AddEditFloor.floorTextField"]
        try requireUITest(floorField.waitForExistence(timeout: 5), "AddEditFloor.floorTextField never appeared")
        floorField.tap()
        floorField.clearAndTypeText("999")

        try UITestAppLauncher.dismissInputView(app, byTapping: "Building")
        app.navigationBars.buttons["AddEditFloor.saveButton"].tap()
        
        // Saving pops back one level, to Floor Meters — its title tracks
        // the floor's display name, so this confirms the save landed.
        try requireUITest(app.navigationBars["Floor 999"].waitForExistence(timeout: 5), "Floor Meters screen title didn't update to Floor 999")

        // Back out to Management and confirm its Floors list picked up
        // the change too.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let table = app.tables["Management.tableView"]
        let updatedRow = table.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Floor 999")
        ).firstMatch
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 5))
    }

    /// clearing the floor number and saving shows the Invalid Floor alert
    func testClearingFloorNumberShowsAlert() throws {
        let app = try openFirstFloorShared()

        let floorField = app.textFields["AddEditFloor.floorTextField"]
        try requireUITest(floorField.waitForExistence(timeout: 5), "AddEditFloor.floorTextField never appeared")
        floorField.tap()
        floorField.clearAndTypeText("")

        try UITestAppLauncher.dismissInputView(app, byTapping: "Building")
        app.navigationBars.buttons["AddEditFloor.saveButton"].tap()

        let alert = app.alerts["Invalid Floor"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }

    /// the building field is pre-populated (and shown) when editing an
    /// existing floor, since `AddEditFloorViewModel` is handed the floor's
    /// building at construction
    func testEditFormPrePopulatesBuilding() throws {
        let app = try openFirstFloorShared()

        let buildingField = app.textFields["AddEditFloor.buildingTextField"]
        try requireUITest(buildingField.waitForExistence(timeout: 5), "AddEditFloor.buildingTextField never appeared")
        XCTAssertNotEqual(buildingField.value as? String, "")
    }
}
