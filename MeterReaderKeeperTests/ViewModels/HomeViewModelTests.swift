//
//  HomeViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//  Simplified on 8/27/26 when HomeViewModel's exportData/seedData dropped
//  their completion-handler signatures for plain async throws (see
//  "Proper concurrency" migration note) — the withCheckedThrowingContinuation
//  bridging helpers this file used are gone; tests just `try await` the
//  methods directly now.
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/HomeViewModel.swift`.
@MainActor @Suite("HomeViewModel")
struct HomeViewModelTests {

    let repository: SwiftDataMeterRepository
    let viewModel: HomeViewModel

    init() {
        repository = SwiftDataMeterRepository(inMemory: true)
        viewModel = HomeViewModel(repository: repository)
    }

    // MARK: - takeReadingsOutcome

    @Test("takeReadingsOutcome returns .noBuildings with no buildings")
    func takeReadingsOutcomeWithNoBuildingsReturnsNoBuildings() async {
        guard case .noBuildings = await viewModel.takeReadingsOutcome() else {
            Issue.record("Expected .noBuildings")
            return
        }
    }

    @Test("takeReadingsOutcome returns .singleBuilding with one building")
    func takeReadingsOutcomeWithOneBuildingReturnsSingleBuilding() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "Only Building", numberOfFloors: 1, autoCreateFloors: true))

        guard case .singleBuilding(let returned) = await viewModel.takeReadingsOutcome() else {
            Issue.record("Expected .singleBuilding")
            return
        }
        #expect(returned.id == building.id)
    }

    @Test("takeReadingsOutcome returns .chooseBuilding with multiple buildings")
    func takeReadingsOutcomeWithMultipleBuildingsReturnsChooseBuilding() async throws {
        _ = try await repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 1, autoCreateFloors: true))
        _ = try await repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 1, autoCreateFloors: true))

        guard case .chooseBuilding(let returned) = await viewModel.takeReadingsOutcome() else {
            Issue.record("Expected .chooseBuilding")
            return
        }
        #expect(returned.count == 2)
    }

    // MARK: - exportData

    @Test("exportData returns non-empty plist data")
    func exportDataReturnsNonEmptyPlistData() async throws {
        _ = try await repository.addBuilding(MRKBuildingInput(name: "Export Building", numberOfFloors: 1, autoCreateFloors: true))

        let data = try await viewModel.exportData()

        #expect(!data.isEmpty)
    }

    #if DEBUG || TESTING
    // MARK: - seedData

    @Test("seedData seeds initial data when the store is empty")
    func seedDataSeedsInitialDataWhenStoreIsEmpty() async throws {
        let outcome = try await viewModel.seedData()

        guard case .seededInitialData = outcome else {
            Issue.record("Expected .seededInitialData")
            return
        }
        #expect(!(try await repository.getBuildings().isEmpty))
    }

    @Test("seedData adds more readings when buildings already exist")
    func seedDataAddsMoreReadingsWhenBuildingsAlreadyExist() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "Existing Building", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try await repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
        let readingCountBefore = meter.readings.count

        let outcome = try await viewModel.seedData()

        guard case .addedMoreReadings = outcome else {
            Issue.record("Expected .addedMoreReadings")
            return
        }
        let refreshedMeter = try await repository.getBuildings().first?.floors.first?.meters.first
        #expect(refreshedMeter?.readings.count == readingCountBefore + 1)
    }
    #endif
}
