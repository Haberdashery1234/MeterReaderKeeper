//
//  MRKReadingTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/Domain/MRKReading.swift`, which declares both
/// `MRKReading` and `MRKReadingInput` — this file tests both.
final class MRKReadingTests: XCTestCase {

    func testFormattedValueShowsTwoDecimalPlacesAndUnit() {
        let reading = MRKReading(id: UUID(), date: Date(), kWh: 1234.5, meterID: UUID())
        XCTAssertEqual(reading.formattedValue, "1234.50 kWh")
    }

    func testValidateRejectsNegativeKWh() {
        let reading = MRKReading(id: UUID(), date: Date(), kWh: -1, meterID: UUID())
        XCTAssertThrowsError(try reading.validate())
    }

    func testValidateRejectsFutureDate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let reading = MRKReading(id: UUID(), date: tomorrow, kWh: 100, meterID: UUID())
        XCTAssertThrowsError(try reading.validate())
    }

    func testValidateAcceptsZeroKWhAtOrBeforeNow() {
        let reading = MRKReading(id: UUID(), date: Date(), kWh: 0, meterID: UUID())
        XCTAssertNoThrow(try reading.validate())
    }
}

final class MRKReadingInputTests: XCTestCase {

    func testValidateRejectsNegativeKWh() {
        let input = MRKReadingInput(kWh: -0.01, date: Date(), meterID: UUID())
        XCTAssertThrowsError(try input.validate())
    }

    func testValidateRejectsFutureDate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let input = MRKReadingInput(kWh: 100, date: tomorrow, meterID: UUID())
        XCTAssertThrowsError(try input.validate())
    }

    func testValidateAcceptsZeroKWh() {
        let input = MRKReadingInput(kWh: 0, date: Date(), meterID: UUID())
        XCTAssertNoThrow(try input.validate())
    }
}
