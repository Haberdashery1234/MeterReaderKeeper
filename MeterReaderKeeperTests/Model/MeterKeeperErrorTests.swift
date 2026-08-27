//
//  MeterKeeperErrorTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/MeterReaderKeeperError.swift`.
final class MeterKeeperErrorTests: XCTestCase {

    func testValidationErrorDescriptions() {
        XCTAssertEqual(
            MeterKeeperError.validationError(.missingRequiredField("Name")).errorDescription,
            "Required field is missing: Name"
        )
        XCTAssertEqual(
            MeterKeeperError.validationError(.negativeValue).errorDescription,
            "Value cannot be negative"
        )
        XCTAssertEqual(
            MeterKeeperError.validationError(.readingInFuture).errorDescription,
            "Reading date cannot be in the future"
        )
        XCTAssertEqual(
            MeterKeeperError.validationError(.invalidInput("bad format")).errorDescription,
            "Invalid input: bad format"
        )
        XCTAssertEqual(
            MeterKeeperError.validationError(.duplicateName("121 Seaport")).errorDescription,
            "An item with the name '121 Seaport' already exists"
        )
    }

    func testPersistenceErrorWrapsUnderlyingDescription() {
        let underlying = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "disk full"])
        XCTAssertEqual(
            MeterKeeperError.persistenceError(underlying).errorDescription,
            "Database error: disk full"
        )
    }

    func testFileSystemErrorWrapsUnderlyingDescription() {
        let underlying = NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "no permission"])
        XCTAssertEqual(
            MeterKeeperError.fileSystemError(underlying).errorDescription,
            "File system error: no permission"
        )
    }

    func testNotFoundIncludesTheItemName() {
        XCTAssertEqual(MeterKeeperError.notFound("Building").errorDescription, "Building not found")
    }

    func testUnknownWrapsUnderlyingDescription() {
        let underlying = NSError(domain: "Test", code: 3, userInfo: [NSLocalizedDescriptionKey: "mystery"])
        XCTAssertEqual(
            MeterKeeperError.unknown(underlying).errorDescription,
            "An unknown error occurred: mystery"
        )
    }
}
