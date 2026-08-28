//
//  AddEditBuildingScreenUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26.
//

import XCTest

/// Mirrors `Source/Screens/Management/AddEditBuildingViewController.swift`.
final class AddEditBuildingScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Navigates Home -> Management -> "+" -> "Building", with the fixed
    /// fixture already seeded, and waits for the "Add Building" screen.
    private func openAddBuilding() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true)
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

    /// saving a new building with a name and floor count adds it to the list
    func testSavingNewBuildingAddsItToList() throws {
        let app = try openAddBuilding()

        let nameField = app.textFields["AddEditBuilding.nameTextField"]
        try requireUITest(nameField.waitForExistence(timeout: 5), "AddEditBuilding.nameTextField never appeared")
        nameField.tap()
        nameField.typeText("999 Test Ave")

        let floorsField = app.textFields["AddEditBuilding.floorsTextField"]
        floorsField.tap()
        floorsField.typeText("5")

        app.buttons["AddEditBuilding.saveButton"].tap()

        let table = app.tables["Management.tableView"]
        XCTAssertTrue(table.staticTexts["999 Test Ave"].waitForExistence(timeout: 5))
    }

    /// saving with a blank name shows the Invalid Name alert
    func testSavingWithBlankNameShowsAlert() throws {
        let app = try openAddBuilding()

        let floorsField = app.textFields["AddEditBuilding.floorsTextField"]
        try requireUITest(floorsField.waitForExistence(timeout: 5), "AddEditBuilding.floorsTextField never appeared")
        floorsField.tap()
        floorsField.typeText("5")

        app.buttons["AddEditBuilding.saveButton"].tap()

        let alert = app.alerts["Invalid Name"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }
}
