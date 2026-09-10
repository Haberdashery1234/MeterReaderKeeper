//
//  UITestAppLauncher.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26 (UI test target initial build-out).
//  Converted from Swift Testing to XCTest on 8/28/26, per Christian's
//  request that the UI test target use only XCTest.
//

import XCTest

/// XCTest-idiomatic helper for launching `MeterReaderKeeper` under UI test
/// conditions. Plays the same role `SeededRepositoryFixture` plays for the
/// unit test target: each test method creates its own `let launcher =
/// try UITestAppLauncher(seeded: true)`, so every test gets its own
/// freshly launched app process instead of state leaking in from a
/// previous test — the UI-test equivalent of the unit tests' fresh
/// in-memory repository per test.
///
/// ## Why an in-memory store instead of the real on-disk one
///
/// `SwiftDataMeterRepository` already supports an `inMemory: Bool` init
/// parameter, added originally so unit tests could back the repository
/// with a throwaway store. `SceneDelegate` now checks for
/// `Self.inMemoryStoreLaunchArgument` in `ProcessInfo.processInfo.arguments`
/// (gated `#if DEBUG`, so this can never affect a release build) and uses
/// that same `inMemory: true` path when present. This launcher always
/// passes that argument, so every UI test run starts from a guaranteed-
/// empty database — without it, UI tests would read/write the real
/// on-disk SwiftData store and accumulate state across runs, making
/// assertions like "there are exactly 4 buildings" unreliable after the
/// first run.
///
/// ## Why tapping "Seed Test Data" instead of a testing-only seed hook
///
/// The `#if DEBUG || TESTING`-gated `DataSeeder`/`seedData()`/
/// `seedDataButton` machinery (see `HomeViewController`,
/// `HomeViewModel`) is already present in any DEBUG build of the real
/// app — `TESTING` is only defined on the unit test target's build
/// settings, but `DEBUG` alone satisfies the `#if DEBUG || TESTING`
/// guard, and UI tests run against a DEBUG build of the app. So rather
/// than inventing a second, UI-test-only seeding mechanism, `init(seeded:
/// true)` just drives the same "Seed Test Data" button a person would
/// tap — `fixtureName:` picks which of the bundled fixtures it seeds
/// (`smallFixtureName`/`minimalFixtureName` below), not a synthetic
/// seeding path of its own. `smallFixtureName`, the default, is the same
/// 4-building fixture the unit tests seed (see `SeedFixtureName.small`
/// in `DataSeeder.swift`).
struct UITestAppLauncher {

    /// Checked by `SceneDelegate.makeRepository()`, `#if DEBUG` only.
    static let inMemoryStoreLaunchArgument = "-UITestInMemoryStore"

    /// Checked by `HomeViewModel.seedData()` (`#if DEBUG || TESTING`) to
    /// pick which bundled fixture `DataSeeder` seeds. Must match that
    /// file's own literal for this key exactly — this target can't import
    /// the app module's `SeedFixtureName` directly.
    static let fixtureNameEnvironmentKey = "UITEST_FIXTURE_NAME"

    /// Fixture tiers a test can request via `fixtureName:` below — bundle
    /// resource names, matching `SeedFixtureName` on the app side. See
    /// `MeterReaderKeeper/Source/Resources/SeedFixture*.json`.
    static let smallFixtureName = "SeedFixtureSmall"
    static let minimalFixtureName = "SeedFixtureMinimal"

    let app: XCUIApplication

    /// - Parameters:
    ///   - seeded: if `true`, taps the DEBUG-only "Seed Test Data" button
    ///     on the Home screen immediately after launch and waits for the
    ///     resulting "Success" alert before returning, so the caller's
    ///     test starts from the known fixture data already populated.
    ///   - fixtureName: which bundled fixture to seed when `seeded` is
    ///     `true`. Defaults to `smallFixtureName` (4 named buildings, the
    ///     shape most screens need). Pass `minimalFixtureName` for a test
    ///     that only needs a single building — see
    ///     `AddEditBuildingViewControllerUITests` and friends.
    init(
        seeded: Bool = false,
        fixtureName: String = UITestAppLauncher.smallFixtureName,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        app = XCUIApplication()
        app.launchArguments = [Self.inMemoryStoreLaunchArgument]
        app.launchEnvironment[Self.fixtureNameEnvironmentKey] = fixtureName
        app.launch()

        guard seeded else { return }

        let seedButton = app.buttons["Seed Test Data"]
        try requireUITest(
            seedButton.waitForExistence(timeout: 5),
            "Home screen's \"Seed Test Data\" button never appeared — is this a DEBUG build?",
            file: file,
            line: line
        )
        seedButton.tap()

        let successAlert = app.alerts["Success"]
        try requireUITest(
            successAlert.waitForExistence(timeout: 30),
            "Seeding did not finish (no \"Success\" alert) within 30s",
            file: file,
            line: line
        )
        successAlert.buttons["OK"].tap()
    }
}

/// Thrown by `requireUITest(_:_:file:line:)` to unwind out of a test as
/// soon as a precondition fails. The actual failure message/location is
/// already reported via the `XCTFail` call inside `requireUITest` — this
/// error's only job is to stop execution of whatever `throws` function
/// called it, so its own description is never shown to anyone.
struct UITestPreconditionError: Error {}

