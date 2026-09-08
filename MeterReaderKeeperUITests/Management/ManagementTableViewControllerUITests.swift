//
//  ManagementTableViewControllerUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26. Reorganized 9/1/26 into one UI test file per view
//  controller, mirroring the app target's own folder hierarchy under this
//  target. Converted 9/2/26 to a single shared seeded launch across the
//  whole class — see "UI test performance: shared launches (2026-09-02)"
//  in project memory.
//

import XCTest

/// Mirrors `Source/Screens/Management/ManagementTableViewController.swift`.
///
/// Every test below only navigates and reads — none of them save, delete,
/// or otherwise mutate the seeded fixture — so the whole class shares one
/// ~20s seeded launch instead of each test paying it independently.
final class ManagementTableViewControllerUITests: XCTestCase {

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
        // A previous test method may have left the app on some pushed
        // screen — reset to Home before this test navigates back down on
        // its own, so tests stay order-independent.
        try UITestAppLauncher.returnToHome(Self.sharedLauncher.app)
    }

    /// Navigates from Home to Management on the class's shared seeded
    /// launch (4 buildings: "121 Seaport", "25 State", "141 Franklin",
    /// "16 Pinkham" — see `SeedFixture.json`).
    private func openManagement() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
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

    /// tapping a floor row opens the Floor Meters screen, not the floor's
    /// own edit form (2026-08-28 change — see `FloorMetersViewControllerUITests`)
    func testTappingFloorRowOpensFloorMeters() throws {
        let app = try openManagement()
        app.segmentedControls["Management.segmentedControl"].buttons["Floors"].tap()

        let table = app.tables["Management.tableView"]
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No floor rows appeared")
        table.cells.firstMatch.tap()

        XCTAssertTrue(app.tables["FloorMeters.tableView"].waitForExistence(timeout: 5))
    }

    /// tapping a meter row opens Edit Meter with its name populated
    func testTappingMeterRowOpensEditMeter() throws {
        let app = try openManagement()
        app.segmentedControls["Management.segmentedControl"].buttons["Meters"].tap()

        let table = app.tables["Management.tableView"]
        try requireUITest(table.cells.firstMatch.waitForExistence(timeout: 5), "No meter rows appeared")
        table.cells.firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Edit Meter"].waitForExistence(timeout: 5))
        let nameField = app.textFields["AddEditMeter.nameTextField"]
        try requireUITest(nameField.waitForExistence(timeout: 5), "AddEditMeter.nameTextField never appeared")
        XCTAssertNotEqual(nameField.value as? String, "")
    }
}
