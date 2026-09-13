//
//  SwiftDataMeterRepositoryTests.swift
//  MeterReaderKeeperTests
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Exercises `SwiftDataMeterRepository` against `DataSeeder`'s fixture
/// data — cascade deletes, id lookups, and basic CRUD through the
/// `@ModelActor`-backed repository.
@Suite("SwiftDataMeterRepository")
struct SwiftDataMeterRepositoryTests {

    let fixture: SeededRepositoryFixture

    init() async throws {
        fixture = try await SeededRepositoryFixture()
    }

    @Test("getBuildings sorts by name")
    func getBuildingsSortsByName() {
        // `getBuildings()` sorts using a natural/standard string comparison
        // (`SortDescriptor(\.name)`), not plain lexicographic ordering, so
        // the expected order here must also use `localizedStandardCompare`.
        let names = fixture.seededBuildings.map { $0.name }
        let naturallySorted = names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        #expect(names == naturallySorted)
    }

    @Test("deleting a building removes it and cascades to its meters")
    func deleteBuildingRemovesItAndCascadesToItsMeters() async throws {
        let buildingToDelete = try #require(fixture.seededBuildings.first)
        let orphanedMeterID = try #require(buildingToDelete.floors.flatMap({ $0.meters }).first?.id)

        try await fixture.repository.deleteBuilding(id: buildingToDelete.id)

        let remainingBuildings = try await fixture.repository.getBuildings()
        #expect(!remainingBuildings.contains { $0.id == buildingToDelete.id })
        #expect(remainingBuildings.count == fixture.seededBuildings.count - 1)

        // If the cascade rule didn't actually remove the meters under the
        // deleted building, this meter would still be findable.
        await #expect(throws: (any Error).self) {
            try await fixture.repository.addReading(MRKReadingInput(kWh: 100, date: Date(), meterID: orphanedMeterID))
        }
    }

    @Test("deleting a floor removes it and cascades to its meters")
    func deleteFloorRemovesItAndCascadesToItsMeters() async throws {
        let buildingWithMeters = try #require(fixture.seededBuildings.first { building in
            building.floors.contains { !$0.meters.isEmpty }
        })
        let floorToDelete = try #require(buildingWithMeters.floors.first { !$0.meters.isEmpty })
        let orphanedMeterID = try #require(floorToDelete.meters.first?.id)

        try await fixture.repository.deleteFloor(id: floorToDelete.id)

        let refreshedBuilding = try await fixture.repository.getBuilding(id: buildingWithMeters.id)
        #expect(!refreshedBuilding.floors.contains { $0.id == floorToDelete.id })
        #expect(refreshedBuilding.floors.count == buildingWithMeters.floors.count - 1)

        // If the cascade rule didn't actually remove the meters under the
        // deleted floor, this meter would still be findable.
        await #expect(throws: (any Error).self) {
            try await fixture.repository.addReading(MRKReadingInput(kWh: 100, date: Date(), meterID: orphanedMeterID))
        }
    }

    @Test("updating a meter's floor moves it and updates both sides of the relationship")
    func updateMeterMovesItBetweenFloorsAndUpdatesBothSides() async throws {
        let building = try #require(fixture.seededBuildings.first(where: { $0.floors.count >= 2 }))
        let sourceFloor = try #require(building.floors.first(where: { !$0.meters.isEmpty }))
        let meter = try #require(sourceFloor.meters.first)
        let destinationFloor = try #require(building.floors.first(where: { $0.id != sourceFloor.id }))

        _ = try await fixture.repository.updateMeter(
            id: meter.id,
            input: MRKMeterInput(
                name: meter.name,
                description: meter.meterDescription,
                imageData: meter.imageData,
                floorID: destinationFloor.id
            )
        )

        let refreshedBuilding = try #require(try await fixture.repository.getBuildings().first(where: { $0.id == building.id }))
        let refreshedSourceFloor = refreshedBuilding.floors.first { $0.id == sourceFloor.id }
        let refreshedDestinationFloor = refreshedBuilding.floors.first { $0.id == destinationFloor.id }

        #expect(
            !(refreshedSourceFloor?.meters.contains { $0.id == meter.id } ?? true),
            "Meter should no longer be reachable from its original floor"
        )
        #expect(
            refreshedDestinationFloor?.meters.contains { $0.id == meter.id } ?? false,
            "Meter should now be reachable from the destination floor"
        )
    }

    @Test("adding a reading rejects negative kWh")
    func addReadingRejectsNegativeKWh() async throws {
        let meter = try #require(fixture.seededBuildings.first?.floors.first?.meters.first)

        await #expect(throws: (any Error).self) {
            try await fixture.repository.addReading(MRKReadingInput(kWh: -1, date: Date(), meterID: meter.id))
        }
    }

    @Test("adding a reading rejects a future date")
    func addReadingRejectsFutureDate() async throws {
        let meter = try #require(fixture.seededBuildings.first?.floors.first?.meters.first)
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        await #expect(throws: (any Error).self) {
            try await fixture.repository.addReading(MRKReadingInput(kWh: 100, date: tomorrow, meterID: meter.id))
        }
    }

    @Test("updating a reading changes its value and re-dates it to today")
    func updateReadingChangesValueAndRedatesToToday() async throws {
        let meter = try #require(fixture.seededBuildings.first?.floors.first?.meters.first)
        let existingReading = try #require(meter.sortedReadings.first)

        let updated = try await fixture.repository.updateReading(id: existingReading.id, kWh: 42)

        #expect(updated.kWh == 42)
        #expect(updated.date == Calendar.current.startOfDay(for: Date()))
    }

    @Test("operating on a missing ID throws not-found")
    func operatingOnAMissingIDThrowsNotFound() async {
        await #expect(throws: (any Error).self) { try await fixture.repository.deleteBuilding(id: UUID()) }
        await #expect(throws: (any Error).self) { try await fixture.repository.deleteFloor(id: UUID()) }
        await #expect(throws: (any Error).self) { try await fixture.repository.deleteMeter(id: UUID()) }
        await #expect(throws: (any Error).self) { try await fixture.repository.updateReading(id: UUID(), kWh: 1) }
    }

    /// Unlike every other test here, this one builds its own fresh,
    /// unseeded repository instead of using `fixture`.
    @Test("a fresh in-memory repository starts empty")
    func freshInMemoryRepositoryStartsEmpty() async throws {
        let freshRepository = SwiftDataMeterRepository(inMemory: true)
        #expect(try await freshRepository.getBuildings().count == 0)
    }
}
