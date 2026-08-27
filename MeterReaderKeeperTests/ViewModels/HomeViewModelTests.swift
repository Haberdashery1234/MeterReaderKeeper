//
//  HomeViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26. The completion-
//  handler-based exportData/seedData tests used to wait via an
//  XCTestExpectation-backed awaitExportData()/awaitSeedData() helper;
//  Swift Testing supports genuinely `async` @Test functions, so those
//  helpers now wrap the completion-based APIs with
//  withCheckedThrowingContinuation instead. Unlike the XCTest version,
//  there's no explicit per-call timeout — a hang here just hangs the test
//  (mirrors how Swift Testing tests are normally written; flagging the
//  behavior difference rather than silently dropping it).
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/HomeViewModel.swift`.
@Suite("HomeViewModel")
struct HomeViewModelTests {

    let repository: SwiftDataMeterRepository
    let viewModel: HomeViewModel

    init() {
        repository = SwiftDataMeterRepository(inMemory: true)
        viewModel = HomeViewModel(repository: repository)
    }

    // MARK: - takeReadingsOutcome

    @Test("takeReadingsOutcome returns .noBuildings with no buildings")
    func takeReadingsOutcomeWithNoBuildingsReturnsNoBuildings() {
        guard case .noBuildings = viewModel.takeReadingsOutcome() else {
            Issue.record("Expected .noBuildings")
            return
        }
    }

    @Test("takeReadingsOutcome returns .singleBuilding with one building")
    func takeReadingsOutcomeWithOneBuildingReturnsSingleBuilding() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "Only Building", numberOfFloors: 1, autoCreateFloors: true))

        guard case .singleBuilding(let returned) = viewModel.takeReadingsOutcome() else {
            Issue.record("Expected .singleBuilding")
            return
        }
        #expect(returned.id == building.id)
    }

    @Test("takeReadingsOutcome returns .chooseBuilding with multiple buildings")
    func takeReadingsOutcomeWithMultipleBuildingsReturnsChooseBuilding() throws {
        _ = try repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 1, autoCreateFloors: true))
        _ = try repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 1, autoCreateFloors: true))

        guard case .chooseBuilding(let returned) = viewModel.takeReadingsOutcome() else {
            Issue.record("Expected .chooseBuilding")
            return
        }
        #expect(returned.count == 2)
    }

    // MARK: - exportData

    @Test("exportData returns non-empty plist data")
    func exportDataReturnsNonEmptyPlistData() async throws {
        _ = try repository.addBuilding(MRKBuildingInput(name: "Export Building", numberOfFloors: 1, autoCreateFloors: true))

        let data = try await awaitExportData()

        #expect(!data.isEmpty)
    }

    #if DEBUG || TESTING
    // MARK: - seedData

    @Test("seedData seeds initial data when the store is empty")
    func seedDataSeedsInitialDataWhenStoreIsEmpty() async throws {
        let outcome = try await awaitSeedData()

        guard case .seededInitialData = outcome else {
            Issue.record("Expected .seededInitialData")
            return
        }
        #expect(!(try repository.getBuildings().isEmpty))
    }

    @Test("seedData adds more readings when buildings already exist")
    func seedDataAddsMoreReadingsWhenBuildingsAlreadyExist() async throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "Existing Building", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
        let readingCountBefore = meter.readings.count

        let outcome = try await awaitSeedData()

        guard case .addedMoreReadings = outcome else {
            Issue.record("Expected .addedMoreReadings")
            return
        }
        let refreshedMeter = try repository.getBuildings().first?.floors.first?.meters.first
        #expect(refreshedMeter?.readings.count == readingCountBefore + 1)
    }
    #endif

    // MARK: - Async helpers

    private func awaitExportData() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            viewModel.exportData { result in
                continuation.resume(with: result)
            }
        }
    }

    #if DEBUG || TESTING
    private func awaitSeedData() async throws -> HomeViewModel.SeedOutcome {
        try await withCheckedThrowingContinuation { continuation in
            viewModel.seedData { result in
                continuation.resume(with: result)
            }
        }
    }
    #endif
}
