//
//  DataSeederTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Verifies `DataSeeder.seedData()` reproduces `SeedFixture.json` exactly
/// — building/floor/meter shape, meter names and descriptions, and every
/// reading's date and kWh value. Because the fixture is now fixed data
/// rather than a random draw, these are real exact-value assertions
/// (unlike the earlier range-based checks this file used to have), loaded
/// from the same JSON file `DataSeeder` itself reads — see `FixtureLoader`.
final class DataSeederTests: SeededRepositoryTestCase {

    private lazy var fixture: SeedFixture = {
        do {
            return try FixtureLoader.loadSeedFixture()
        } catch {
            XCTFail("Failed to load SeedFixture.json: \(error)")
            return SeedFixture(buildings: [])
        }
    }()

    func testSeedDataMatchesFixtureBuildingAndFloorShape() {
        XCTAssertEqual(seededBuildings.count, fixture.buildings.count)

        let seededByName = Dictionary(uniqueKeysWithValues: seededBuildings.map { ($0.name, $0) })

        for expectedBuilding in fixture.buildings {
            guard let actualBuilding = seededByName[expectedBuilding.name] else {
                XCTFail("Missing seeded building '\(expectedBuilding.name)'")
                continue
            }
            XCTAssertEqual(
                actualBuilding.floors.count, expectedBuilding.floors.count,
                "'\(expectedBuilding.name)' floor count mismatch"
            )

            let actualFloorsByNumber = Dictionary(uniqueKeysWithValues: actualBuilding.floors.map { ($0.number, $0) })
            for expectedFloor in expectedBuilding.floors {
                guard let actualFloor = actualFloorsByNumber[expectedFloor.number] else {
                    XCTFail("Missing floor \(expectedFloor.number) in '\(expectedBuilding.name)'")
                    continue
                }
                XCTAssertEqual(
                    actualFloor.meters.count, expectedFloor.meters.count,
                    "'\(expectedBuilding.name)' floor \(expectedFloor.number) meter count mismatch"
                )
            }
        }
    }

    func testSeedDataMatchesFixtureMeterNamesAndDescriptions() {
        let expectedMeters = fixture.buildings.flatMap { $0.floors }.flatMap { $0.meters }
        let actualMeters = seededBuildings.flatMap { $0.floors }.flatMap { $0.meters }

        XCTAssertEqual(Set(actualMeters.map { $0.name }), Set(expectedMeters.map { $0.name }))

        let actualDescriptionsByName = Dictionary(uniqueKeysWithValues: actualMeters.map { ($0.name, $0.meterDescription) })
        for expectedMeter in expectedMeters {
            XCTAssertEqual(actualDescriptionsByName[expectedMeter.name], expectedMeter.description)
        }
    }

    func testSeedDataMatchesFixtureReadingDatesAndKWh() {
        let actualMetersByName = Dictionary(uniqueKeysWithValues: seededBuildings.flatMap { $0.floors }.flatMap { $0.meters }.map { ($0.name, $0) })
        let today = Calendar.current.startOfDay(for: Date())

        for expectedMeter in fixture.buildings.flatMap({ $0.floors }).flatMap({ $0.meters }) {
            guard let actualMeter = actualMetersByName[expectedMeter.name] else {
                XCTFail("Missing meter '\(expectedMeter.name)'")
                continue
            }
            XCTAssertEqual(actualMeter.readings.count, expectedMeter.readings.count, "'\(expectedMeter.name)' reading count mismatch")

            let actualKWhByDate = Dictionary(uniqueKeysWithValues: actualMeter.readings.map { ($0.date, $0.kWh) })
            for expectedReading in expectedMeter.readings {
                let expectedDate = Calendar.current.date(byAdding: .day, value: -expectedReading.daysAgo, to: today) ?? today
                guard let actualKWh = actualKWhByDate[expectedDate] else {
                    XCTFail("'\(expectedMeter.name)' missing a reading dated \(expectedDate)")
                    continue
                }
                XCTAssertEqual(actualKWh, expectedReading.kWh, accuracy: 0.001)
            }
        }
    }

    /// `DataSeeder.seedData()` has no built-in guard against being called
    /// against a store that already has data — `HomeViewModel.seedData` is
    /// what decides whether to seed initial data or add readings, by
    /// checking building count first. This documents that assumption.
    func testSeedDataIsNotIdempotent() throws {
        try dataSeeder.seedData()
        let buildingsAfterSecondSeed = try repository.getBuildings()
        XCTAssertEqual(buildingsAfterSecondSeed.count, fixture.buildings.count * 2)
    }

    func testSeedMoreReadingsAddsExactlyOneReadingPerMeter() throws {
        let meterCountBefore = seededBuildings.reduce(0) { $0 + $1.totalMeterCount }
        let readingCountBefore = seededBuildings
            .flatMap { $0.floors }
            .flatMap { $0.meters }
            .reduce(0) { $0 + $1.readings.count }

        try dataSeeder.seedMoreReadings()

        let buildingsAfter = try repository.getBuildings()
        let meterCountAfter = buildingsAfter.reduce(0) { $0 + $1.totalMeterCount }
        let metersAfter = buildingsAfter.flatMap { $0.floors }.flatMap { $0.meters }
        let readingCountAfter = metersAfter.reduce(0) { $0 + $1.readings.count }

        XCTAssertEqual(meterCountAfter, meterCountBefore, "seedMoreReadings should not create or delete meters")
        XCTAssertEqual(readingCountAfter, readingCountBefore + meterCountBefore, "Expected exactly one new reading per existing meter")

        for meter in metersAfter {
            guard let latest = meter.sortedReadings.first else {
                XCTFail("Every meter should have at least one reading")
                continue
            }
            XCTAssertTrue(DataSeeder.additionalReadingKWhRange.contains(latest.kWh))
            XCTAssertEqual(latest.date, Calendar.current.startOfDay(for: Date()))
        }
    }
}
