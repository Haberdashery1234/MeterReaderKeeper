//
//  QrScannerViewControllerUITests.swift
//  MeterReaderKeeperUITests
//
//  Created 9/1/26. One file per view controller, mirroring the app
//  target's own folder hierarchy under this target — this file exists for
//  that mapping even though it can't drive any real UI coverage; see below.
//

import XCTest

/// Mirrors `Source/Screens/ReadingsFlow/QrScannerViewController.swift`.
///
/// `QrScannerViewController` is **not wired into the app** —
/// `AppCoordinator` has no `showQrScanner()`, and `ReadingsMainViewController`
/// 's scan button shows a placeholder alert instead of presenting this
/// screen (covered by `ReadingsMainViewControllerUITests
/// .testScanButtonShowsPlaceholderAlert()`). There is no path through the
/// app's UI that reaches this screen, so a real UI test — navigate here,
/// assert something — isn't possible the way it is for every other
/// screen. It's also `AVCaptureSession`-backed, which needs real camera
/// hardware the iOS Simulator doesn't have, so even a hypothetical direct
/// presentation wouldn't be meaningfully testable via XCUITest.
///
/// This is flagged rather than silently skipped: if `QrScannerViewController`
/// is ever wired up (`AppCoordinator.showQrScanner()` + a real
/// `scannerDelegate`), replace this file's single test with real coverage
/// of that flow.
final class QrScannerViewControllerUITests: XCTestCase {

    func testNoEntryPointExistsYet() throws {
        throw XCTSkip("QrScannerViewController isn't reachable from the app's UI yet (see this file's header comment) — nothing to drive a UI test through.")
    }
}
