//
//  AddEditMeterViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//  Converted to async throws on 8/27/26 when AddEditMeterViewModel's
//  loadBuildingsAndFloors()/save()/delete() became async (see "Proper
//  concurrency" migration note).
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditMeterViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from
/// `TestSupport/FormValidationErrorAssertion.swift`.
@MainActor @Suite("AddEditMeterViewModel")
struct AddEditMeterViewModelTests {

    let repository: SwiftDataMeterRepository

    init() {
        repository = SwiftDataMeterRepository(inMemory: true)
    }

    // MARK: - Display

    @Test("adding a meter shows the add display state")
    func addingMeterDisplayState() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
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
    func editingMeterDisplayState() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let imageData = Data([0x01])
        let meter = try await repository.addMeter(MRKMeterInput(name: "M1", description: "A meter", imageData: imageData, floorID: floor.id))

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
    func loadBuildingsAndFloorsAutoSelectsSingleBuildingAndItsFloors() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "Only Building", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)

        await viewModel.loadBuildingsAndFloors()

        #expect(viewModel.selectedBuilding?.id == building.id)
        #expect(viewModel.floors.count == 3)
    }

    @Test("selectBuilding reloads floors and clears the selected floor")
    func selectBuildingReloadsFloorsAndClearsSelectedFloor() async throws {
        let buildingA = try await repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 2, autoCreateFloors: true))
        let buildingB = try await repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 4, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: buildingA, floor: buildingA.floors[0], meter: nil)
        await viewModel.loadBuildingsAndFloors()

        let indexOfB = try #require(viewModel.buildings.firstIndex { $0.id == buildingB.id })
        let selected = viewModel.selectBuilding(at: indexOfB)

        #expect(selected?.id == buildingB.id)
        #expect(viewModel.floors.count == 4)
        #expect(viewModel.selectedFloor == nil)
    }

    @Test("selectFloor at a valid row updates the selection")
    func selectFloorAtValidRowUpdatesSelection() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: nil, meter: nil)
        await viewModel.loadBuildingsAndFloors()

        let selected = viewModel.selectFloor(at: 0)

        #expect(selected?.id == viewModel.floors[0].id)
        #expect(viewModel.selectedFloor?.id == viewModel.floors[0].id)
    }

    @Test("selectFloor at an out-of-bounds row returns nil")
    func selectFloorAtOutOfBoundsRowReturnsNil() {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)
        #expect(viewModel.selectFloor(at: 0) == nil)
    }

    @Test("clearBuildingSelection clears building, floors, and floor selection")
    func clearBuildingSelectionClearsEverything() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: building.floors[0], meter: nil)
        await viewModel.loadBuildingsAndFloors()

        viewModel.clearBuildingSelection()

        #expect(viewModel.selectedBuilding == nil)
        #expect(viewModel.floors.isEmpty)
        #expect(viewModel.selectedFloor == nil)
    }

    @Test("clearFloorSelection clears only the floor selection")
    func clearFloorSelectionClearsOnlyFloor() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: building.floors[0], meter: nil)
        await viewModel.loadBuildingsAndFloors()

        viewModel.clearFloorSelection()

        #expect(viewModel.selectedFloor == nil)
        #expect(viewModel.selectedBuilding?.id == building.id)
        #expect(viewModel.floors.count == 3)
    }

    // MARK: - save validation

    @Test("save rejects when no building is selected")
    func saveRejectsWhenNoBuildingSelected() async {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)

        await assertThrowsFormValidationError(try await viewModel.save(nameText: "M1", descriptionText: nil, imageData: Data()), title: "Missing Building")
    }

    @Test("save rejects when no floor is selected")
    func saveRejectsWhenNoFloorSelected() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: nil, meter: nil)

        await assertThrowsFormValidationError(try await viewModel.save(nameText: "M1", descriptionText: nil, imageData: Data()), title: "Missing Floor")
    }

    @Test("save rejects a blank name")
    func saveRejectsBlankName() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: building.floors[0], meter: nil)

        await assertThrowsFormValidationError(try await viewModel.save(nameText: "   ", descriptionText: nil, imageData: Data()), title: "Missing Name")
    }

    @Test("save defaults a missing description to an empty string")
    func saveDefaultsMissingDescriptionToEmptyString() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: building.floors[0], meter: nil)

        let saved = try await viewModel.save(nameText: "M1", descriptionText: nil, imageData: Data())

        #expect(saved.meterDescription == "")
    }

    // MARK: - save behavior

    @Test("save adds a new meter when not editing")
    func saveAddsNewMeterWhenNotEditing() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: nil)

        let saved = try await viewModel.save(nameText: "M1", descriptionText: "A meter", imageData: Data([0x01]))

        #expect(saved.name == "M1")
        #expect(saved.floorID == floor.id)

        let refreshedBuilding = try await repository.getBuildings().first { $0.id == building.id }
        #expect(refreshedBuilding?.floors.first?.meters.count == 1)
    }

    @Test("save updates the existing meter when editing")
    func saveUpdatesExistingMeterWhenEditing() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let existingMeter = try await repository.addMeter(MRKMeterInput(name: "Old Name", description: "Old", imageData: Data(), floorID: floor.id))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: existingMeter)

        let saved = try await viewModel.save(nameText: "New Name", descriptionText: "New", imageData: Data())

        #expect(saved.id == existingMeter.id)
        #expect(saved.name == "New Name")

        let refreshedBuilding = try await repository.getBuildings().first { $0.id == building.id }
        #expect(refreshedBuilding?.floors.first?.meters.count == 1) // updated, not duplicated
    }

    // MARK: - delete

    @Test("delete with no meter does nothing")
    func deleteWithNoMeterDoesNothing() async throws {
        let viewModel = AddEditMeterViewModel(repository: repository, building: nil, floor: nil, meter: nil)
        try await viewModel.delete()
    }

    @Test("delete removes the meter")
    func deleteRemovesTheMeter() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0]
        let meter = try await repository.addMeter(MRKMeterInput(name: "To Delete", description: "", imageData: Data(), floorID: floor.id))
        let viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: meter)

        try await viewModel.delete()

        let refreshedBuilding = try await repository.getBuildings().first { $0.id == building.id }
        #expect(refreshedBuilding?.floors.first?.meters.count == 0)
    }
}
