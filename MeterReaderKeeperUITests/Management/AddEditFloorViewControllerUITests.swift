//
//  AddEditFloorViewControllerUITests.swift
//  MeterReaderKeeperUITests
//

import XCTest

/// Mirrors `Source/Screens/Management/AddEditFloorViewController.swift`.
///
/// There is no "Add Floor" entry point in the app — floors are created by
/// setting a building's floor count. This form is reached only via a
/// floor's Edit button, so these tests cover editing only.
///
/// `testClearingFloorNumberShowsAlert` and `testEditFormPrePopulatesBuilding`
/// don't save anything, so they share one seeded launch.
/// `testEditingFloorNumberUpdatesList` and
/// `testSavingWithoutTouchingBuildingPickerSucceeds` each save a
/// floor-number change, so both use their own fresh, isolated launch.
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

    /// Regression test for the "picker default row never fires
    /// didSelectRow" bug fixed in `AddEditFloorViewController` (see the
    /// doc comment on its `pickerView(_:didSelectRow:)`): this screen is
    /// reached only via editing an existing floor, so `selectedBuilding`
    /// is always populated at construction from the floor's own building
    /// and synced to the picker's highlighted row in `populateData()` —
    /// not by the user scrolling and triggering `didSelectRow`. Saving
    /// without ever touching the building picker must still succeed;
    /// before the fix, an equivalent scenario in `AddEditMeterViewController`
    /// left the model's selection out of sync with what the picker showed.
    func testSavingWithoutTouchingBuildingPickerSucceeds() throws {
        let app = try openFirstFloorIsolated()

        let floorField = app.textFields["AddEditFloor.floorTextField"]
        try requireUITest(floorField.waitForExistence(timeout: 5), "AddEditFloor.floorTextField never appeared")
        floorField.tap()
        floorField.clearAndTypeText("888")

        // Deliberately never taps buildingTextField or its picker.
        try UITestAppLauncher.dismissInputView(app, byTapping: "Building")
        app.navigationBars.buttons["AddEditFloor.saveButton"].tap()

        try requireUITest(
            app.navigationBars["Floor 888"].waitForExistence(timeout: 5),
            "Save failed without touching the building picker — selectedBuilding was likely lost"
        )
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
