//
//  MRKMeterTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
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
