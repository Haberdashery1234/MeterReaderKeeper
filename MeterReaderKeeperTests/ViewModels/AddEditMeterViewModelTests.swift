//
//  AddEditMeterViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditMeterViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from
/// `TestSupport/FormValidationErrorAssertion.swift`.
@Suite("AddEditMeterViewModel")
struct AddEditMeterViewModelTests {

    let repository: SwiftDataMeterRepository

    init() {
        repository = SwiftDataMeterRepository(inMemory: true)
    }

    // MARK: - Display

    @Test("adding a meter shows the add display state")
    func addingMeterDisplayState() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: nil)

        #expect(!viewModel.isEditing)
        #expect(viewModel.screenTitle == "Add Meter")
        #expect(viewModel.initialNameText == nil)
        #expect(viewModel.initialDescriptionText == nil)
        #expect(viewModel.initialFloorText == "Floor \(floor.number)")
        #expect(viewModel.initialImageData == nil)
    }

    @Test("editing a meter shows the edit display state")
    func editingMeterDisplayState() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let imageData = Data([0x01])
        let meter = try repository.addMeter(MRKMeterInput(name: "M1", description: "A meter", imageData: imageData, floorID: floor.id))

        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: meter)

        #expect(viewModel.isEditing)
        #expect(viewModel.screenTitle == "Edit Meter")
        #expect(viewModel.initialNameText == "M1")
        #expect(viewModel.initialDescriptionText == "A meter")
        #expect(viewModel.initialImageData == imageData)
    }

    @Test("initialFloorText is nil with no selected floor")
    func initialFloorTextIsNilWithNoSelectedFloor() {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)
        #expect(viewModel.initialFloorText == nil)
    }

    // MARK: - Loading + selection

    @Test("loadBuildingsAndFloors auto-selects a single building and its floors")
    func loadBuildingsAndFloorsAutoSelectsSingleBuildingAndItsFloors() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "Only Building", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)

        viewModel.loadBuildingsAndFloors()

        #expect(viewModel.selectedBuilding?.id == building.id)
        #expect(viewModel.floors.count == 3)
    }

    @Test("selectBuilding reloads floors and clears the selected floor")
    func selectBuildingReloadsFloorsAndClearsSelectedFloor() throws {
        let buildingA = try repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 2, autoCreateFloors: true))
        let buildingB = try repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 4, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: buildingA, floor: buildingA.floors[0], meter: nil)
        viewModel.loadBuildingsAndFloors()

        let indexOfB = try #require(viewModel.buildings.firstIndex { $0.id == buildingB.id })
        let selected = viewModel.selectBuilding(at: indexOfB)

        #expect(selected?.id == buildingB.id)
        #expect(viewModel.floors.count == 4)
        #expect(viewModel.selectedFloor == nil)
    }

    @Test("selectFloor at a valid row updates the selection")
    func selectFloorAtValidRowUpdatesSelection() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: nil, meter: nil)
        viewModel.loadBuildingsAndFloors()

        let selected = viewModel.selectFloor(at: 0)

        #expect(selected?.id == viewModel.floors[0].id)
        #expect(viewModel.selectedFloor?.id == viewModel.floors[0].id)
    }

    @Test("selectFloor at an out-of-bounds row returns nil")
    func selectFloorAtOutOfBoundsRowReturnsNil() {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)
        #expect(viewModel.selectFloor(at: 0) == nil)
    }

    // MARK: - save validation

    @Test("save rejects when no building is selected")
    func saveRejectsWhenNoBuildingSelected() {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)

        assertThrowsFormValidationError(try viewModel.save(nameText: "M1", descriptionText: nil, imageData: Data()), title: "Missing Building")
    }

    @Test("save rejects when no floor is selected")
    func saveRejectsWhenNoFloorSelected() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: nil, meter: nil)

        assertThrowsFormValidationError(try viewModel.save(nameText: "M1", descriptionText: nil, imageData: Data()), title: "Missing Floor")
    }

    @Test("save rejects a blank name")
    func saveRejectsBlankName() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: building.floors[0], meter: nil)

        assertThrowsFormValidationError(try viewModel.save(nameText: "   ", descriptionText: nil, imageData: Data()), title: "Missing Name")
    }

    @Test("save defaults a missing description to an empty string")
    func saveDefaultsMissingDescriptionToEmptyString() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: building.floors[0], meter: nil)

        let saved = try viewModel.save(nameText: "M1", descriptionText: nil, imageData: Data())

        #expect(saved.meterDescription == "")
    }

    // MARK: - save behavior

    @Test("save adds a new meter when not editing")
    func saveAddsNewMeterWhenNotEditing() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: nil)

        let saved = try viewModel.save(nameText: "M1", descriptionText: "A meter", imageData: Data([0x01]))

        #expect(saved.name == "M1")
        #expect(saved.floorID == floor.id)

        let refreshedBuilding = try repository.getBuildings().first { $0.id == building.id }
        #expect(refreshedBuilding?.floors.first?.meters.count == 1)
    }

    @Test("save updates the existing meter when editing")
    func saveUpdatesExistingMeterWhenEditing() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let existingMeter = try repository.addMeter(MRKMeterInput(name: "Old Name", description: "Old", imageData: Data(), floorID: floor.id))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: existingMeter)

        let saved = try viewModel.save(nameText: "New Name", descriptionText: "New", imageData: Data())

        #expect(saved.id == existingMeter.id)
        #expect(saved.name == "New Name")

        let refreshedBuilding = try repository.getBuildings().first { $0.id == building.id }
        #expect(refreshedBuilding?.floors.first?.meters.count == 1) // updated, not duplicated
    }

    // MARK: - delete

    @Test("delete with no meter does nothing")
    func deleteWithNoMeterDoesNothing() throws {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)
        try viewModel.delete()
    }

    @Test("delete removes the meter")
    func deleteRemovesTheMeter() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try repository.addMeter(MRKMeterInput(name: "To Delete", description: "", imageData: Data(), floorID: floor.id))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: meter)

        try viewModel.delete()

        let refreshedBuilding = try repository.getBuildings().first { $0.id == building.id }
        #expect(refreshedBuilding?.floors.first?.meters.count == 0)
    }
}
