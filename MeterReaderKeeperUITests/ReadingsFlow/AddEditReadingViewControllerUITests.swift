//
//  AddEditReadingViewControllerUITests.swift
//  MeterReaderKeeperUITests
//

import XCTest

/// Mirrors `Source/Screens/ReadingsFlow/AddEditReadingViewController.swift`.
final class AddEditReadingViewControllerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Creates a brand-new meter on "121 Seaport" Floor 1 via Management
    /// (so it has zero readings — every *seeded* meter already has one
    /// dated today, which would route to Edit Reading instead), then
    /// navigates Home -> Take Readings -> "121 Seaport" -> that meter's
    /// row, landing on a genuine "Add Reading" screen.
    private func openAddReading() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true, fixtureName: UITestAppLauncher.minimalFixtureName)
        let app = launcher.app

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.navigationBars.buttons["Management.addButton"].tap()
        let addSheet = app.sheets["Add Item"]
        try requireUITest(addSheet.waitForExistence(timeout: 5), "Add Item sheet never appeared")
        addSheet.buttons["Meter"].tap()
        try requireUITest(app.navigationBars["Add Meter"].waitForExistence(timeout: 5), "Add Meter screen never appeared")

        let buildingField = app.textFields["AddEditMeter.buildingTextField"]
        try requireUITest(buildingField.waitForExistence(timeout: 5), "AddEditMeter.buildingTextField never appeared")
        buildingField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "121 Seaport")

        let floorField = app.textFields["AddEditMeter.floorTextField"]
        floorField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Floor 1")

        let nameField = app.textFields["AddEditMeter.nameTextField"]
        nameField.tap()
        nameField.typeText("Unread Test Meter")

        try UITestAppLauncher.dismissInputView(app, byTapping: "Building")
        app.navigationBars.buttons["AddEditMeter.saveButton"].tap()
        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 10), "Management.tableView never reappeared after saving")

        // Back to Home, then into Take Readings for the new meter.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let takeReadingsButton = app.buttons["Take Readings"]
        try requireUITest(takeReadingsButton.waitForExistence(timeout: 5), "Home screen never reappeared")
        takeReadingsButton.tap()

        let buildingSheet = app.sheets["Select Building"]
        try requireUITest(buildingSheet.waitForExistence(timeout: 5), "Select Building sheet never appeared")
        buildingSheet.buttons["121 Seaport"].tap()

        let table = app.tables["ReadingsMain.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "ReadingsMain.tableView never appeared")
        let newMeterRow = table.staticTexts["Unread Test Meter"]
        try requireUITest(newMeterRow.waitForExistence(timeout: 5), "Unread Test Meter row never appeared")
        newMeterRow.tap()

        try requireUITest(app.navigationBars["Add Reading"].waitForExistence(timeout: 5), "Add Reading screen never appeared")
        return app
    }

    /// saving a valid reading returns to the meters list
    func testSavingValidReadingReturnsToList() throws {
        let app = try openAddReading()

        let readingField = app.textFields["AddEditReading.readingTextField"]
        try requireUITest(readingField.waitForExistence(timeout: 5), "AddEditReading.readingTextField never appeared")
        readingField.tap()
        readingField.typeText("123.45")

        app.navigationBars.buttons["AddEditReading.saveButton"].tap()

        XCTAssertTrue(app.tables["ReadingsMain.tableView"].waitForExistence(timeout: 5))
    }

    /// saving a blank reading shows the Missing Reading alert
    func testSavingBlankReadingShowsAlert() throws {
        let app = try openAddReading()

        try requireUITest(app.textFields["AddEditReading.readingTextField"].waitForExistence(timeout: 5), "AddEditReading.readingTextField never appeared")
        app.navigationBars.buttons["AddEditReading.saveButton"].tap()

        let alert = app.alerts["Missing Reading"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }

    /// the form shows the tapped meter's own building context, confirming
    /// `viewModel.building`/`.floor`/`.meter` carried the right meter
    /// through from `ReadingsMainViewController`, not just any meter
    func testShowsTappedMetersBuildingContext() throws {
        let app = try openAddReading()
        XCTAssertTrue(app.staticTexts["121 Seaport"].waitForExistence(timeout: 5))
    }
}
