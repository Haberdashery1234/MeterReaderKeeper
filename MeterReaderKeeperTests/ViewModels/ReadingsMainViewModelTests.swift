//
//  ReadingsMainViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//  Converted to async throws on 8/27/26 when ReadingsMainViewModel.refreshBuilding()/
//  getCSVData() became async (see "Proper concurrency" migration note).
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/ReadingsMainViewModel.swift`.
@Suite("ReadingsMainViewModel")
struct ReadingsMainViewModelTests {

    let repository: SwiftDataMeterRepository

    init() {
        repository = SwiftDataMeterRepository(inMemory: true)
    }

    @Test("init selects the first floor and its meters")
    func initSelectsFirstFloorAndItsMeters() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let floor1 = building.sortedFloors[0]
        _ = try await repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor1.id))

        // Re-fetch the building to get the updated version with the meter included
        let refreshedBuilding = try await repository.getBuilding(id: building.id)
        let viewModel = ReadingsMainViewModel(repository: repository, building: refreshedBuilding)

        #expect(viewModel.floors.count == 3)
        #expect(viewModel.floor?.id == floor1.id)
        #expect(viewModel.meters.count == 1)
    }

    @Test("selectFloor at a valid row updates the floor and meters")
    func selectFloorAtValidRowUpdatesFloorAndMeters() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 2, autoCreateFloors: true))
        let floor2 = building.sortedFloors[1]
        _ = try await repository.addMeter(MRKMeterInput(name: "M2", description: "", imageData: Data(), floorID: floor2.id))

        // Re-fetch the building to get the updated version with the meter included
        let refreshedBuilding = try await repository.getBuilding(id: building.id)
        let viewModel = ReadingsMainViewModel(repository: repository, building: refreshedBuilding)

        let selected = viewModel.selectFloor(at: 1)

        #expect(selected?.id == floor2.id)
        #expect(viewModel.floor?.id == floor2.id)
        #expect(viewModel.meters.count == 1)
    }

    @Test("selectFloor at an out-of-bounds row returns nil")
    func selectFloorAtOutOfBoundsRowReturnsNil() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = ReadingsMainViewModel(repository: repository, building: building)

        #expect(viewModel.selectFloor(at: 5) == nil)
    }

    @Test("refreshBuilding picks up newly added floors and preserves the selected floor")
    func refreshBuildingPicksUpNewlyAddedFloorsAndPreservesSelectedFloor() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = ReadingsMainViewModel(repository: repository, building: building)
        let originalFloorID = viewModel.floor?.id

        _ = try await repository.addFloor(MRKFloorInput(number: 2, mapImageData: Data(), buildingID: building.id))
        await viewModel.refreshBuilding()

        #expect(viewModel.floors.count == 2)
        #expect(viewModel.floor?.id == originalFloorID)
    }

    @Test("refreshBuilding falls back to the first floor when the selected floor no longer exists")
    func refreshBuildingFallsBackToFirstFloorWhenSelectedFloorNoLongerExists() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        // There's no way to delete a single floor through the public API
        // today (only whole buildings cascade-delete), so the "selected
        // floor no longer exists on refresh" branch is simulated directly:
        // hand the view model a building snapshot whose one floor has an id
        // that was never actually persisted.
        let phantomFloor = MRKFloor(id: UUID(), number: 99, mapImageData: Data(), buildingID: building.id, meters: [])
        let buildingWithPhantomFloor = MRKBuilding(id: building.id, name: building.name, floors: [phantomFloor])
        let viewModel = ReadingsMainViewModel(repository: repository, building: buildingWithPhantomFloor)
        #expect(viewModel.floor?.id == phantomFloor.id)

        await viewModel.refreshBuilding()

        #expect(viewModel.floor?.id == building.floors[0].id)
    }

    @Test("readingRoute returns .add when no reading exists for today")
    func readingRouteReturnsAddWhenNoReadingExistsForToday() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try await repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
        let refreshedBuilding = try await repository.getBuilding(id: building.id)
        let viewModel = ReadingsMainViewModel(repository: repository, building: refreshedBuilding)

        guard case .add(let routedMeter, let routedFloor, let routedBuilding) = viewModel.readingRoute(forMeterAt: 0) else {
            Issue.record("Expected .add")
            return
        }
        #expect(routedMeter.id == meter.id)
        #expect(routedFloor.id == floor.id)
        #expect(routedBuilding.id == building.id)
    }

    @Test("readingRoute returns .edit when a reading already exists for today")
    func readingRouteReturnsEditWhenAReadingAlreadyExistsForToday() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try await repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
        let today = Calendar.current.startOfDay(for: Date())
        let todaysReading = try await repository.addReading(MRKReadingInput(kWh: 42, date: today, meterID: meter.id))

        let refreshedBuilding = try await repository.getBuilding(id: building.id)
        let viewModel = ReadingsMainViewModel(repository: repository, building: refreshedBuilding)

        guard case .edit(let routedReading, let routedMeter, _, _) = viewModel.readingRoute(forMeterAt: 0) else {
            Issue.record("Expected .edit")
            return
        }
        #expect(routedReading.id == todaysReading.id)
        #expect(routedMeter.id == meter.id)
    }

    @Test("readingRoute returns nil for an out-of-bounds row")
    func readingRouteReturnsNilForOutOfBoundsRow() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = ReadingsMainViewModel(repository: repository, building: building)

        #expect(viewModel.readingRoute(forMeterAt: 0) == nil) // no meters on this floor yet
    }

    @Test("getCSVData returns data")
    func getCSVDataReturnsData() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = ReadingsMainViewModel(repository: repository, building: building)

        let data = try await viewModel.getCSVData()

        #expect(!data.isEmpty)
    }
}
