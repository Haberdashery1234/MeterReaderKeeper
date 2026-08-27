//
//  AddEditBuildingViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
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
    func editingBuildingDisplayState() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        #expect(viewModel.isEditing)
        #expect(viewModel.screenTitle == "Edit Building")
        #expect(viewModel.initialNameText == "121 Seaport")
        #expect(viewModel.initialFloorsText == "5")
        #expect(!viewModel.isFloorsFieldEnabled)
    }

    // MARK: - save validation

    @Test("save rejects a blank name")
    func saveRejectsBlankName() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "   ", floorsText: "5"), title: "Invalid Name")
    }

    @Test("save rejects a name over the max length")
    func saveRejectsNameOverMaxLength() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        let longName = String(repeating: "A", count: 101)
        assertThrowsFormValidationError(try viewModel.save(nameText: longName, floorsText: "5"), title: "Name Too Long")
    }

    @Test("save rejects missing floors text")
    func saveRejectsMissingFloorsText() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "Some Building", floorsText: nil), title: "Invalid Floor Count")
    }

    @Test("save rejects non-numeric floors text")
    func saveRejectsNonNumericFloorsText() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "Some Building", floorsText: "abc"), title: "Invalid Floor Count")
    }

    @Test("save rejects zero floors")
    func saveRejectsZeroFloors() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "Some Building", floorsText: "0"), title: "Invalid Floor Count")
    }

    @Test("save rejects too many floors")
    func saveRejectsTooManyFloors() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "Some Building", floorsText: "201"), title: "Too Many Floors")
    }

    @Test("save rejects a duplicate name case-insensitively")
    func saveRejectsDuplicateNameCaseInsensitive() throws {
        _ = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)

        assertThrowsFormValidationError(try viewModel.save(nameText: "121 SEAPORT", floorsText: "3"), title: "Duplicate Name")
    }

    @Test("save creates a building with a trimmed name")
    func saveCreatesBuildingWithTrimmedName() throws {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)

        let saved = try viewModel.save(nameText: "  New Building  ", floorsText: "10")

        #expect(saved.name == "New Building")
        #expect(saved.floors.count == 10)
        #expect(try repository.getBuildings().count == 1)
    }

    @Test("save on an existing building always throws Not Implemented")
    func saveOnAnExistingBuildingAlwaysThrowsNotImplemented() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        // Even a fully valid, non-duplicate name should still be rejected —
        // editing an existing building isn't implemented yet.
        assertThrowsFormValidationError(try viewModel.save(nameText: "A Totally Different Name", floorsText: "5"), title: "Not Implemented")
    }

    // MARK: - delete

    @Test("delete with no building does nothing")
    func deleteWithNoBuildingDoesNothing() throws {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        try viewModel.delete()
    }

    @Test("delete removes the building")
    func deleteRemovesTheBuilding() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "To Delete", numberOfFloors: 2, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        try viewModel.delete()

        #expect(try repository.getBuildings().isEmpty)
    }
}
