//
//  AddEditBuildingViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditBuildingViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from `TestSupport/XCTestCase+FormValidationError.swift`.
final class AddEditBuildingViewModelTests: XCTestCase {

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

    func testAddingBuildingDisplayState() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)

        XCTAssertFalse(viewModel.isEditing)
        XCTAssertEqual(viewModel.screenTitle, "Add Building")
        XCTAssertNil(viewModel.initialNameText)
        XCTAssertNil(viewModel.initialFloorsText)
        XCTAssertTrue(viewModel.isFloorsFieldEnabled)
    }

    func testEditingBuildingDisplayState() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.screenTitle, "Edit Building")
        XCTAssertEqual(viewModel.initialNameText, "121 Seaport")
        XCTAssertEqual(viewModel.initialFloorsText, "5")
        XCTAssertFalse(viewModel.isFloorsFieldEnabled)
    }

    // MARK: - save validation

    func testSaveRejectsBlankName() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "   ", floorsText: "5"), title: "Invalid Name")
    }

    func testSaveRejectsNameOverMaxLength() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        let longName = String(repeating: "A", count: 101)
        assertThrowsFormValidationError(try viewModel.save(nameText: longName, floorsText: "5"), title: "Name Too Long")
    }

    func testSaveRejectsMissingFloorsText() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "Some Building", floorsText: nil), title: "Invalid Floor Count")
    }

    func testSaveRejectsNonNumericFloorsText() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "Some Building", floorsText: "abc"), title: "Invalid Floor Count")
    }

    func testSaveRejectsZeroFloors() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "Some Building", floorsText: "0"), title: "Invalid Floor Count")
    }

    func testSaveRejectsTooManyFloors() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        assertThrowsFormValidationError(try viewModel.save(nameText: "Some Building", floorsText: "201"), title: "Too Many Floors")
    }

    func testSaveRejectsDuplicateNameCaseInsensitive() throws {
        _ = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)

        assertThrowsFormValidationError(try viewModel.save(nameText: "121 SEAPORT", floorsText: "3"), title: "Duplicate Name")
    }

    func testSaveCreatesBuildingWithTrimmedName() throws {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)

        let saved = try viewModel.save(nameText: "  New Building  ", floorsText: "10")

        XCTAssertEqual(saved.name, "New Building")
        XCTAssertEqual(saved.floors.count, 10)
        XCTAssertEqual(try repository.getBuildings().count, 1)
    }

    func testSaveOnAnExistingBuildingAlwaysThrowsNotImplemented() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 5, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        // Even a fully valid, non-duplicate name should still be rejected —
        // editing an existing building isn't implemented yet.
        assertThrowsFormValidationError(try viewModel.save(nameText: "A Totally Different Name", floorsText: "5"), title: "Not Implemented")
    }

    // MARK: - delete

    func testDeleteWithNoBuildingDoesNothing() {
        let viewModel = AddEditBuildingViewModel(repository: repository, building: nil)
        XCTAssertNoThrow(try viewModel.delete())
    }

    func testDeleteRemovesTheBuilding() throws {
        let building = try repository.addBuilding(MRKBuildingInput(name: "To Delete", numberOfFloors: 2, autoCreateFloors: true))
        let viewModel = AddEditBuildingViewModel(repository: repository, building: building)

        try viewModel.delete()

        XCTAssertTrue(try repository.getBuildings().isEmpty)
    }
}