extension UITestAppLauncher {

    /// Recovers to the Home screen from wherever the app currently is —
    /// dismissing an open alert or sheet first, then popping navigation
    /// bars — so a test class sharing one seeded launch across several
    /// test methods (see "UI test performance: shared launches
    /// (2026-09-02)" in project memory) can reliably reset to a known
    /// starting point before each test navigates back down on its own,
    /// regardless of which screen — or failure state — the previous test
    /// method left the app on.
    ///
    /// Only used by test classes where every shared test is confirmed
    /// non-mutating; a class with tests that save/delete data keeps those
    /// specific tests on their own fresh, isolated launch instead (see
    /// the mixed-file classes for examples), so this never has to reason
    /// about restoring mutated data — only navigation position.
    ///
    /// Calls `app.activate()` first: an isolated launch elsewhere in the
    /// same test run (its own `XCUIApplication`, same simulator) can leave
    /// itself frontmost when its test ends without backgrounding it, so
    /// the shared app isn't guaranteed to already be in front here.
    static func returnToHome(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        app.activate()
        let homeButton = app.buttons["Take Readings"]
        var attempts = 0
        while !homeButton.waitForExistence(timeout: 1) {
            try requireUITest(
                attempts < 10,
                "returnToHome: still not back at Home after \(attempts) recovery taps",
                file: file,
                line: line
            )
            if app.alerts.firstMatch.exists {
                app.alerts.firstMatch.buttons.firstMatch.tap()
            } else if app.sheets.firstMatch.exists {
                let sheet = app.sheets.firstMatch
                if sheet.buttons["Cancel"].exists {
                    sheet.buttons["Cancel"].tap()
                } else {
                    sheet.buttons.firstMatch.tap()
                }
            } else if app.navigationBars.buttons.count > 0 {
                app.navigationBars.buttons.element(boundBy: 0).tap()
            } else {
                try requireUITest(
                    false,
                    "returnToHome: no alert, sheet, or nav-bar back button found to recover with",
                    file: file,
                    line: line
                )
            }
            attempts += 1
        }
    }
}

extension UITestAppLauncher {

    /// Dismisses whatever keyboard or `UIPickerView` input view is
    /// currently up, by tapping one of the form's own caption labels
    /// (e.g. "Building") instead of the field itself.
    ///
    /// Every AddEdit screen in this app wires a tap-anywhere gesture
    /// recognizer on its root `view` that calls `view.endEditing(true)`
    /// (see `AddEditFloorViewController.setupKeyboardHandling()`,
    /// `AddEditMeterViewController.setupKeyboardHandling()`,
    /// `AddEditBuildingViewController.setupKeyboardHandling()`) — and a
    /// `UILabel` has `isUserInteractionEnabled == false` by default, so a
    /// tap on one of these labels passes straight through to that
    /// gesture recognizer instead of being consumed by anything else.
    ///
    /// Originally added so a Save button on a tall form (Floor, Meter —
    /// the ones with an image-picker section) wouldn't sit under an open
    /// keyboard/picker and become briefly not-hittable; see "UI test
    /// fix: keyboard/picker covering Save (2026-09-02)" in project
    /// memory. Save later moved to the nav bar (2026-09-02), which
    /// retired that specific hittability problem — but removing every
    /// call site the same day caused a *different* regression: tapping
    /// Save immediately after a `UIPickerView` selection (the
    /// building/floor pickers used here, not the system keyboard) was
    /// intermittently unreliable — the pop-back-to-Management transition
    /// or a validation alert would sometimes never appear within the
    /// test's wait window, and a failed attempt left the shared launcher
    /// on a half-finished screen for whatever test ran next. Restored
    /// 2026-09-02 for that reason: this call gives the picker's
    /// dismissal a moment to actually settle before Save is tapped,
    /// which building/floor-picker-driven forms (Floor, Meter, and any
    /// helper that creates a meter) need — Building's own form (no
    /// custom picker, just a `numberPad` field) and Reading's own Save
    /// (a `decimalPad` field, no picker) haven't shown this failure mode
    /// and don't call this. See "UI test flakiness: Save after a picker
    /// selection (2026-09-02)" in project memory.
    static func dismissInputView(
        _ app: XCUIApplication,
        byTapping labelText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let label = app.staticTexts[labelText]
        try requireUITest(
            label.waitForExistence(timeout: 5),
            "dismissInputView: '\(labelText)' label never appeared to tap",
            file: file,
            line: line
        )
        label.tap()
    }
}


/// The XCTest analogue of Swift Testing's `#require`: records a failure
/// via `XCTFail` — attributed to the call site via `file`/`line`, matching
/// how `#require` attributes failures to its own call site — and then
/// throws, so callers can `try` it to bail out of the rest of a test (or a
/// shared setup helper) once a required precondition isn't met, instead of
/// letting every subsequent line fail too once one element never appeared.
func requireUITest(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    guard condition() else {
        XCTFail(message(), file: file, line: line)
        throw UITestPreconditionError()
    }
}
