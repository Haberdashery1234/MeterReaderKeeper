//
//  ReadingsMainViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/ReadingsMainViewModel.swift`.
final class ReadingsMainViewModelTests: XCTestCase {

    private var repository: SwiftDataMeterRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = SwiftDataMeterRepository(inMemory: true)
    }

    override func tearDownWithError() throws {
        repository = nil
        try super.tearDownWithError()
    }

    func testInitSelectsFirstFloorAndItsMeters() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let floor1 = building.sortedFloors[0]
        _ = try repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor1.id))

        // Re-fetch the building to get the updated version with the meter included
        let refreshedBuilding = try repository.getBuilding(id: building.id)
        let viewModel = ReadingsMainViewModel(repository: repository, building: refreshedBuilding)

        XCTAssertEqual(viewModel.floors.count, 3)
        XCTAssertEqual(viewModel.floor?.id, floor1.id)
        XCTAssertEqual(viewModel.meters.count, 1)
    }

    func testSelectFloorAtValidRowUpdatesFloorAndMeters() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 2, autoCreateFloors: true))
        let floor2 = building.sortedFloors[1]
        _ = try repository.addMeter(MRKMeterInput(name: "M2", description: "", imageData: Data(), floorID: floor2.id))
        
        // Re-fetch the building to get the updated version with the meter included
        let refreshedBuilding = try repository.getBuilding(id: building.id)
        let viewModel = ReadingsMainViewModel(repository: repository, building: refreshedBuilding)

        let selected = viewModel.selectFloor(at: 1)

        XCTAssertEqual(selected?.id, floor2.id)
        XCTAssertEqual(viewModel.floor?.id, floor2.id)
        XCTAssertEqual(viewModel.meters.count, 1)
    }

    func testSelectFloorAtOutOfBoundsRowReturnsNil() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = ReadingsMainViewModel(repository: repository, building: building)

        XCTAssertNil(viewModel.selectFloor(at: 5))
    }

    func testRefreshBuildingPicksUpNewlyAddedFloorsAndPreservesSelectedFloor() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = ReadingsMainViewModel(repository: repository, building: building)
        let originalFloorID = viewModel.floor?.id

        _ = try repository.addFloor(MRKFloorInput(number: 2, mapImageData: Data(), buildingID: building.id))
        viewModel.refreshBuilding()

        XCTAssertEqual(viewModel.floors.count, 2)
        XCTAssertEqual(viewModel.floor?.id, originalFloorID)
    }

    func testRefreshBuildingFallsBackToFirstFloorWhenSelectedFloorNoLongerExists() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        // There's no way to delete a single floor through the public API
        // today (only whole buildings cascade-delete), so the "selected
        // floor no longer exists on refresh" branch is simulated directly:
        // hand the view model a building snapshot whose one floor has an id
        // that was never actually persisted.
        let phantomFloor = MRKFloor(id: UUID(), number: 99, mapImageData: Data(), buildingID: building.id, meters: [])
        let buildingWithPhantomFloor = MRKBuilding(id: building.id, name: building.name, floors: [phantomFloor])
        let viewModel = ReadingsMainViewModel(repository: repository, building: buildingWithPhantomFloor)
        XCTAssertEqual(viewModel.floor?.id, phantomFloor.id)

        viewModel.refreshBuilding()

        XCTAssertEqual(viewModel.floor?.id, building.floors[0].id)
    }

    func testReadingRouteReturnsAddWhenNoReadingExistsForToday() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
        let refreshedBuilding = try repository.getBuilding(id: building.id)
        let viewModel = ReadingsMainViewModel(repository: repository, building: refreshedBuilding)

        guard case .add(let routedMeter, let routedFloor, let routedBuilding) = viewModel.readingRoute(forMeterAt: 0) else {
            return XCTFail("Expected .add")
        }
        XCTAssertEqual(routedMeter.id, meter.id)
        XCTAssertEqual(routedFloor.id, floor.id)
        XCTAssertEqual(routedBuilding.id, building.id)
    }

    func testReadingRouteReturnsEditWhenAReadingAlreadyExistsForToday() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
        let today = Calendar.current.startOfDay(for: Date())
        let todaysReading = try repository.addReading(MRKReadingInput(kWh: 42, date: today, meterID: meter.id))

        let refreshedBuilding = try repository.getBuilding(id: building.id)
        let viewModel = ReadingsMainViewModel(repository: repository, building: refreshedBuilding)

        guard case .edit(let routedReading, let routedMeter, _, _) = viewModel.readingRoute(forMeterAt: 0) else {
            return XCTFail("Expected .edit")
        }
        XCTAssertEqual(routedReading.id, todaysReading.id)
        XCTAssertEqual(routedMeter.id, meter.id)
    }

    func testReadingRouteReturnsNilForOutOfBoundsRow() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = ReadingsMainViewModel(repository: repository, building: building)

        XCTAssertNil(viewModel.readingRoute(forMeterAt: 0)) // no meters on this floor yet
    }

    func testGetCSVDataReturnsData() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = ReadingsMainViewModel(repository: repository, building: building)

        let data = try viewModel.getCSVData()

        XCTAssertFalse(data.isEmpty)
    }
}
