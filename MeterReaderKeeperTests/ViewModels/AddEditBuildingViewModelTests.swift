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
@Suite("AddEditBuildingViewModel")
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
        #expect(!viewModel.isFloorsFieldEnabled)
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

    @Test("save on an existing building always throws Not Implemented")
    func saveOnAnExistingBuildingAlwaysThrowsNotImplemented() async throws {
        let building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        // Even a fully valid, non-duplicate name should still be rejected —
        // editing an existing building isn't implemented yet.
        await assertThrowsFormValidationError(try await viewModel.save(nameText: "A Totally Different Name", floorsText: "5"), title: "Not Implemented")
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
