//
//  AddEditBuildingViewControllerUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26. Reorganized 9/1/26 into one UI test file per view
//  controller, mirroring the app target's own folder hierarchy under this
//  target. Converted 9/2/26 to a mixed shared/isolated launch strategy —
//  see "UI test performance: shared launches (2026-09-02)" in project
//  memory.
//

import XCTest

/// Mirrors `Source/Screens/Management/AddEditBuildingViewController.swift`.
///
/// Three tests below (blank-name alert, no-delete-button-on-add,
/// renaming-unsupported alert) never save or delete anything, so they
/// share one seeded launch. The other three
/// (`testSavingNewBuildingAddsItToList`, `testEditingFloorCountOnlySaves`,
/// `testDeletingBuildingRemovesItFromList`) do mutate the fixture — in
/// particular, `testDeletingBuildingRemovesItFromList` deletes "121
/// Seaport", which several *other* files' tests also depend on existing
/// — so each of those three keeps its own fresh, isolated launch exactly
/// as before.
final class AddEditBuildingViewControllerUITests: XCTestCase {

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

    /// Navigates Home -> Management -> "+" -> "Building" on the class's
    /// shared seeded launch, resetting to Home first so tests stay
    /// order-independent.
    private func openAddBuildingShared() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
        try UITestAppLauncher.returnToHome(app)

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.navigationBars.buttons["Management.addButton"].tap()
        let sheet = app.sheets["Add Item"]
        try requireUITest(sheet.waitForExistence(timeout: 5), "Add Item sheet never appeared")
        sheet.buttons["Building"].tap()

        try requireUITest(app.navigationBars["Add Building"].waitForExistence(timeout: 5), "Add Building screen never appeared")
        return app
    }

    /// Navigates Home -> Management -> "121 Seaport" row on the class's
    /// shared seeded launch, resetting to Home first so tests stay
    /// order-independent.
    private func openEditBuildingShared() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
        try UITestAppLauncher.returnToHome(app)

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        let table = app.tables["Management.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "Management.tableView never appeared")

        let row = table.staticTexts["121 Seaport"]
        try requireUITest(row.waitForExistence(timeout: 5), "121 Seaport row never appeared")
        row.tap()

        try requireUITest(app.navigationBars["Edit Building"].waitForExistence(timeout: 5), "Edit Building screen never appeared")
        return app
    }

    // MARK: - Isolated launch (mutating tests only)

    /// Navigates Home -> Management -> "+" -> "Building" on a fresh,
    /// isolated seeded launch — for a test that saves a new building.
    private func openAddBuildingIsolated() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true, fixtureName: UITestAppLauncher.minimalFixtureName)
        let app = launcher.app

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.navigationBars.buttons["Management.addButton"].tap()
        let sheet = app.sheets["Add Item"]
        try requireUITest(sheet.waitForExistence(timeout: 5), "Add Item sheet never appeared")
        sheet.buttons["Building"].tap()

        try requireUITest(app.navigationBars["Add Building"].waitForExistence(timeout: 5), "Add Building screen never appeared")
        return app
    }

    /// Navigates Home -> Management -> "121 Seaport" row on a fresh,
    /// isolated seeded launch — for a test that edits or deletes an
    /// existing building.
    private func openEditBuildingIsolated() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true, fixtureName: UITestAppLauncher.minimalFixtureName)
        let app = launcher.app

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        let table = app.tables["Management.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "Management.tableView never appeared")

        let row = table.staticTexts["121 Seaport"]
        try requireUITest(row.waitForExistence(timeout: 5), "121 Seaport row never appeared")
        row.tap()

        try requireUITest(app.navigationBars["Edit Building"].waitForExistence(timeout: 5), "Edit Building screen never appeared")
        return app
    }

    // MARK: - Tests

    /// saving a new building with a name and floor count adds it to the list
    func testSavingNewBuildingAddsItToList() throws {
        let app = try openAddBuildingIsolated()

        let nameField = app.textFields["AddEditBuilding.nameTextField"]
        try requireUITest(nameField.waitForExistence(timeout: 5), "AddEditBuilding.nameTextField never appeared")
        nameField.tap()
        nameField.typeText("999 Test Ave")

        let floorsField = app.textFields["AddEditBuilding.floorsTextField"]
        floorsField.tap()
        floorsField.typeText("5")

        app.navigationBars.buttons["AddEditBuilding.saveButton"].tap()

        let table = app.tables["Management.tableView"]
        XCTAssertTrue(table.staticTexts["999 Test Ave"].waitForExistence(timeout: 5))
    }

    /// saving with a blank name shows the Invalid Name alert
    func testSavingWithBlankNameShowsAlert() throws {
        let app = try openAddBuildingShared()

        let floorsField = app.textFields["AddEditBuilding.floorsTextField"]
        try requireUITest(floorsField.waitForExistence(timeout: 5), "AddEditBuilding.floorsTextField never appeared")
        floorsField.tap()
        floorsField.typeText("5")

        app.navigationBars.buttons["AddEditBuilding.saveButton"].tap()

        let alert = app.alerts["Invalid Name"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }

    /// a new (never-edited) building doesn't show a Delete button — there's
    /// nothing to delete yet
    func testAddFormHasNoDeleteButton() throws {
        let app = try openAddBuildingShared()
        XCTAssertFalse(app.buttons["AddEditBuilding.deleteButton"].exists)
    }

    /// editing an existing building's floor count (without changing its
    /// name) saves without the "Renaming Not Supported" error and pops
    /// back to Management
    func testEditingFloorCountOnlySaves() throws {
        let app = try openEditBuildingIsolated()

        let floorsField = app.textFields["AddEditBuilding.floorsTextField"]
        try requireUITest(floorsField.waitForExistence(timeout: 5), "AddEditBuilding.floorsTextField never appeared")
        XCTAssertTrue(floorsField.isEnabled, "floor count should be editable on an existing building")

        app.navigationBars.buttons["AddEditBuilding.saveButton"].tap()

        XCTAssertTrue(app.tables["Management.tableView"].waitForExistence(timeout: 5))
    }

    /// changing an existing building's name shows the "Renaming Not
    /// Supported" alert instead of saving
    func testRenamingExistingBuildingShowsUnsupportedAlert() throws {
        let app = try openEditBuildingShared()

        let nameField = app.textFields["AddEditBuilding.nameTextField"]
        try requireUITest(nameField.waitForExistence(timeout: 5), "AddEditBuilding.nameTextField never appeared")
        nameField.tap()
        nameField.clearAndTypeText("121 Seaport Renamed")

        app.navigationBars.buttons["AddEditBuilding.saveButton"].tap()

        XCTAssertTrue(app.alerts["Renaming Not Supported"].waitForExistence(timeout: 5))
    }

    /// Delete Building on an existing building, confirmed, removes it from
    /// the Management list
    func testDeletingBuildingRemovesItFromList() throws {
        let app = try openEditBuildingIsolated()

        app.buttons["AddEditBuilding.deleteButton"].tap()
        let alert = app.alerts["Delete Building"]
        try requireUITest(alert.waitForExistence(timeout: 5), "Delete Building confirmation never appeared")
        alert.buttons["Delete"].tap()

        let table = app.tables["Management.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "Management.tableView never reappeared after delete")
        XCTAssertFalse(table.staticTexts["121 Seaport"].waitForExistence(timeout: 3))
    }
}
