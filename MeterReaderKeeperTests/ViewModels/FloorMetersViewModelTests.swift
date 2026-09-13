//
//  FloorMetersViewModelTests.swift
//  MeterReaderKeeperTests
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/FloorMetersViewModel.swift`.
@MainActor @Suite("FloorMetersViewModel")
struct FloorMetersViewModelTests {

    let repository: SwiftDataMeterRepository

    init() {
        repository = SwiftDataMeterRepository(inMemory: true)
    }

    private func makeViewModel(building: MRKBuilding, floor: MRKFloor) -> FloorMetersViewModel {
        FloorMetersViewModel(repository: repository, floor: floor, building: building)
    }

    @Test("initial meters come from the floor passed in, sorted by name")
    func initialMetersComeFromFloorPassedIn() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "B1", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        _ = try await repository.addMeter(MRKMeterInput(name: "Zed", description: "", imageData: Data(), floorID: floor.id))
        _ = try await repository.addMeter(MRKMeterInput(name: "Alpha", description: "", imageData: Data(), floorID: floor.id))
        let refreshed = try await repository.getBuilding(id: building.id)

        let viewModel = makeViewModel(building: refreshed, floor: refreshed.floors[0])

        #expect(viewModel.meters.map { $0.name } == ["Alpha", "Zed"])
        #expect(viewModel.hasMeters)
    }

    @Test("hasMeters is false for a floor with no meters")
    func hasMetersIsFalseForEmptyFloor() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "B1", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = makeViewModel(building: building, floor: building.floors[0])

        #expect(!viewModel.hasMeters)
        #expect(viewModel.meters.isEmpty)
    }

    @Test("loadData picks up a meter added elsewhere after construction")
    func loadDataPicksUpMeterAddedElsewhere() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "B1", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let viewModel = makeViewModel(building: building, floor: floor)
        #expect(!viewModel.hasMeters)

        _ = try await repository.addMeter(MRKMeterInput(name: "New Meter", description: "", imageData: Data(), floorID: floor.id))
        await viewModel.loadData()

        #expect(viewModel.meters.map { $0.name } == ["New Meter"])
    }

    @Test("deleteMeter removes the meter and reloads")
    func deleteMeterRemovesAndReloads() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "B1", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try await repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
        let refreshed = try await repository.getBuilding(id: building.id)
        let viewModel = makeViewModel(building: refreshed, floor: refreshed.floors[0])
        #expect(viewModel.hasMeters)

        try await viewModel.deleteMeter(meter)

        #expect(viewModel.meters.isEmpty)
        let allBuildings = try await repository.getBuildings()
        #expect(allBuildings.first?.floors.first?.meters.isEmpty == true)
    }

    @Test("loadData leaves state as-is if the floor was deleted elsewhere")
    func loadDataLeavesStateIfFloorDeletedElsewhere() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "B1", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        _ = try await repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
        let refreshedBuilding = try await repository.getBuilding(id: building.id)
        let viewModel = makeViewModel(building: refreshedBuilding, floor: refreshedBuilding.floors[0])
        #expect(viewModel.hasMeters)

        try await repository.deleteFloor(id: floor.id)
        await viewModel.loadData()

        // Repository lookup for the now-missing floor fails, so loadData
        // is a no-op rather than clearing state out from under the view.
        #expect(viewModel.hasMeters)
        #expect(viewModel.floor.id == floor.id)
    }
}
