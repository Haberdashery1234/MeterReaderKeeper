//
//  AddEditMeterViewControllerUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26. Reorganized 9/1/26 into one UI test file per view
//  controller, mirroring the app target's own folder hierarchy under this
//  target. Converted 9/2/26 to a mixed shared/isolated launch strategy —
//  see "UI test performance: shared launches (2026-09-02)" in project
//  memory.
//

import XCTest

/// Mirrors `Source/Screens/Management/AddEditMeterViewController.swift`.
///
/// Three tests below (blank-name alert, no-delete-button-on-add, edit
/// form pre-populates name) never save or delete anything, so they share
/// one seeded launch. The other two (`testSavingNewMeterAddsItToList`,
/// `testDeletingMeterPopsBackToManagement`) do mutate the fixture, so
/// each keeps its own fresh, isolated launch exactly as before.
final class AddEditMeterViewControllerUITests: XCTestCase {

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
        let launcher = try UITestAppLauncher(seeded: true)
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
        let launcher = try UITestAppLauncher(seeded: true)
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

    // MARK: - Tests

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
