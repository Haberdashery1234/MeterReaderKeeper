//
//  MRKMeterTests.swift
//  MeterReaderKeeperTests
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/Domain/MRKMeter.swift`, which declares both
/// `MRKMeter` and `MRKMeterInput` — this file tests both.
@Suite("MRKMeter")
struct MRKMeterTests {

    private func makeReading(date: Date, kWh: Double) -> MRKReading {
        MRKReading(id: UUID(), date: date, kWh: kWh, meterID: UUID())
    }

    private func makeMeter(readings: [MRKReading]) -> MRKMeter {
        MRKMeter(
            id: UUID(), name: "M1", meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: readings
        )
    }

    @Test("sortedReadings orders newest first")
    func sortedReadingsOrdersNewestFirst() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        let meter = makeMeter(readings: [
            makeReading(date: lastWeek, kWh: 1),
            makeReading(date: today, kWh: 3),
            makeReading(date: yesterday, kWh: 2)
        ])

        #expect(meter.sortedReadings.map { $0.kWh } == [3, 2, 1])
    }

    @Test("mostRecentReading is the newest one")
    func mostRecentReadingIsTheNewestOne() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let meter = makeMeter(readings: [
            makeReading(date: yesterday, kWh: 100),
            makeReading(date: today, kWh: 200)
        ])

        #expect(meter.mostRecentReading?.kWh == 200)
    }

    @Test("mostRecentReading is nil with no readings")
    func mostRecentReadingIsNilWithNoReadings() {
        #expect(makeMeter(readings: []).mostRecentReading == nil)
    }

    @Test("validate rejects a blank name")
    func validateRejectsBlankName() {
        let meter = MRKMeter(
            id: UUID(), name: "  ", meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: []
        )
        #expect(throws: (any Error).self) {
            try meter.validate()
        }
    }

    @Test("validate accepts a non-empty name")
    func validateAcceptsNonEmptyName() throws {
        let meter = MRKMeter(
            id: UUID(), name: "M1", meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: []
        )
        try meter.validate()
    }

    private func makeMeter(latestReadingDate: Date) -> MRKMeter {
        MRKMeter(
            id: UUID(), name: "M1", meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: latestReadingDate, floorID: UUID(), readings: []
        )
    }

    @Test("daysSinceLastReading is nil when never read")
    func daysSinceLastReadingIsNilWhenNeverRead() {
        let meter = makeMeter(latestReadingDate: .distantPast)
        #expect(meter.daysSinceLastReading() == nil)
    }

    @Test("daysSinceLastReading counts whole days since the last reading")
    func daysSinceLastReadingCountsWholeDays() {
        let now = Date()
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let meter = makeMeter(latestReadingDate: tenDaysAgo)
        #expect(meter.daysSinceLastReading(asOf: now) == 10)
    }

    @Test("isStale is true when never read")
    func isStaleIsTrueWhenNeverRead() {
        let meter = makeMeter(latestReadingDate: .distantPast)
        #expect(meter.isStale())
    }

    @Test("isStale is true at or past the threshold")
    func isStaleIsTrueAtThreshold() {
        let now = Date()
        let atThreshold = Calendar.current.date(byAdding: .day, value: -MRKMeter.staleThresholdDays, to: now)!
        let meter = makeMeter(latestReadingDate: atThreshold)
        #expect(meter.isStale(asOf: now))
    }

    @Test("isStale is false comfortably within the threshold")
    func isStaleIsFalseWithinThreshold() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let meter = makeMeter(latestReadingDate: yesterday)
        #expect(meter.isStale(asOf: now) == false)
    }

    @Test("lastReadingSummary reports never read")
    func lastReadingSummaryReportsNeverRead() {
        let meter = makeMeter(latestReadingDate: .distantPast)
        #expect(meter.lastReadingSummary == "Never read")
    }

    /// Unlike `makeMeter(latestReadingDate:)` above, `lastReadingSummary`
    /// also needs `mostRecentReading` to be non-nil, so this helper keeps
    /// `readings` and `latestReadingDate` consistent.
    private func makeMeterWithReading(date: Date, kWh: Double) -> MRKMeter {
        MRKMeter(
            id: UUID(), name: "M1", meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: date, floorID: UUID(),
            readings: [makeReading(date: date, kWh: kWh)]
        )
    }

    @Test("lastReadingSummary includes a formatted date when read")
    func lastReadingSummaryIncludesFormattedDate() {
        let now = Date()
        let meter = makeMeterWithReading(date: now, kWh: 100)
        #expect(meter.lastReadingSummary.hasPrefix("Last read "))
        #expect(meter.lastReadingSummary != "Never read")
    }

    @Test("lastReadingSummary includes the reading's formatted value")
    func lastReadingSummaryIncludesFormattedValue() {
        let meter = makeMeterWithReading(date: Date(), kWh: 245.1)
        #expect(meter.lastReadingSummary.contains("245.10 kWh"))
    }
}

@Suite("MRKMeterInput")
struct MRKMeterInputTests {

    @Test("validate rejects a blank name")
    func validateRejectsBlankName() {
        let input = MRKMeterInput(name: "   ", description: "", imageData: Data(), floorID: UUID())
        #expect(throws: (any Error).self) {
            try input.validate()
        }
    }

    @Test("validate accepts a non-empty name")
    func validateAcceptsNonEmptyName() throws {
        let input = MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: UUID())
        try input.validate()
    }
}
