//
//  HomeScreenUITests.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26.
//

import XCTest

/// Mirrors `Source/Screens/HomeViewController.swift`.
final class HomeScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        // Stop each test at its first failure instead of letting every
        // subsequent UI interaction fail too once one element isn't found.
        continueAfterFailure = false
    }

    /// launching shows the primary action buttons
    func testLaunchShowsPrimaryButtons() throws {
        let launcher = try UITestAppLauncher()
        let app = launcher.app

        XCTAssertTrue(app.buttons["Take Readings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Previous Readings"].exists)
        XCTAssertTrue(app.buttons["Manage Buildings & Meters"].exists)
        XCTAssertTrue(app.buttons["Export Data"].exists)
    }

    /// Take Readings with no buildings shows the No Buildings alert
    func testTakeReadingsWithNoBuildingsShowsAlert() throws {
        let launcher = try UITestAppLauncher()
        let app = launcher.app

        let takeReadingsButton = app.buttons["Take Readings"]
        try requireUITest(takeReadingsButton.waitForExistence(timeout: 5), "Take Readings button never appeared")
        takeReadingsButton.tap()

        let alert = app.alerts["No Buildings"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["OK"].tap()
    }

    /// Seed Test Data seeds the fixed fixture and confirms success
    func testSeedDataSeedsFixture() throws {
        // UITestAppLauncher(seeded: true) already does the tap-and-confirm
        // dance and requires each step succeeds — not throwing is the test.
        _ = try UITestAppLauncher(seeded: true)
    }

    /// Previous Readings navigates to the Previous Readings screen
    func testPreviousReadingsNavigates() throws {
        let launcher = try UITestAppLauncher()
        let app = launcher.app

        let previousReadingsButton = app.buttons["Previous Readings"]
        try requireUITest(previousReadingsButton.waitForExistence(timeout: 5), "Previous Readings button never appeared")
        previousReadingsButton.tap()

        XCTAssertTrue(app.navigationBars["Previous Readings"].waitForExistence(timeout: 5))
    }

    /// Manage Buildings & Meters navigates to the Management screen
    func testManageNavigates() throws {
        let launcher = try UITestAppLauncher()
        let app = launcher.app

        let manageButton = app.buttons["Manage Buildings & Meters"]
        try requireUITest(manageButton.waitForExistence(timeout: 5), "Manage Buildings & Meters button never appeared")
        manageButton.tap()

        XCTAssertTrue(app.navigationBars["Manage Buildings"].waitForExistence(timeout: 5))
    }
}
