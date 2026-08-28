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
/// tap, giving tests the identical fixed fixture the unit tests already
/// rely on (4 buildings: "121 Seaport", "25 State", "141 Franklin", "16
/// Pinkham" — see `SeedFixture.json`).
struct UITestAppLauncher {

    /// Checked by `SceneDelegate.makeRepository()`, `#if DEBUG` only.
    static let inMemoryStoreLaunchArgument = "-UITestInMemoryStore"

    let app: XCUIApplication

    /// - Parameter seeded: if `true`, taps the DEBUG-only "Seed Test Data"
    ///   button on the Home screen immediately after launch and waits for
    ///   the resulting "Success" alert before returning, so the caller's
    ///   test starts from the known fixture data already populated.
    init(seeded: Bool = false, file: StaticString = #filePath, line: UInt = #line) throws {
        app = XCUIApplication()
        app.launchArguments = [Self.inMemoryStoreLaunchArgument]
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
            successAlert.waitForExistence(timeout: 10),
            "Seeding did not finish (no \"Success\" alert) within 10s",
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
