//
//  AddEditBuildingViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//  Converted to async throws on 8/27/26 when AddEditBuildingViewModel's
//  save()/delete() became async (see "Proper concurrency" migration note).
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditBuildingViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from
/// `TestSupport/FormValidationErrorAssertion.swift`.
@MainActor @Suite("AddEditBuildingViewModel")
struct AddEditBuildingViewModelTests {

    let repository: SwiftDataMeterRepository

    init() {
        repository = SwiftDataMeterRepository(inMemory: true)
    }

    // MARK: - Display

    @Test("adding a building shows the add display state")
    func addingBuildingDisplayState() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)

        #expect(!viewModel.isEditing)
        #expect(viewModel.screenTitle == "Add Building")
        #expect(viewModel.initialNameText == nil)
        #expect(viewModel.initialFloorsText == nil)
        #expect(viewModel.isFloorsFieldEnabled)
    }

    @Test("editing a building shows the edit display state")
    func editingBuildingDisplayState() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        #expect(viewModel.isEditing)
        #expect(viewModel.screenTitle == "Edit Building")
        #expect(viewModel.initialNameText == "121 Seaport")
        #expect(viewModel.initialFloorsText == "5")
        // Floor count is now editable on an existing building too — see
        // "save increases floor count..."/"save decreases floor count..."
        // below.
        #expect(viewModel.isFloorsFieldEnabled)
    }

    // MARK: - save validation

    @Test("save rejects a blank name")
    func saveRejectsBlankName() async {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        await assertThrowsFormValidationError(try await viewModel.save(nameText: "   ", floorsText: "5"), title: "Invalid Name")
    }

    @Test("save rejects a name over the max length")
    func saveRejectsNameOverMaxLength() async {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        let longName = String(repeating: "A", count: 101)
        await assertThrowsFormValidationError(try await viewModel.save(nameText: longName, floorsText: "5"), title: "Name Too Long")
    }

    @Test("save rejects missing floors text")
    func saveRejectsMissingFloorsText() async {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        await assertThrowsFormValidationError(try await viewModel.save(nameText: "Some Building", floorsText: nil), title: "Invalid Floor Count")
    }

    @Test("save rejects non-numeric floors text")
    func saveRejectsNonNumericFloorsText() async {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        await assertThrowsFormValidationError(try await viewModel.save(nameText: "Some Building", floorsText: "abc"), title: "Invalid Floor Count")
    }

    @Test("save rejects zero floors")
    func saveRejectsZeroFloors() async {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        await assertThrowsFormValidationError(try await viewModel.save(nameText: "Some Building", floorsText: "0"), title: "Invalid Floor Count")
    }

    @Test("save rejects too many floors")
    func saveRejectsTooManyFloors() async {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        await assertThrowsFormValidationError(try await viewModel.save(nameText: "Some Building", floorsText: "201"), title: "Too Many Floors")
    }

    @Test("save rejects a duplicate name case-insensitively")
    func saveRejectsDuplicateNameCaseInsensitive() async throws {
        _ = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)

        await assertThrowsFormValidationError(try await viewModel.save(nameText: "121 SEAPORT", floorsText: "3"), title: "Duplicate Name")
    }

    @Test("save creates a building with a trimmed name")
    func saveCreatesBuildingWithTrimmedName() async throws {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)

        let saved = try await viewModel.save(nameText: "  New Building  ", floorsText: "10")

        #expect(saved.name == "New Building")
        #expect(saved.floors.count == 10)
        #expect(try await repository.getBuildings().count == 1)
    }

    @Test("save on an existing building with a changed name throws Renaming Not Supported")
    func saveOnAnExistingBuildingWithChangedNameThrows() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        // Renaming is still not supported, even with a fully valid,
        // non-duplicate name and an unchanged floor count.
        await assertThrowsFormValidationError(try await viewModel.save(nameText: "A Totally Different Name", floorsText: "5"), title: "Renaming Not Supported")
    }

    @Test("save on an existing building with the same name and floor count is a no-op success")
    func saveWithUnchangedNameAndFloorCountSucceeds() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        let saved = try await viewModel.save(nameText: "121 Seaport", floorsText: "5")

        #expect(saved.name == "121 Seaport")
        #expect(saved.floors.count == 5)
    }

    @Test("save increasing floor count adds floors numbered after the existing ones")
    func saveIncreasingFloorCountAddsFloors() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        let saved = try await viewModel.save(nameText: "121 Seaport", floorsText: "5")

        #expect(saved.floors.count == 5)
        #expect(Set(saved.floors.map(\.number)) == [1, 2, 3, 4, 5])
    }

    @Test("save decreasing floor count removes the top (highest-numbered) floors")
    func saveDecreasingFloorCountRemovesTopFloors() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        let saved = try await viewModel.save(nameText: "121 Seaport", floorsText: "3")

        #expect(saved.floors.count == 3)
        #expect(Set(saved.floors.map(\.number)) == [1, 2, 3])
    }

    @Test("save decreasing floor count cascades to delete meters on the removed floors")
    func saveDecreasingFloorCountCascadesToMeters() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let topFloor = try #require(building.floors.first { $0.number == 3 })
        let orphanedMeter = try await repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: topFloor.id))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        let saved = try await viewModel.save(nameText: "121 Seaport", floorsText: "2")

        #expect(saved.floors.count == 2)
        #expect(!saved.floors.contains { $0.id == topFloor.id })
        // If the cascade didn't actually remove the meter, this would
        // still be findable.
        await #expect(throws: (any Error).self) {
            try await self.repository.addReading(MRKReadingInput(kWh: 100, date: Date(), meterID: orphanedMeter.id))
        }
    }

    // MARK: - floorRemovalWarning

    @Test("floorRemovalWarning is nil when adding a new building")
    func floorRemovalWarningNilWhenAdding() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        #expect(viewModel.floorRemovalWarning(floorsText: "1") == nil)
    }

    @Test("floorRemovalWarning is nil when the floor count isn't decreasing")
    func floorRemovalWarningNilWhenNotDecreasing() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        #expect(viewModel.floorRemovalWarning(floorsText: "3") == nil)
        #expect(viewModel.floorRemovalWarning(floorsText: "5") == nil)
    }

    @Test("floorRemovalWarning is nil when the removed floors have no meters")
    func floorRemovalWarningNilWhenRemovedFloorsAreEmpty() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        #expect(viewModel.floorRemovalWarning(floorsText: "3") == nil)
    }

    @Test("floorRemovalWarning describes the floors and meters that would be removed")
    func floorRemovalWarningDescribesLoss() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 3, autoCreateFloors: true))
        let topFloor = try #require(building.floors.first { $0.number == 3 })
        _ = try await repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: topFloor.id))
        _ = try await repository.addMeter(MRKMeterInput(name: "M2", description: "", imageData: Data(), floorID: topFloor.id))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        let warning = try #require(viewModel.floorRemovalWarning(floorsText: "2"))
        #expect(warning.contains("1 floor"))
        #expect(warning.contains("2 meters"))
    }

    // MARK: - delete

    @Test("delete with no building does nothing")
    func deleteWithNoBuildingDoesNothing() async throws {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        try await viewModel.delete()
    }

    @Test("delete removes the building")
    func deleteRemovesTheBuilding() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "To Delete", numberOfFloors: 2, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        try await viewModel.delete()

        #expect(try await repository.getBuildings().isEmpty)
    }
}
