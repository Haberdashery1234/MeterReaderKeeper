//
//  ManagementScreenUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26.
//

import XCTest

/// Mirrors `Source/Screens/Management/ManagementTableViewController.swift`.
final class ManagementScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Navigates from Home to Management with the fixed fixture already
    /// seeded (4 buildings: "121 Seaport", "25 State", "141 Franklin",
    /// "16 Pinkham" — see `SeedFixture.json`).
    private func openManagement() throws -> XCUIApplication {
        let launcher = try UITestAppLauncher(seeded: true)
        let app = launcher.app
        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 5), "Management.tableView never appeared")
        return app
    }

    /// Buildings segment lists all seeded buildings
    func testBuildingsSegmentListsSeededBuildings() throws {
        let app = try openManagement()
        let table = app.tables["Management.tableView"]

        for name in ["121 Seaport", "25 State", "141 Franklin", "16 Pinkham"] {
            XCTAssertTrue(table.staticTexts[name].waitForExistence(timeout: 5))
        }
    }

    /// Floors segment lists a non-empty set of floors
    func testFloorsSegmentListsFloors() throws {
        let app = try openManagement()
        app.segmentedControls["Management.segmentedControl"].buttons["Floors"].tap()

        let table = app.tables["Management.tableView"]
        XCTAssertTrue(table.cells.firstMatch.waitForExistence(timeout: 5))
    }

    /// Meters segment lists a non-empty set of meters
    func testMetersSegmentListsMeters() throws {
        let app = try openManagement()
        app.segmentedControls["Management.segmentedControl"].buttons["Meters"].tap()

        let table = app.tables["Management.tableView"]
        XCTAssertTrue(table.cells.firstMatch.waitForExistence(timeout: 5))
    }

    /// tapping a building row opens Edit Building with its name populated
    func testTappingBuildingRowOpensEditBuilding() throws {
        let app = try openManagement()
        let table = app.tables["Management.tableView"]
        let row = table.staticTexts["121 Seaport"]
        try requireUITest(row.waitForExistence(timeout: 5), "121 Seaport row never appeared")
        row.tap()

        XCTAssertTrue(app.navigationBars["Edit Building"].waitForExistence(timeout: 5))
        let nameField = app.textFields["AddEditBuilding.nameTextField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "121 Seaport")
    }

    /// + with existing buildings offers Building and Meter
    func testAddButtonOffersBuildingAndMeter() throws {
        let app = try openManagement()
        app.navigationBars.buttons["Management.addButton"].tap()

        let sheet = app.sheets["Add Item"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        XCTAssertTrue(sheet.buttons["Building"].exists)
        XCTAssertTrue(sheet.buttons["Meter"].exists)
        sheet.buttons["Cancel"].tap()
    }
}
