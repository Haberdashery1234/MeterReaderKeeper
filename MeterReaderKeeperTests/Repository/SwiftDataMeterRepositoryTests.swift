//
//  SwiftDataMeterRepositoryTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Exercises `SwiftDataMeterRepository` against `DataSeeder`'s fixture
/// data. This was the first real check (compiler included) of whether the
/// Core Data -> SwiftData migration's `@Relationship(inverse:)` cascade
/// deletes, the `#Predicate` id lookups, and the manual `ModelContext`
/// queue confinement actually behave the way the migration assumed they
/// would — none of it had ever been built or run before these existed.
final class SwiftDataMeterRepositoryTests: SeededRepositoryTestCase {

    func testGetBuildingsSortsByName() {
        let names = seededBuildings.map { $0.name }
        XCTAssertEqual(names, names.sorted())
    }

    func testDeleteBuildingRemovesItAndCascadesToItsMeters() throws {
        guard let buildingToDelete = seededBuildings.first,
              let orphanedMeterID = buildingToDelete.floors.flatMap({ $0.meters }).first?.id else {
            return XCTFail("Expected a seeded building with at least one meter")
        }

        try repository.deleteBuilding(id: buildingToDelete.id)

        let remainingBuildings = try repository.getBuildings()
        XCTAssertFalse(remainingBuildings.contains { $0.id == buildingToDelete.id })
        XCTAssertEqual(remainingBuildings.count, seededBuildings.count - 1)

        // If the cascade rule didn't actually remove the meters under the
        // deleted building, this meter would still be findable.
        XCTAssertThrowsError(
            try repository.addReading(MRKReadingInput(kWh: 100, date: Date(), meterID: orphanedMeterID))
        )
    }

    func testUpdateMeterMovesItBetweenFloorsAndUpdatesBothSides() throws {
        guard let building = seededBuildings.first(where: { $0.floors.count >= 2 }),
              let sourceFloor = building.floors.first(where: { !$0.meters.isEmpty }),
              let meter = sourceFloor.meters.first,
              let destinationFloor = building.floors.first(where: { $0.id != sourceFloor.id }) else {
            return XCTFail("Expected a seeded building with 2+ floors and at least one meter")
        }

        _ = try repository.updateMeter(
            id: meter.id,
            input: MRKMeterInput(
                name: meter.name,
                description: meter.meterDescription,
                imageData: meter.imageData,
                floorID: destinationFloor.id
            )
        )

        guard let refreshedBuilding = try repository.getBuildings().first(where: { $0.id == building.id }) else {
            return XCTFail("Building disappeared after updating one of its meters")
        }
        let refreshedSourceFloor = refreshedBuilding.floors.first { $0.id == sourceFloor.id }
        let refreshedDestinationFloor = refreshedBuilding.floors.first { $0.id == destinationFloor.id }

        XCTAssertFalse(
            refreshedSourceFloor?.meters.contains { $0.id == meter.id } ?? true,
            "Meter should no longer be reachable from its original floor"
        )
        XCTAssertTrue(
            refreshedDestinationFloor?.meters.contains { $0.id == meter.id } ?? false,
            "Meter should now be reachable from the destination floor"
        )
    }

    func testAddReadingRejectsNegativeKWh() throws {
        guard let meter = seededBuildings.first?.floors.first?.meters.first else {
            return XCTFail("Expected at least one seeded meter")
        }

        XCTAssertThrowsError(
            try repository.addReading(MRKReadingInput(kWh: -1, date: Date(), meterID: meter.id))
        )
    }

    func testAddReadingRejectsFutureDate() throws {
        guard let meter = seededBuildings.first?.floors.first?.meters.first else {
            return XCTFail("Expected at least one seeded meter")
        }
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        XCTAssertThrowsError(
            try repository.addReading(MRKReadingInput(kWh: 100, date: tomorrow, meterID: meter.id))
        )
    }

    func testUpdateReadingChangesValueAndRedatesToToday() throws {
        guard let meter = seededBuildings.first?.floors.first?.meters.first,
              let existingReading = meter.sortedReadings.first else {
            return XCTFail("Expected at least one seeded reading")
        }

        let updated = try repository.updateReading(id: existingReading.id, kWh: 42)

        XCTAssertEqual(updated.kWh, 42)
        XCTAssertEqual(updated.date, Calendar.current.startOfDay(for: Date()))
    }

    func testOperatingOnAMissingIDThrowsNotFound() {
        XCTAssertThrowsError(try repository.deleteBuilding(id: UUID()))
        XCTAssertThrowsError(try repository.deleteMeter(id: UUID()))
        XCTAssertThrowsError(try repository.updateReading(id: UUID(), kWh: 1))
    }
}
