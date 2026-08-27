//
//  ManagementViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/ManagementViewModel.swift`.
final class ManagementViewModelTests: XCTestCase {

    private var repository: SwiftDataMeterRepository!
    private var viewModel: ManagementViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = SwiftDataMeterRepository(inMemory: true)
        viewModel = ManagementViewModel(repository: repository)
    }

    override func tearDownWithError() throws {
        repository = nil
        viewModel = nil
        try super.tearDownWithError()
    }

    func testHasFloorsIsFalseBeforeLoading() {
        XCTAssertFalse(viewModel.hasFloors)
    }

    func testLoadDataWithNoBuildingsLeavesEverythingEmpty() {
        viewModel.loadData()

        XCTAssertTrue(viewModel.buildings.isEmpty)
        XCTAssertTrue(viewModel.floorItems.isEmpty)
        XCTAssertTrue(viewModel.meterItems.isEmpty)
        XCTAssertFalse(viewModel.hasFloors)
    }

    func testLoadDataFlattensFloorsAndMetersAcrossBuildings() throws {
        let buildingA = try repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 2, autoCreateFloors: true))
        let buildingB = try repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 1, autoCreateFloors: true))
        _ = try repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: buildingA.floors[0].id))
        _ = try repository.addMeter(MRKMeterInput(name: "M2", description: "", imageData: Data(), floorID: buildingB.floors[0].id))

        viewModel.loadData()

        XCTAssertEqual(viewModel.buildings.count, 2)
        XCTAssertEqual(viewModel.floorItems.count, 3) // 2 + 1 floors
        XCTAssertEqual(viewModel.meterItems.count, 2)
        XCTAssertTrue(viewModel.hasFloors)

        // Every FloorItem/MeterItem should carry its correct owning building/floor.
        for item in viewModel.floorItems {
            XCTAssertEqual(item.floor.buildingID, item.building.id)
        }
        for item in viewModel.meterItems {
            XCTAssertEqual(item.meter.floorID, item.floor.id)
            XCTAssertEqual(item.floor.buildingID, item.building.id)
        }
    }
}
