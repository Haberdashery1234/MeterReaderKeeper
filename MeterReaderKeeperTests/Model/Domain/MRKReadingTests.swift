//
//  MRKReadingTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26 (migration pilot).
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/Domain/MRKReading.swift`, which declares both
/// `MRKReading` and `MRKReadingInput` — this file tests both.
///
/// Swift Testing pilot note: unlike the `XCTAssertNoThrow` cases in the
/// original XCTest version, a "should not throw" assertion here is just a
/// plain `try` call inside a `throws` `@Test` function — any error
/// propagating out of the test body fails it automatically, so there's no
/// separate no-throw assertion macro needed.
@Suite("MRKReading")
struct MRKReadingTests {

    @Test("formattedValue shows two decimal places and the kWh unit")
    func formattedValueShowsTwoDecimalPlacesAndUnit() {
        let reading = MRKReading(id: UUID(), date: Date(), kWh: 1234.5, meterID: UUID())
        #expect(reading.formattedValue == "1234.50 kWh")
    }

    @Test("validate rejects negative kWh")
    func validateRejectsNegativeKWh() {
        let reading = MRKReading(id: UUID(), date: Date(), kWh: -1, meterID: UUID())
        #expect(throws: (any Error).self) {
            try reading.validate()
        }
    }

    @Test("validate rejects a future date")
    func validateRejectsFutureDate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let reading = MRKReading(id: UUID(), date: tomorrow, kWh: 100, meterID: UUID())
        #expect(throws: (any Error).self) {
            try reading.validate()
        }
    }

    @Test("validate accepts zero kWh at or before now")
    func validateAcceptsZeroKWhAtOrBeforeNow() throws {
        let reading = MRKReading(id: UUID(), date: Date(), kWh: 0, meterID: UUID())
        try reading.validate()
    }
}

@Suite("MRKReading.usage")
struct MRKReadingUsageTests {

    private func reading(_ kWh: Double, daysAgo: Int) -> MRKReading {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return MRKReading(id: UUID(), date: date, kWh: kWh, meterID: UUID())
    }

    @Test("usage is the plain difference when the reading increased")
    func usageIsPlainDifferenceWhenIncreasing() {
        let previous = reading(10_000, daysAgo: 1)
        let current = reading(10_250.5, daysAgo: 0)
        #expect(MRKReading.usage(from: previous, to: current) == 250.5)
    }

    @Test("usage is zero when the reading is unchanged")
    func usageIsZeroWhenUnchanged() {
        let previous = reading(10_000, daysAgo: 1)
        let current = reading(10_000, daysAgo: 0)
        #expect(MRKReading.usage(from: previous, to: current) == 0)
    }

    @Test("a drop from a 4-digit reading rolls over at 10,000 — Christian's example")
    func usageHandlesFourDigitRollover() {
        let previous = reading(9997, daysAgo: 1)
        let current = reading(200, daysAgo: 0)
        #expect(MRKReading.usage(from: previous, to: current) == 203)
    }

    @Test("a drop from a 7-digit reading rolls over at 10,000,000 — Christian's example")
    func usageHandlesSevenDigitRollover() {
        let previous = reading(9_999_997, daysAgo: 1)
        let current = reading(200, daysAgo: 0)
        #expect(MRKReading.usage(from: previous, to: current) == 203)
    }

    @Test("rollover math ignores the previous reading's decimal portion")
    func usageIgnoresDecimalPortionOfPreviousReading() {
        let previous = reading(9997.75, daysAgo: 1)
        let current = reading(200, daysAgo: 0)
        // Still a 4-digit whole number, so still wraps at 10,000 — the
        // fractional .75 doesn't push it into a 5-digit cap.
        #expect(MRKReading.usage(from: previous, to: current) == 202.25)
    }
}

@Suite("MRKReadingInput")
struct MRKReadingInputTests {

    @Test("validate rejects negative kWh")
    func validateRejectsNegativeKWh() {
        let input = MRKReadingInput(kWh: -0.01, date: Date(), meterID: UUID())
        #expect(throws: (any Error).self) {
            try input.validate()
        }
    }

    @Test("validate rejects a future date")
    func validateRejectsFutureDate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let input = MRKReadingInput(kWh: 100, date: tomorrow, meterID: UUID())
        #expect(throws: (any Error).self) {
            try input.validate()
        }
    }

    @Test("validate accepts zero kWh")
    func validateAcceptsZeroKWh() throws {
        let input = MRKReadingInput(kWh: 0, date: Date(), meterID: UUID())
        try input.validate()
    }
}
