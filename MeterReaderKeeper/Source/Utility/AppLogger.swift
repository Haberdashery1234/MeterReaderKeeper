//
//  AppLogger.swift
//  MeterReaderKeeper
//
//  Added on 2026-09-13 to replace the codebase's ad-hoc print() logging.
//

import os

/// Centralized `os.Logger` instances for this app, one per feature area,
/// all sharing the app's bundle ID as their subsystem. Console.app / the
/// Xcode console can filter by subsystem+category to isolate one area's
/// logs, which plain `print()` statements never allowed.
enum AppLogger {
    private static let subsystem = "com.Haberdashery1234.MeterReaderKeeper"

    /// `DataSeeder`'s bulk-fixture-loading lifecycle.
    static let dataSeeding = Logger(subsystem: subsystem, category: "DataSeeding")
    /// `UIService`'s image compression pipeline.
    static let imageProcessing = Logger(subsystem: subsystem, category: "ImageProcessing")
    /// `EmailService`'s compose/send flow.
    static let email = Logger(subsystem: subsystem, category: "Email")
    /// Shared by every ViewModel for save/select/load status logging.
    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
}
