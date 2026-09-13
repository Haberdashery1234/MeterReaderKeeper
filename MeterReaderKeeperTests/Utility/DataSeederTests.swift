//
//  DataSeederTests.swift
//  MeterReaderKeeperTests
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Verifies `DataSeeder.seedData()` reproduces `SeedFixture.json` exactly
/// — building/floor/meter shape, meter names and descriptions, and every
/// reading's date and kWh value — loaded from the same JSON file
/// `DataSeeder` itself reads (see `FixtureLoader`).
@Suite("DataSeeder")
struct DataSeederTests {

    let fixture: SeededRepositoryFixture
    let expectedFixture: SeedFixture

    init() async throws {
        fixture = try await SeededRepositoryFixture()
        // Letting a load failure (missing/malformed SeedFixture.json)
        // propagate straight out of init() fails every test in this suite
        // clearly.
        expectedFixture = try FixtureLoader.loadSeedFixture(named: SeedFixtureName.small)
    }

    @Test("seedData matches the fixture's building and floor shape")
    func seedDataMatchesFixtureBuildingAndFloorShape() {
        #expect(fixture.seededBuildings.count == expectedFixture.buildings.count)

        let seededByName = Dictionary(uniqueKeysWithValues: fixture.seededBuildings.map { ($0.name, $0) })

        for expectedBuilding in expectedFixture.buildings {
            guard let actualBuilding = seededByName[expectedBuilding.name] else {
                Issue.record("Missing seeded building '\(expectedBuilding.name)'")
                continue
            }
            #expect(
                actualBuilding.floors.count == expectedBuilding.floors.count,
                "'\(expectedBuilding.name)' floor count mismatch"
            )

            let actualFloorsByNumber = Dictionary(uniqueKeysWithValues: actualBuilding.floors.map { ($0.number, $0) })
            for expectedFloor in expectedBuilding.floors {
                guard let actualFloor = actualFloorsByNumber[expectedFloor.number] else {
                    Issue.record("Missing floor \(expectedFloor.number) in '\(expectedBuilding.name)'")
                    continue
                }
                #expect(
                    actualFloor.meters.count == expectedFloor.meters.count,
                    "'\(expectedBuilding.name)' floor \(expectedFloor.number) meter count mismatch"
                )
            }
        }
    }

    @Test("seedData matches the fixture's meter names and descriptions")
    func seedDataMatchesFixtureMeterNamesAndDescriptions() {
        let expectedMeters = expectedFixture.buildings.flatMap { $0.floors }.flatMap { $0.meters }
        let actualMeters = fixture.seededBuildings.flatMap { $0.floors }.flatMap { $0.meters }

        #expect(Set(actualMeters.map { $0.name }) == Set(expectedMeters.map { $0.name }))

        let actualDescriptionsByName = Dictionary(uniqueKeysWithValues: actualMeters.map { ($0.name, $0.meterDescription) })
        for expectedMeter in expectedMeters {
            #expect(actualDescriptionsByName[expectedMeter.name] == expectedMeter.description)
        }
    }

    @Test("seedData matches the fixture's reading dates and kWh values")
    func seedDataMatchesFixtureReadingDatesAndKWh() {
        let actualMetersByName = Dictionary(uniqueKeysWithValues: fixture.seededBuildings.flatMap { $0.floors }.flatMap { $0.meters }.map { ($0.name, $0) })
        let today = Calendar.current.startOfDay(for: Date())

        for expectedMeter in expectedFixture.buildings.flatMap({ $0.floors }).flatMap({ $0.meters }) {
            guard let actualMeter = actualMetersByName[expectedMeter.name] else {
                Issue.record("Missing meter '\(expectedMeter.name)'")
                continue
            }
            #expect(
                actualMeter.readings.count == expectedMeter.readings.count,
                "'\(expectedMeter.name)' reading count mismatch"
            )

            let actualKWhByDate = Dictionary(uniqueKeysWithValues: actualMeter.readings.map { ($0.date, $0.kWh) })
            for expectedReading in expectedMeter.readings {
                let expectedDate = Calendar.current.date(byAdding: .day, value: -expectedReading.daysAgo, to: today) ?? today
                guard let actualKWh = actualKWhByDate[expectedDate] else {
                    Issue.record("'\(expectedMeter.name)' missing a reading dated \(expectedDate)")
                    continue
                }
                // No built-in tolerance assertion, so the comparison is
                // done manually within a small margin.
                #expect(abs(actualKWh - expectedReading.kWh) <= 0.001)
            }
        }
    }

    /// `DataSeeder.seedData()` has no built-in guard against being called
    /// against a store that already has data — `HomeViewModel.seedData()` is
    /// what decides whether to seed initial data or add readings, by
    /// checking building count first. This documents that assumption.
    @Test("seedData is not idempotent")
    func seedDataIsNotIdempotent() async throws {
        try await fixture.dataSeeder.seedData(fixtureName: SeedFixtureName.small)
        let buildingsAfterSecondSeed = try await fixture.repository.getBuildings()
        #expect(buildingsAfterSecondSeed.count == expectedFixture.buildings.count * 2)
    }
}
