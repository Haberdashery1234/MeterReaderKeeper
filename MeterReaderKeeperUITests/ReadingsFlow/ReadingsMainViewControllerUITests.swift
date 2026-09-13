//
//  ReadingsMainViewControllerUITests.swift
//  MeterReaderKeeperUITests
//

import XCTest

/// Mirrors `Source/Screens/ReadingsFlow/ReadingsMainViewController.swift`.
///
/// The tests that check opening with a floor and meters, tapping a
/// seeded meter, the scan-button alert, the map-button alert, and the
/// floor picker don't mutate the fixture, so they share one seeded launch
/// via `openReadingsShared()`. `testTappingFreshlyAddedMeterOpensAddReading`
/// creates a brand-new meter as part of what it's testing, so it uses its
/// own fresh, isolated launch.
///
/// `XCUIApplication.launch()` restarts whatever process currently backs
/// its bundle ID rather than starting an independent one, so the
/// isolated launch above replaces the process the shared launcher's
/// `app` refers to. Any meter it adds to "121 Seaport" Floor 1 is
/// therefore visible in the shared tests' table as well, which is why
/// tests reading that table select a meter by name rather than by row
/// position.
final class ReadingsMainViewControllerUITests: XCTestCase {

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

    /// Navigates Home -> "Take Readings" -> "121 Seaport" on the class's
    /// shared seeded launch, resetting to Home first so tests stay
    /// order-independent. The seeded fixture has 4 buildings, so "Take
    /// Readings" always presents a "Select Building" action sheet rather
    /// than jumping straight in.
    private func openReadingsShared() throws -> XCUIApplication {
        let app = Self.sharedLauncher.app
        try UITestAppLauncher.returnToHome(app)

        let takeReadingsButton = app.buttons["Take Readings"]
        try requireUITest(takeReadingsButton.waitForExistence(timeout: 5), "Take Readings button never appeared")
        takeReadingsButton.tap()

        let sheet = app.sheets["Select Building"]
        try requireUITest(sheet.waitForExistence(timeout: 5), "Select Building sheet never appeared")
        sheet.buttons["121 Seaport"].tap()

        try requireUITest(app.tables["ReadingsMain.tableView"].waitForExistence(timeout: 5), "ReadingsMain.tableView never appeared")
        return app
    }

