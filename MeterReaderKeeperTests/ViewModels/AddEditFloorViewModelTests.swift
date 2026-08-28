//
//  AddEditFloorViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//  Converted to async throws on 8/27/26 when AddEditFloorViewModel's
//  loadBuildings()/save() became async (see "Proper concurrency"
//  migration note).
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditFloorViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from
/// `TestSupport/FormValidationErrorAssertion.swift`.
@MainActor @Suite("AddEditFloorViewModel")
struct AddEditFloorViewModelTests {

    let repository: SwiftDataMeterRepository

    init() {
        repository = SwiftDataMeterRepository(inMemory: true)
    }

    // MARK: - Display

    @Test("adding a floor shows the add display state")
    func addingFloorDisplayState() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: nil)

        #expect(!viewModel.isEditing)
        #expect(viewModel.screenTitle == "Add Floor")
        #expect(viewModel.initialFloorNumberText == nil)
        #expect(viewModel.initialMapImageData == nil)
    }

    @Test("editing a floor shows the edit display state")
    func editingFloorDisplayState() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let mapData = Data([0x01, 0x02, 0x03])
        let floor = try await repository.updateFloor(
            id: building.floors[0].id,
            input: MRKFloorInput(number: 4, mapImageData: mapData, buildingID: building.id)
        )
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: floor)

        #expect(viewModel.isEditing)
        #expect(viewModel.screenTitle == "Edit Floor")
        #expect(viewModel.initialFloorNumberText == "4")
        #expect(viewModel.initialMapImageData == mapData)
    }

    @Test("initialMapImageData is nil when the floor has no map")
    func initialMapImageDataIsNilWhenFloorHasNoMap() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let floor = building.floors[0] // auto-created with an empty Data() map

        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: floor)

        #expect(viewModel.initialMapImageData == nil)
    }

    // MARK: - Building selection

    @Test("loadBuildings auto-selects when only one building exists")
    func loadBuildingsAutoSelectsWhenOnlyOneBuildingExists() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "Only Building", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)

        await viewModel.loadBuildings()

        #expect(viewModel.buildings.count == 1)
        #expect(viewModel.selectedBuilding?.id == building.id)
    }

    @Test("loadBuildings does not auto-select when multiple buildings exist")
    func loadBuildingsDoesNotAutoSelectWhenMultipleBuildingsExist() async throws {
        _ = try await repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 1, autoCreateFloors: true))
        _ = try await repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)

        await viewModel.loadBuildings()

        #expect(viewModel.buildings.count == 2)
        #expect(viewModel.selectedBuilding == nil)
    }

    @Test("selectBuilding at a valid row updates the selection")
    func selectBuildingAtValidRowUpdatesSelection() async throws {
        _ = try await repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 1, autoCreateFloors: true))
        _ = try await repository.addBuilding(MRKBuildingInput(name: "Building B", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)
        await viewModel.loadBuildings()

        let selected = viewModel.selectBuilding(at: 1)

        #expect(selected?.id == viewModel.buildings[1].id)
        #expect(viewModel.selectedBuilding?.id == viewModel.buildings[1].id)
    }

    @Test("selectBuilding at an out-of-bounds row returns nil")
    func selectBuildingAtOutOfBoundsRowReturnsNil() async {
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)
        await viewModel.loadBuildings()

        #expect(viewModel.selectBuilding(at: 0) == nil)
    }

    // MARK: - save validation

    @Test("save rejects when no building is selected")
    func saveRejectsWhenNoBuildingSelected() async {
        let viewModel = AddEditFloorViewModel(repository: repository, building: nil, floor: nil)

        await assertThrowsFormValidationError(try await viewModel.save(floorNumberText: "3", mapImageData: Data()), title: "Missing Building")
    }

    @Test("save rejects invalid floor number text")
    func saveRejectsInvalidFloorNumberText() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: nil)

        await assertThrowsFormValidationError(try await viewModel.save(floorNumberText: "abc", mapImageData: Data()), title: "Invalid Floor")
    }

    @Test("save rejects a zero floor number")
    func saveRejectsZeroFloorNumber() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: nil)

        await assertThrowsFormValidationError(try await viewModel.save(floorNumberText: "0", mapImageData: Data()), title: "Invalid Floor")
    }

    // MARK: - save behavior

    @Test("save adds a new floor when not editing")
    func saveAddsNewFloorWhenNotEditing() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: nil)
        let mapData = Data([0xAA])

        let saved = try await viewModel.save(floorNumberText: "9", mapImageData: mapData)

        #expect(saved.number == 9)
        #expect(saved.mapImageData == mapData)
        #expect(saved.buildingID == building.id)

        let refreshedBuilding = try await repository.getBuildings().first { $0.id == building.id }
        #expect(refreshedBuilding?.floors.count == 2) // 1 auto-created + 1 new
    }

    @Test("save updates the existing floor when editing")
    func saveUpdatesExistingFloorWhenEditing() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        let existingFloor = building.floors[0]
        let viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: existingFloor)
        let mapData = Data([0xBB])

        let saved = try await viewModel.save(floorNumberText: "7", mapImageData: mapData)

        #expect(saved.id == existingFloor.id)
        #expect(saved.number == 7)
        #expect(saved.mapImageData == mapData)

        let refreshedBuilding = try await repository.getBuildings().first { $0.id == building.id }
        #expect(refreshedBuilding?.floors.count == 1) // updated in place, not duplicated
    }
}
