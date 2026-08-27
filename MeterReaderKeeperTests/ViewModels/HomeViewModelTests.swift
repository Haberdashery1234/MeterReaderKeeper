//
//  HomeViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/HomeViewModel.swift`.
final class HomeViewModelTests: XCTestCase {

    private var repository: SwiftDataMeterRepository!
    private var viewModel: HomeViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = SwiftDataMeterRepository(inMemory: true)
        viewModel = HomeViewModel(repository: repository)
    }

    override func tearDownWithError() throws {
        repository = nil
        viewModel = nil
        try super.tearDownWithError()
    }

    // MARK: - takeReadingsOutcome

    func testTakeReadingsOutcomeWithNoBuildingsReturnsNoBuildings() {
        guard case .noBuildings = viewModel.takeReadingsOutcome() else {
            return XCTFail("Expected .noBuildings")
        }
    }

    func testTakeReadingsOutcomeWithOneBuildingReturnsSingleBuilding() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "Only Building", numberOfFloors: 1, autoCreateFloors: true))

        guard case .singleBuilding(let returned) = viewModel.takeReadingsOutcome() else {
            return XCTFail("Expected .singleBuilding")
        }
        XCTAssertEqual(returned.id, building.id)
    }

    func testTakeReadingsOutcomeWithMultipleBuildingsReturnsChooseBuilding() throws {
        _ = try repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 1, autoCreateFloors: true))
        _ = try repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 1, autoCreateFloors: true))

        guard case .chooseBuilding(let returned) = viewModel.takeReadingsOutcome() else {
            return XCTFail("Expected .chooseBuilding")
        }
        XCTAssertEqual(returned.count, 2)
    }

    // MARK: - exportData

    func testExportDataReturnsNonEmptyPlistData() throws {
        _ = try repository.addBuilding(MRKBuildingInput(name: "Export Building", numberOfFloors: 1, autoCreateFloors: true))

        let data = try awaitExportData()

        XCTAssertFalse(data.isEmpty)
    }

    #if DEBUG || TESTING
    // MARK: - seedData

    func testSeedDataSeedsInitialDataWhenStoreIsEmpty() throws {
        let outcome = try awaitSeedData()

        guard case .seededInitialData = outcome else {
            return XCTFail("Expected .seededInitialData")
        }
        XCTAssertFalse(try repository.getBuildings().isEmpty)
    }

    func testSeedDataAddsMoreReadingsWhenBuildingsAlreadyExist() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "Existing Building", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
        let readingCountBefore = meter.readings.count

        let outcome = try awaitSeedData()

        guard case .addedMoreReadings = outcome else {
            return XCTFail("Expected .addedMoreReadings")
        }
        let refreshedMeter = try repository.getBuildings().first?.floors.first?.meters.first
        XCTAssertEqual(refreshedMeter?.readings.count, readingCountBefore + 1)
    }
    #endif

    // MARK: - Async helpers

    private func awaitExportData(timeout: TimeInterval = 10) throws -> Data {
        let completed = expectation(description: "exportData completes")
        var result: Result<Data, Error>!
        viewModel.exportData { completionResult in
            result = completionResult
            completed.fulfill()
        }
        wait(for: [completed], timeout: timeout)
        return try result.get()
    }

    #if DEBUG || TESTING
    private func awaitSeedData(timeout: TimeInterval = 30) throws -> HomeViewModel.SeedOutcome {
        let completed = expectation(description: "seedData completes")
        var result: Result<HomeViewModel.SeedOutcome, Error>!
        viewModel.seedData { completionResult in
            result = completionResult
            completed.fulfill()
        }
        wait(for: [completed], timeout: timeout)
        return try result.get()
    }
    #endif
}
