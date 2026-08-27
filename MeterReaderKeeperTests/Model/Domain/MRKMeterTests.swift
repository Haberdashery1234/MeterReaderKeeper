//
//  MRKMeterTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/Domain/MRKMeter.swift`, which declares both
/// `MRKMeter` and `MRKMeterInput` — this file tests both.
final class MRKMeterTests: XCTestCase {

    private func makeReading(date: Date, kWh: Double) -> MRKReading {
        MRKReading(id: UUID(), date: date, kWh: kWh, meterID: UUID())
    }

    private func makeMeter(readings: [MRKReading]) -> MRKMeter {
        MRKMeter(
            id: UUID(), name: "M1", meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: readings
        )
    }

    func testSortedReadingsOrdersNewestFirst() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        let meter = makeMeter(readings: [
            makeReading(date: lastWeek, kWh: 1),
            makeReading(date: today, kWh: 3),
            makeReading(date: yesterday, kWh: 2)
        ])

        XCTAssertEqual(meter.sortedReadings.map { $0.kWh }, [3, 2, 1])
    }

    func testMostRecentReadingIsTheNewestOne() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let meter = makeMeter(readings: [
            makeReading(date: yesterday, kWh: 100),
            makeReading(date: today, kWh: 200)
        ])

        XCTAssertEqual(meter.mostRecentReading?.kWh, 200)
    }

    func testMostRecentReadingIsNilWithNoReadings() {
        XCTAssertNil(makeMeter(readings: []).mostRecentReading)
    }

    func testValidateRejectsBlankName() {
        let meter = MRKMeter(
            id: UUID(), name: "  ", meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: []
        )
        XCTAssertThrowsError(try meter.validate())
    }

    func testValidateAcceptsNonEmptyName() {
        let meter = MRKMeter(
            id: UUID(), name: "M1", meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: []
        )
        XCTAssertNoThrow(try meter.validate())
    }
}

final class MRKMeterInputTests: XCTestCase {

    func testValidateRejectsBlankName() {
        let input = MRKMeterInput(name: "   ", description: "", imageData: Data(), floorID: UUID())
        XCTAssertThrowsError(try input.validate())
    }

    func testValidateAcceptsNonEmptyName() {
        let input = MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: UUID())
        XCTAssertNoThrow(try input.validate())
    }
}
