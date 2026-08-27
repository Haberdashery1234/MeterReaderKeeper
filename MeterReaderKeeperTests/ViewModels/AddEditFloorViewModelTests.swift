//
//  AddEditFloorViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditFloorViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from `TestSupport/XCTestCase+FormValidationError.swift`.
final class AddEditFloorViewModelTests: XCTestCase {

    private var repository: SwiftDataMeterRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = SwiftDataMeterRepository(inMemory: true)
    }

    override func tearDownWithError() throws {
        repository = nil
        try super.tearDownWithError()
    }

    // MARK: - Display

    func testAddingFloorDisplayState() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: nil)

        XCTAssertFalse(viewModel.isEditing)
        XCTAssertEqual(viewModel.screenTitle, "Add Floor")
        XCTAssertNil(viewModel.initialFloorNumberText)
        XCTAssertNil(viewModel.initialMapImageData)
    }

    func testEditingFloorDisplayState() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let mapData = Data([0x01, 0x02, 0x03])
        let floor = try repository.updateFloor(
            id: building.floors[0].id,
            input: MRKFloorInput(number: 4, mapImageData: mapData, buildingID: building.id)
        )
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: floor)

        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.screenTitle, "Edit Floor")
        XCTAssertEqual(viewModel.initialFloorNumberText, "4")
        XCTAssertEqual(viewModel.initialMapImageData, mapData)
    }

    func testInitialMapImageDataIsNilWhenFloorHasNoMap() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0] // auto-created with an empty Data() map

        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: floor)

        XCTAssertNil(viewModel.initialMapImageData)
    }

    // MARK: - Building selection

    func testLoadBuildingsAutoSelectsWhenOnlyOneBuildingExists() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "Only Building", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)

        viewModel.loadBuildings()

        XCTAssertEqual(viewModel.buildings.count, 1)
        XCTAssertEqual(viewModel.selectedBuilding?.id, building.id)
    }

    func testLoadBuildingsDoesNotAutoSelectWhenMultipleBuildingsExist() throws {
        _ = try repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 1, autoCreateFloors: true))
        _ = try repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)

        viewModel.loadBuildings()

        XCTAssertEqual(viewModel.buildings.count, 2)
        XCTAssertNil(viewModel.selectedBuilding)
    }

    func testSelectBuildingAtValidRowUpdatesSelection() throws {
        _ = try repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 1, autoCreateFloors: true))
        _ = try repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)
        viewModel.loadBuildings()

        let selected = viewModel.selectBuilding(at: 1)

        XCTAssertEqual(selected?.id, viewModel.buildings[1].id)
        XCTAssertEqual(viewModel.selectedBuilding?.id, viewModel.buildings[1].id)
    }

    func testSelectBuildingAtOutOfBoundsRowReturnsNil() {
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)
        viewModel.loadBuildings()

        XCTAssertNil(viewModel.selectBuilding(at: 0))
    }

    // MARK: - save validation

    func testSaveRejectsWhenNoBuildingSelected() {
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)

        assertThrowsFormValidationError(try viewModel.save(floorNumberText: "3", mapImageData: Data()), title: "Missing Building")
    }

    func testSaveRejectsInvalidFloorNumberText() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: nil)

        assertThrowsFormValidationError(try viewModel.save(floorNumberText: "abc", mapImageData: Data()), title: "Invalid Floor")
    }

    func testSaveRejectsZeroFloorNumber() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: nil)

        assertThrowsFormValidationError(try viewModel.save(floorNumberText: "0", mapImageData: Data()), title: "Invalid Floor")
    }

    // MARK: - save behavior

    func testSaveAddsNewFloorWhenNotEditing() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: nil)
        let mapData = Data([0xAA])

        let saved = try viewModel.save(floorNumberText: "9", mapImageData: mapData)

        XCTAssertEqual(saved.number, 9)
        XCTAssertEqual(saved.mapImageData, mapData)
        XCTAssertEqual(saved.buildingID, building.id)

        let refreshedBuilding = try repository.getBuildings().first { $0.id == building.id }
        XCTAssertEqual(refreshedBuilding?.floors.count, 2) // 1 auto-created + 1 new
    }

    func testSaveUpdatesExistingFloorWhenEditing() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let existingFloor = building.floors[0]
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: existingFloor)
        let mapData = Data([0xBB])

        let saved = try viewModel.save(floorNumberText: "7", mapImageData: mapData)

        XCTAssertEqual(saved.id, existingFloor.id)
        XCTAssertEqual(saved.number, 7)
        XCTAssertEqual(saved.mapImageData, mapData)

        let refreshedBuilding = try repository.getBuildings().first { $0.id == building.id }
        XCTAssertEqual(refreshedBuilding?.floors.count, 1) // updated in place, not duplicated
    }
}
