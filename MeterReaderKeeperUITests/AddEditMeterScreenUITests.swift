//
//  AddEditMeterScreenUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26.
//

import XCTest

/// Mirrors `Source/Screens/Management/AddEditMeterViewController.swift`.
final class AddEditMeterScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Navigates Home -> Management -> "+" -> "Meter" (only offered once a
    /// building with floors exists, which the seeded fixture guarantees),
    /// with the fixed fixture already seeded, and waits for the
    /// "Add Meter" screen.
    private func openAddMeter() throws -> XCUIApplication {
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

    /// saving a new meter with a building, floor, and name adds it to the list
    func testSavingNewMeterAddsItToList() throws {
        let app = try openAddMeter()

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

        app.buttons["AddEditMeter.saveButton"].tap()

        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 5), "Management.tableView never reappeared after saving")
        app.segmentedControls["Management.segmentedControl"].buttons["Meters"].tap()
        XCTAssertTrue(app.tables["Management.tableView"].staticTexts["Test Meter 999"].waitForExistence(timeout: 5))
    }

    /// saving with a blank name shows the Missing Name alert
    func testSavingWithBlankNameShowsAlert() throws {
        let app = try openAddMeter()

        let buildingField = app.textFields["AddEditMeter.buildingTextField"]
        try requireUITest(buildingField.waitForExistence(timeout: 5), "AddEditMeter.buildingTextField never appeared")
        buildingField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "121 Seaport")

        let floorField = app.textFields["AddEditMeter.floorTextField"]
        floorField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Floor 1")

        app.buttons["AddEditMeter.saveButton"].tap()

        let alert = app.alerts["Missing Name"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }
}
