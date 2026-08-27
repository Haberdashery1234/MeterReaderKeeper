//
//  ManagementViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/ManagementViewModel.swift`.
@Suite("ManagementViewModel")
struct ManagementViewModelTests {

    let repository: SwiftDataMeterRepository
    let viewModel: ManagementViewModel

    init() {
        repository = SwiftDataMeterRepository(inMemory: true)
        viewModel = ManagementViewModel(repository: repository)
    }

    @Test("hasFloors is false before loading")
    func hasFloorsIsFalseBeforeLoading() {
        #expect(!viewModel.hasFloors)
    }

    @Test("loadData with no buildings leaves everything empty")
    func loadDataWithNoBuildingsLeavesEverythingEmpty() {
        viewModel.loadData()

        #expect(viewModel.buildings.isEmpty)
        #expect(viewModel.floorItems.isEmpty)
        #expect(viewModel.meterItems.isEmpty)
        #expect(!viewModel.hasFloors)
    }

    @Test("loadData flattens floors and meters across buildings")
    func loadDataFlattensFloorsAndMetersAcrossBuildings() throws {
        let buildingA = try repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 2, autoCreateFloors: true))
        let buildingB = try repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 1, autoCreateFloors: true))
        _ = try repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: buildingA.floors[0].id))
        _ = try repository.addMeter(MRKMeterInput(name: "M2", description: "", imageData: Data(), floorID: buildingB.floors[0].id))

        viewModel.loadData()

        #expect(viewModel.buildings.count == 2)
        #expect(viewModel.floorItems.count == 3) // 2 + 1 floors
        #expect(viewModel.meterItems.count == 2)
        #expect(viewModel.hasFloors)

        // Every FloorItem/MeterItem should carry its correct owning building/floor.
        for item in viewModel.floorItems {
            #expect(item.floor.buildingID == item.building.id)
        }
        for item in viewModel.meterItems {
            #expect(item.meter.floorID == item.floor.id)
            #expect(item.floor.buildingID == item.building.id)
        }
    }
}
