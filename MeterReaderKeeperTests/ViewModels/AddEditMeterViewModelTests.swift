//
//  AddEditMeterViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditMeterViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from `TestSupport/XCTestCase+FormValidationError.swift`.
final class AddEditMeterViewModelTests: XCTestCase {

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

    func testAddingMeterDisplayState() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: nil)

        XCTAssertFalse(viewModel.isEditing)
        XCTAssertEqual(viewModel.screenTitle, "Add Meter")
        XCTAssertNil(viewModel.initialNameText)
        XCTAssertNil(viewModel.initialDescriptionText)
        XCTAssertEqual(viewModel.initialFloorText, "Floor \(floor.number)")
        XCTAssertNil(viewModel.initialImageData)
    }

    func testEditingMeterDisplayState() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let imageData = Data([0x01])
        let meter = try repository.addMeter(MRKMeterInput(name: "M1", description: "A meter", imageData: imageData, floorID: floor.id))

        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: meter)

        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.screenTitle, "Edit Meter")
        XCTAssertEqual(viewModel.initialNameText, "M1")
        XCTAssertEqual(viewModel.initialDescriptionText, "A meter")
        XCTAssertEqual(viewModel.initialImageData, imageData)
    }

    func testInitialFloorTextIsNilWithNoSelectedFloor() {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)
        XCTAssertNil(viewModel.initialFloorText)
    }

    // MARK: - Loading + selection

    func testLoadBuildingsAndFloorsAutoSelectsSingleBuildingAndItsFloors() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "Only Building", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)

        viewModel.loadBuildingsAndFloors()

        XCTAssertEqual(viewModel.selectedBuilding?.id, building.id)
        XCTAssertEqual(viewModel.floors.count, 3)
    }

    func testSelectBuildingReloadsFloorsAndClearsSelectedFloor() throws {
        let buildingA = try repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 2, autoCreateFloors: true))
        let buildingB = try repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 4, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: buildingA, floor: buildingA.floors[0], meter: nil)
        viewModel.loadBuildingsAndFloors()

        let indexOfB = try XCTUnwrap(viewModel.buildings.firstIndex { $0.id == buildingB.id })
        let selected = viewModel.selectBuilding(at: indexOfB)

        XCTAssertEqual(selected?.id, buildingB.id)
        XCTAssertEqual(viewModel.floors.count, 4)
        XCTAssertNil(viewModel.selectedFloor)
    }

    func testSelectFloorAtValidRowUpdatesSelection() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: nil, meter: nil)
        viewModel.loadBuildingsAndFloors()

        let selected = viewModel.selectFloor(at: 0)

        XCTAssertEqual(selected?.id, viewModel.floors[0].id)
        XCTAssertEqual(viewModel.selectedFloor?.id, viewModel.floors[0].id)
    }

    func testSelectFloorAtOutOfBoundsRowReturnsNil() {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)
        XCTAssertNil(viewModel.selectFloor(at: 0))
    }

    // MARK: - save validation

    func testSaveRejectsWhenNoBuildingSelected() {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)

        assertThrowsFormValidationError(try viewModel.save(nameText: "M1", descriptionText: nil, imageData: Data()), title: "Missing Building")
    }

    func testSaveRejectsWhenNoFloorSelected() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: nil, meter: nil)

        assertThrowsFormValidationError(try viewModel.save(nameText: "M1", descriptionText: nil, imageData: Data()), title: "Missing Floor")
    }

    func testSaveRejectsBlankName() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: building.floors[0], meter: nil)

        assertThrowsFormValidationError(try viewModel.save(nameText: "   ", descriptionText: nil, imageData: Data()), title: "Missing Name")
    }

    func testSaveDefaultsMissingDescriptionToEmptyString() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: building.floors[0], meter: nil)

        let saved = try viewModel.save(nameText: "M1", descriptionText: nil, imageData: Data())

        XCTAssertEqual(saved.meterDescription, "")
    }

    // MARK: - save behavior

    func testSaveAddsNewMeterWhenNotEditing() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: nil)

        let saved = try viewModel.save(nameText: "M1", descriptionText: "A meter", imageData: Data([0x01]))

        XCTAssertEqual(saved.name, "M1")
        XCTAssertEqual(saved.floorID, floor.id)

        let refreshedBuilding = try repository.getBuildings().first { $0.id == building.id }
        XCTAssertEqual(refreshedBuilding?.floors.first?.meters.count, 1)
    }

    func testSaveUpdatesExistingMeterWhenEditing() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let existingMeter = try repository.addMeter(MRKMeterInput(name: "Old Name", description: "Old", imageData: Data(), floorID: floor.id))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: existingMeter)

        let saved = try viewModel.save(nameText: "New Name", descriptionText: "New", imageData: Data())

        XCTAssertEqual(saved.id, existingMeter.id)
        XCTAssertEqual(saved.name, "New Name")

        let refreshedBuilding = try repository.getBuildings().first { $0.id == building.id }
        XCTAssertEqual(refreshedBuilding?.floors.first?.meters.count, 1) // updated, not duplicated
    }

    // MARK: - delete

    func testDeleteWithNoMeterDoesNothing() {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)
        XCTAssertNoThrow(try viewModel.delete())
    }

    func testDeleteRemovesTheMeter() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try repository.addMeter(MRKMeterInput(name: "To Delete", description: "", imageData: Data(), floorID: floor.id))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: meter)

        try viewModel.delete()

        let refreshedBuilding = try repository.getBuildings().first { $0.id == building.id }
        XCTAssertEqual(refreshedBuilding?.floors.first?.meters.count, 0)
    }
}