    /// Creates a brand-new meter on "121 Seaport" Floor 1 via Management
    /// (so it has zero readings, unlike every *seeded* meter — see
    /// `testTappingFreshlyAddedMeterOpensAddReading` below), then
    /// navigates back to Home so the caller can continue into
    /// "Take Readings" for it.
    private func addUnreadMeter(named name: String, on app: XCUIApplication) throws {
        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()
        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 5), "Management.tableView never appeared")

        app.navigationBars.buttons["Management.addButton"].tap()
        let sheet = app.sheets["Add Item"]
        try requireUITest(sheet.waitForExistence(timeout: 5), "Add Item sheet never appeared")
        sheet.buttons["Meter"].tap()
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
        nameField.typeText(name)

        try UITestAppLauncher.dismissInputView(app, byTapping: "Building")
        app.navigationBars.buttons["AddEditMeter.saveButton"].tap()
        try requireUITest(app.tables["Management.tableView"].waitForExistence(timeout: 10), "Management.tableView never reappeared after saving")

        // Back to Home.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        try requireUITest(app.buttons["Take Readings"].waitForExistence(timeout: 5), "Home screen never reappeared")
    }

    /// opening Readings for a building shows a floor selection and its meters
    func testOpensWithFloorAndMeters() throws {
        let app = try openReadingsShared()

        let floorField = app.textFields["ReadingsMain.floorTextField"]
        XCTAssertTrue(floorField.waitForExistence(timeout: 5))
        XCTAssertTrue((floorField.value as? String)?.hasPrefix("Floor ") == true)

        let table = app.tables["ReadingsMain.tableView"]
        XCTAssertTrue(table.cells.firstMatch.waitForExistence(timeout: 5))
    }

    /// tapping a seeded meter opens Edit Reading, not Add Reading.
    ///
    /// Every meter in `SeedFixture.json` is seeded with a reading dated
    /// today, so `ReadingsMainViewModel.readingRoute(forMeterAt:)` always
    /// routes an existing meter to `.edit`. See
    /// `testTappingFreshlyAddedMeterOpensAddReading` below for the
    /// `.add`-route coverage. Selects "sm-b1f1m1" by name rather than row
    /// position — see the class doc comment above.
    func testTappingSeededMeterOpensEditReading() throws {
        let app = try openReadingsShared()
        let table = app.tables["ReadingsMain.tableView"]
        let meterRow = table.staticTexts["sm-b1f1m1"]
        try requireUITest(meterRow.waitForExistence(timeout: 5), "sm-b1f1m1 row never appeared")
        meterRow.tap()

        try requireUITest(app.navigationBars["Edit Reading"].waitForExistence(timeout: 5), "Edit Reading screen never appeared")
        // Edit Reading pre-fills the existing (today's) reading value,
        // unlike Add Reading, which always starts blank.
        let readingField = app.textFields["AddEditReading.readingTextField"]
        try requireUITest(readingField.waitForExistence(timeout: 5), "AddEditReading.readingTextField never appeared")
        XCTAssertNotEqual(readingField.value as? String, "")
    }

    /// tapping a freshly-added meter (zero readings) opens Add Reading —
    /// the counterpart to `testTappingSeededMeterOpensEditReading` above,
    /// covering the other branch of `readingRoute(forMeterAt:)`. Uses its
    /// own fresh, isolated launch (not the class's shared one) since
    /// creating a new meter is itself a mutation. Named `"zz-..."` so it
    /// sorts after every `"sm-b1f1mN"` fixture meter — see the class doc
    /// comment above.
    func testTappingFreshlyAddedMeterOpensAddReading() throws {
        let launcher = try UITestAppLauncher(seeded: true)
        let app = launcher.app
        try addUnreadMeter(named: "zz-Unread Test Meter", on: app)

        app.buttons["Take Readings"].tap()
        let sheet = app.sheets["Select Building"]
        try requireUITest(sheet.waitForExistence(timeout: 5), "Select Building sheet never appeared")
        sheet.buttons["121 Seaport"].tap()

        let table = app.tables["ReadingsMain.tableView"]
        try requireUITest(table.waitForExistence(timeout: 5), "ReadingsMain.tableView never appeared")
        let newMeterRow = table.staticTexts["zz-Unread Test Meter"]
        try requireUITest(newMeterRow.waitForExistence(timeout: 5), "zz-Unread Test Meter row never appeared")
        newMeterRow.tap()

        XCTAssertTrue(app.navigationBars["Add Reading"].waitForExistence(timeout: 5))
    }

    /// scan button shows the QR Scanner placeholder alert — the real
    /// scanner (`QrScannerViewController`) isn't wired into the coordinator
    func testScanButtonShowsPlaceholderAlert() throws {
        let app = try openReadingsShared()
        app.navigationBars.buttons["ReadingsMain.scanButton"].tap()

        let alert = app.alerts["QR Scanner"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }

    /// map button with no floor map set shows the No Map alert — seed data
    /// never includes real floor-map image bytes (see `DataSeeder`)
    func testMapButtonWithNoMapShowsAlert() throws {
        let app = try openReadingsShared()
        app.navigationBars.buttons["ReadingsMain.mapButton"].tap()

        let alert = app.alerts["No Map"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }

    /// picking a different floor in the floor picker refreshes the meter list
    func testSelectingDifferentFloorUpdatesFloorField() throws {
        let app = try openReadingsShared()

        let floorField = app.textFields["ReadingsMain.floorTextField"]
        try requireUITest(floorField.waitForExistence(timeout: 5), "ReadingsMain.floorTextField never appeared")
        let initialFloor = floorField.value as? String

        floorField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Floor 2")

        XCTAssertNotEqual(floorField.value as? String, initialFloor)
        XCTAssertEqual(floorField.value as? String, "Floor 2")
    }
}
