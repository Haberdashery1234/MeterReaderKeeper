//
//  AddEditFloorScreenUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26.
//

import XCTest

/// Mirrors `Source/Screens/Management/AddEditFloorViewController.swift`.
///
/// There is no "Add Floor" entry point anywhere in the app's UI — floors
/// are created only by setting a building's floor count (see
/// `AddEditBuildingScreenUITests`). This screen is reached only by tapping
/// an existing floor row on the Management screen's Floors segment, so
/// these tests cover the edit flow exclusively.
final class AddEditFloorScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Navigates Home -> Management -> Floors segment -> first floor row,
    /// with the fixed fixture already seeded.
    private func openFirstFloor() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true)
        let app = launcher.app

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        let table = app.tables["Management.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.segmentedControls["Management.segmentedControl"].buttons["Floors"].tap()
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No floor rows appeared")
        table.cells.firstMatch.tap()

        try requireUITest(app.navigationBars["Edit Floor"].waitForExistence(timeout: 5), "Edit Floor screen never appeared")
        return app
    }

    /// editing a floor's number and saving updates it in the list
    func testEditingFloorNumberUpdatesList() throws {
        let app = try openFirstFloor()

        let floorField = app.textFields["AddEditFloor.floorTextField"]
        try requireUITest(floorField.waitForExistence(timeout: 5), "AddEditFloor.floorTextField never appeared")
        floorField.tap()
        floorField.clearAndTypeText("999")

        app.buttons["AddEditFloor.saveButton"].tap()

        let table = app.tables["Management.tableView"]
        let updatedRow = table.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Floor 999")
        ).firstMatch
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 5))
    }

    /// clearing the floor number and saving shows the Invalid Floor alert
    func testClearingFloorNumberShowsAlert() throws {
        let app = try openFirstFloor()

        let floorField = app.textFields["AddEditFloor.floorTextField"]
        try requireUITest(floorField.waitForExistence(timeout: 5), "AddEditFloor.floorTextField never appeared")
        floorField.tap()
        floorField.clearAndTypeText("")

        app.buttons["AddEditFloor.saveButton"].tap()

        let alert = app.alerts["Invalid Floor"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }
}
