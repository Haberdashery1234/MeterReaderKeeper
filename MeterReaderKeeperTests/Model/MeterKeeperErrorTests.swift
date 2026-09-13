//
//  MeterKeeperErrorTests.swift
//  MeterReaderKeeperTests
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/MeterReaderKeeperError.swift`.
@Suite("MeterKeeperError")
struct MeterKeeperErrorTests {

    @Test("validation error descriptions")
    func validationErrorDescriptions() {
        #expect(
            MeterKeeperError.validationError(.missingRequiredField("Name")).errorDescription ==
            "Required field is missing: Name"
        )
        #expect(
            MeterKeeperError.validationError(.negativeValue).errorDescription ==
            "Value cannot be negative"
        )
        #expect(
            MeterKeeperError.validationError(.readingInFuture).errorDescription ==
            "Reading date cannot be in the future"
        )
        #expect(
            MeterKeeperError.validationError(.invalidInput("bad format")).errorDescription ==
            "Invalid input: bad format"
        )
        #expect(
            MeterKeeperError.validationError(.duplicateName("121 Seaport")).errorDescription ==
            "An item with the name '121 Seaport' already exists"
        )
    }

    @Test("persistenceError wraps the underlying description")
    func persistenceErrorWrapsUnderlyingDescription() {
        let underlying = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "disk full"])
        #expect(
            MeterKeeperError.persistenceError(underlying).errorDescription ==
            "Database error: disk full"
        )
    }

    @Test("fileSystemError wraps the underlying description")
    func fileSystemErrorWrapsUnderlyingDescription() {
        let underlying = NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "no permission"])
        #expect(
            MeterKeeperError.fileSystemError(underlying).errorDescription ==
            "File system error: no permission"
        )
    }

    @Test("notFound includes the item name")
    func notFoundIncludesTheItemName() {
        #expect(MeterKeeperError.notFound("Building").errorDescription == "Building not found")
    }

    @Test("unknown wraps the underlying description")
    func unknownWrapsUnderlyingDescription() {
        let underlying = NSError(domain: "Test", code: 3, userInfo: [NSLocalizedDescriptionKey: "mystery"])
        #expect(
            MeterKeeperError.unknown(underlying).errorDescription ==
            "An unknown error occurred: mystery"
        )
    }
}
