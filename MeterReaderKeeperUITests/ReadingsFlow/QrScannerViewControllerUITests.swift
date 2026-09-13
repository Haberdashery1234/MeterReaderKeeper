//
//  QrScannerViewControllerUITests.swift
//  MeterReaderKeeperUITests
//

import XCTest

/// Mirrors `Source/Screens/ReadingsFlow/QrScannerViewController.swift`.
///
/// `QrScannerViewController` is wired into the app (see
/// `ReadingsMainViewControllerUITests.testScanButtonOpensQrScanner()` for
/// the navigation coverage), but it's `AVCaptureSession`-backed, which
/// needs real camera hardware the simulator doesn't have — there's no way
/// to drive an actual scan through XCUITest, so that part stays untested
/// here.
final class QrScannerViewControllerUITests: XCTestCase {

    func testNoCameraHardwareInSimulator() throws {
        throw XCTSkip("QrScannerViewController needs real camera hardware, which the simulator doesn't have — nothing to drive a scan through.")
    }
}
