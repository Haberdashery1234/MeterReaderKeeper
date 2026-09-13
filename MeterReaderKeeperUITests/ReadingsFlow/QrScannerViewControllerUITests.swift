//
//  QrScannerViewControllerUITests.swift
//  MeterReaderKeeperUITests
//

import XCTest

/// Mirrors `Source/Screens/ReadingsFlow/QrScannerViewController.swift`.
///
/// `QrScannerViewController` isn't wired into the app — there's no path
/// through the UI that presents it (the scan button shows a placeholder
/// alert instead, covered by
/// `ReadingsMainViewControllerUITests.testScanButtonShowsPlaceholderAlert()`).
/// It's also `AVCaptureSession`-backed, which needs real camera hardware
/// the simulator doesn't have. There's nothing to drive a UI test through,
/// so this file just documents that.
final class QrScannerViewControllerUITests: XCTestCase {

    func testNoEntryPointExistsYet() throws {
        throw XCTSkip("QrScannerViewController isn't reachable from the app's UI — nothing to drive a UI test through.")
    }
}
