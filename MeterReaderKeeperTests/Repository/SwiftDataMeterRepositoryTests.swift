//
//  SwiftDataMeterRepositoryTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26 (migration pilot) —
//  this was deliberately chosen as one of the two pilot files because it's
//  the trickiest case: it used to inherit shared seeded-store setup from
//  `SeededRepositoryTestCase`, an XCTestCase base class. Swift Testing
//  doesn't have that inheritance convention, so this now *composes* a
//  `SeededRepositoryFixture` (see TestSupport) instead of subclassing
//  anything. See that type's doc comment for why.
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Exercises `SwiftDataMeterRepository` against `DataSeeder`'s fixture
/// data. This was the first real check (compiler included) of whether the
/// Core Data -> SwiftData migration's `@Relationship(inverse:)` cascade
/// deletes, the `#Predicate` id lookups, and the manual `ModelContext`
/// queue confinement actually behave the way the migration assumed they
/// would — none of it had ever been built or run before these existed.
@Suite("SwiftDataMeterRepository")
struct SwiftDataMeterRepositoryTests {

    let fixture: SeededRepositoryFixture

    init() throws {
        fixture = try SeededRepositoryFixture()
    }

    @Test("getBuildings sorts by name")
    func getBuildingsSortsByName() {
        // `getBuildings()` sorts via a SwiftData `SortDescriptor(\.name)`,
        // which performs a natural/standard string comparison (embedded
        // digit runs compare numerically, the same behavior as Finder
        // filename sorting), not Swift's plain lexicographic `String.<`.
        // For names like "16 Pinkham" / "121 Seaport" those two orderings
        // disagree, so the expected order here must use
        // `localizedStandardCompare` too, or this assertion is just wrong
        // for any fixture with double- and triple-digit leading numbers.
        let names = fixture.seededBuildings.map { $0.name }
        let naturallySorted = names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        #expect(names == naturallySorted)
    }

    @Test("deleting a building removes it and cascades to its meters")
    func deleteBuildingRemovesItAndCascadesToItsMeters() throws {
        let buildingToDelete = try #require(fixture.seededBuildings.first)
        let orphanedMeterID = try #require(buildingToDelete.floors.flatMap({ $0.meters }).first?.id)

        try fixture.repository.deleteBuilding(id: buildingToDelete.id)

        let remainingBuildings = try fixture.repository.getBuildings()
        #expect(!remainingBuildings.contains { $0.id == buildingToDelete.id })
        #expect(remainingBuildings.count == fixture.seededBuildings.count - 1)

        // If the cascade rule didn't actually remove the meters under the
        // deleted building, this meter would still be findable.
        #expect(throws: (any Error).self) {
            try fixture.repository.addReading(MRKReadingInput(kWh: 100, date: Date(), meterID: orphanedMeterID))
        }
    }

    @Test("updating a meter's floor moves it and updates both sides of the relationship")
    func updateMeterMovesItBetweenFloorsAndUpdatesBothSides() throws {
        let building = try #require(fixture.seededBuildings.first(where: { $0.floors.count >= 2 }))
        let sourceFloor = try #require(building.floors.first(where: { !$0.meters.isEmpty }))
        let meter = try #require(sourceFloor.meters.first)
        let destinationFloor = try #require(building.floors.first(where: { $0.id != sourceFloor.id }))

        _ = try fixture.repository.updateMeter(
            id: meter.id,
            input: MRKMeterInput(
                name: meter.name,
                description: meter.meterDescription,
                imageData: meter.imageData,
                floorID: destinationFloor.id
            )
        )

        let refreshedBuilding = try #require(try fixture.repository.getBuildings().first(where: { $0.id == building.id }))
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
    func addReadingRejectsNegativeKWh() throws {
        let meter = try #require(fixture.seededBuildings.first?.floors.first?.meters.first)

        #expect(throws: (any Error).self) {
            try fixture.repository.addReading(MRKReadingInput(kWh: -1, date: Date(), meterID: meter.id))
        }
    }

    @Test("adding a reading rejects a future date")
    func addReadingRejectsFutureDate() throws {
        let meter = try #require(fixture.seededBuildings.first?.floors.first?.meters.first)
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        #expect(throws: (any Error).self) {
            try fixture.repository.addReading(MRKReadingInput(kWh: 100, date: tomorrow, meterID: meter.id))
        }
    }

    @Test("updating a reading changes its value and re-dates it to today")
    func updateReadingChangesValueAndRedatesToToday() throws {
        let meter = try #require(fixture.seededBuildings.first?.floors.first?.meters.first)
        let existingReading = try #require(meter.sortedReadings.first)

        let updated = try fixture.repository.updateReading(id: existingReading.id, kWh: 42)

        #expect(updated.kWh == 42)
        #expect(updated.date == Calendar.current.startOfDay(for: Date()))
    }

    @Test("operating on a missing ID throws not-found")
    func operatingOnAMissingIDThrowsNotFound() {
        #expect(throws: (any Error).self) { try fixture.repository.deleteBuilding(id: UUID()) }
        #expect(throws: (any Error).self) { try fixture.repository.deleteMeter(id: UUID()) }
        #expect(throws: (any Error).self) { try fixture.repository.updateReading(id: UUID(), kWh: 1) }
    }

    /// Unlike every other test here, this one deliberately ignores
    /// `fixture` and builds its own fresh, unseeded repository — merged in
    /// from the old `Meter_Reader_KeeperTests.swift` boilerplate-turned-
    /// smoke-test, which tested exactly this and had no home of its own
    /// once the "one file per tested class" convention was adopted.
    @Test("a fresh in-memory repository starts empty")
    func freshInMemoryRepositoryStartsEmpty() throws {
        let freshRepository = SwiftDataMeterRepository(inMemory: true)
        #expect(try freshRepository.getBuildings().count == 0)
    }
}
