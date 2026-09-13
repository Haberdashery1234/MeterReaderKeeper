//
//  AddEditMeterViewControllerUITests.swift
//  MeterReaderKeeperUITests
//

import XCTest

/// Mirrors `Source/Screens/Management/AddEditMeterViewController.swift`.
///
/// The blank-name alert, no-delete-button-on-add, and edit-form
/// pre-population tests don't save or delete anything, so they share one
/// seeded launch. Saving a new meter (including the picker-regression
/// test below) and deleting a meter all mutate the fixture, so each of
/// those uses its own fresh, isolated launch.
final class AddEditMeterViewControllerUITests: XCTestCase {

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

    // MARK: - Shared launch (non-mutating tests only)

    /// Navigates Home -> Management -> "+" -> "Meter" on the class's
    /// shared seeded launch, resetting to Home first so tests stay
    /// order-independent.
    private func openAddMeterShared() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
        try UITestAppLauncher.returnToHome(app)

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.navigationBars.buttons["Management.addButton"].tap()
        let sheet = app.sheets["Add Item"]
        try requireUITest(sheet.waitForExistence(timeout: 5), "Add Item sheet never appeared")
        sheet.buttons["Meter"].tap()

        try requireUITest(app.navigationBars["Add Meter"].waitForExistence(timeout: 5), "Add Meter screen never appeared")
        return app
    }

    /// Navigates Home -> Management -> Meters segment -> first meter row
    /// on the class's shared seeded launch, resetting to Home first so
    /// tests stay order-independent.
    private func openEditMeterShared() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
        try UITestAppLauncher.returnToHome(app)

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        let table = app.tables["Management.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.segmentedControls["Management.segmentedControl"].buttons["Meters"].tap()
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No meter rows appeared")
        table.cells.firstMatch.tap()

        try requireUITest(app.navigationBars["Edit Meter"].waitForExistence(timeout: 5), "Edit Meter screen never appeared")
        return app
    }

    // MARK: - Isolated launch (mutating tests only)

    /// Navigates Home -> Management -> "+" -> "Meter" on a fresh, isolated
    /// seeded launch — for a test that saves a new meter.
    private func openAddMeterIsolated() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true, fixtureName: UITestAppLauncher.minimalFixtureName)
        let app = launcher.app

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.navigationBars.buttons["Management.addButton"].tap()
        let sheet = app.sheets["Add Item"]
        try requireUITest(sheet.waitForExistence(timeout: 5), "Add Item sheet never appeared")
        sheet.buttons["Meter"].tap()

        try requireUITest(app.navigationBars["Add Meter"].waitForExistence(timeout: 5), "Add Meter screen never appeared")
        return app
    }

    /// Navigates Home -> Management -> Meters segment -> first meter row
    /// on a fresh, isolated seeded launch — for a test that deletes an
    /// existing meter.
    private func openEditMeterIsolated() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true, fixtureName: UITestAppLauncher.minimalFixtureName)
        let app = launcher.app

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        let table = app.tables["Management.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.segmentedControls["Management.segmentedControl"].buttons["Meters"].tap()
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No meter rows appeared")
        table.cells.firstMatch.tap()

        try requireUITest(app.navigationBars["Edit Meter"].waitForExistence(timeout: 5), "Edit Meter screen never appeared")
        return app
    }

    /// Navigates Home -> Management -> Floors segment -> first floor row
    /// -> Floor Meters screen -> its Add button, on a fresh, isolated
    /// seeded launch. Unlike `openAddMeterIsolated()`'s Management "+"
    /// entry point (which supplies neither), this entry point pre-supplies
    /// both building and floor —
    /// `FloorMetersViewController.addMeterTapped()` calls
    /// `showMeterDetails(meter: nil, floor: viewModel.floor, building:
    /// viewModel.building)` — so it's the one that exercises the picker's
    /// pre-populated-selection path rather than a fresh manual pick.
    private func openAddMeterFromFloorMetersIsolated() throws -> XCUIApplication {
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
        app.navigationBars.buttons["FloorMeters.addButton"].tap()

        try requireUITest(app.navigationBars["Add Meter"].waitForExistence(timeout: 5), "Add Meter screen never appeared")
        return app
    }

    // MARK: - Tests

    /// Regression test for the "picker default row never fires
    /// didSelectRow" bug (see `AddEditMeterViewController`'s
    /// `pickerView(_:didSelectRow:)` doc comment): reached via
    /// `FloorMetersViewController`'s Add button, both the building and
    /// floor pickers already show a correct selection without any user
    /// interaction, because `selectedBuilding`/`selectedFloor` are set at
    /// construction and synced to each picker's highlighted row in
    /// `populateData()`. Saving with only a name typed in — never tapping
    /// either picker — must still succeed.
    func testSavingWithoutTouchingPickersSucceeds() throws {
        let app = try openAddMeterFromFloorMetersIsolated()

        let nameField = app.textFields["AddEditMeter.nameTextField"]
        try requireUITest(nameField.waitForExistence(timeout: 5), "AddEditMeter.nameTextField never appeared")
        nameField.tap()
        nameField.typeText("Sub Meter From Floor Meters")

        // Deliberately never taps buildingTextField, floorTextField, or
        // either picker.
        try UITestAppLauncher.dismissInputView(app, byTapping: "Building")
        app.navigationBars.buttons["AddEditMeter.saveButton"].tap()

        try requireUITest(
            app.tables["FloorMeters.tableView"].waitForExistence(timeout: 10),
            "Save failed without touching the pickers — selectedBuilding/selectedFloor was likely lost"
        )
        XCTAssertTrue(app.tables["FloorMeters.tableView"].staticTexts["Sub Meter From Floor Meters"].waitForExistence(timeout: 5))
    }

    /// saving a new meter with a building, floor, and name adds it to the list
    func testSavingNewMeterAddsItToList() throws {
        let app = try openAddMeterIsolated()

        let buildingField = app.textFields["AddEditMeter.buildingTextField"]
        try requireUITest(buildingField.waitForExistence(timeout: 5), "AddEditMeter.buildingTextField never appeared")
        buildingField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "121 Seaport")

        let floorField = app.textFields["AddEditMeter.floorTextField"]
        floorField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Floor 1")

        let nameField = app.textFields["AddEditMeter.nameTextField"]
        nameField.tap()
        nameField.typeText("Test Meter 999")

        try UITestAppLauncher.dismissInputView(app, byTapping: "Building")
        app.navigationBars.buttons["AddEditMeter.saveButton"].tap()

        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 10), "Management.tableView never reappeared after saving")
        app.segmentedControls["Management.segmentedControl"].buttons["Meters"].tap()
        XCTAssertTrue(app.tables["Management.tableView"].staticTexts["Test Meter 999"].waitForExistence(timeout: 5))
    }

    /// saving with a blank name shows the Missing Name alert
    func testSavingWithBlankNameShowsAlert() throws {
        let app = try openAddMeterShared()

        let buildingField = app.textFields["AddEditMeter.buildingTextField"]
        try requireUITest(buildingField.waitForExistence(timeout: 5), "AddEditMeter.buildingTextField never appeared")
        buildingField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "121 Seaport")

        let floorField = app.textFields["AddEditMeter.floorTextField"]
        floorField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Floor 1")

        try UITestAppLauncher.dismissInputView(app, byTapping: "Building")
        app.navigationBars.buttons["AddEditMeter.saveButton"].tap()

        let alert = app.alerts["Missing Name"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }

    /// a new (never-edited) meter doesn't show a Delete button
    func testAddFormHasNoDeleteButton() throws {
        let app = try openAddMeterShared()
        XCTAssertFalse(app.buttons["AddEditMeter.deleteButton"].exists)
    }

    /// editing an existing meter pre-populates its name field
    func testEditFormPrePopulatesName() throws {
        let app = try openEditMeterShared()

        let nameField = app.textFields["AddEditMeter.nameTextField"]
        try requireUITest(nameField.waitForExistence(timeout: 5), "AddEditMeter.nameTextField never appeared")
        XCTAssertNotEqual(nameField.value as? String, "")
    }

    /// Delete Meter on an existing meter, confirmed, pops back to Management
    func testDeletingMeterPopsBackToManagement() throws {
        let app = try openEditMeterIsolated()

        app.buttons["AddEditMeter.deleteButton"].tap()
        let alert = app.alerts["Delete Meter"]
        try requireUITest(alert.waitForExistence(timeout: 5), "Delete Meter confirmation never appeared")
        alert.buttons["Delete"].tap()

        XCTAssertTrue(app.tables["Management.tableView"].waitForExistence(timeout: 5))
    }
}
