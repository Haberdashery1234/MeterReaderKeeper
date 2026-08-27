//
//  AddEditReadingViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditReadingViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from
/// `TestSupport/FormValidationErrorAssertion.swift`.
@Suite("AddEditReadingViewModel")
struct AddEditReadingViewModelTests {

    let repository: SwiftDataMeterRepository
    let building: MRKBuilding
    let floor: MRKFloor
    let meter: MRKMeter

    init() throws {
        repository = SwiftDataMeterRepository(inMemory: true)
        building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        floor = building.floors[0]
        meter = try repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
    }

    // MARK: - Display

    @Test("adding a reading shows the add display state")
    func addingReadingDisplayState() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        #expect(!viewModel.isEditing)
        #expect(viewModel.screenTitle == "Add Reading")
        #expect(viewModel.initialReadingText == nil)
    }

    @Test("editing a reading shows the edit display state")
    func editingReadingDisplayState() throws {
        let reading = try repository.addReading(MRKReadingInput(kWh: 1234.5, date: Calendar.current.startOfDay(for: Date()), meterID: meter.id))
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: reading)

        #expect(viewModel.isEditing)
        #expect(viewModel.screenTitle == "Edit Reading")
        #expect(viewModel.initialReadingText == "1234.50")
    }

    // MARK: - save validation

    @Test("save rejects missing reading text")
    func saveRejectsMissingReadingText() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        assertThrowsFormValidationError(try viewModel.save(readingText: nil), title: "Missing Reading")
    }

    @Test("save rejects blank reading text")
    func saveRejectsBlankReadingText() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        assertThrowsFormValidationError(try viewModel.save(readingText: "   "), title: "Missing Reading")
    }

    @Test("save rejects non-numeric reading text")
    func saveRejectsNonNumericReadingText() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        assertThrowsFormValidationError(try viewModel.save(readingText: "not-a-number"), title: "Invalid Reading")
    }

    @Test("save rejects a negative reading value")
    func saveRejectsNegativeReadingValue() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        assertThrowsFormValidationError(try viewModel.save(readingText: "-5"), title: "Invalid Reading")
    }

    @Test("save accepts zero")
    func saveAcceptsZero() throws {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        let saved = try viewModel.save(readingText: "0")

        #expect(saved.kWh == 0)
    }

    // MARK: - save behavior

    @Test("save adds a new reading dated today")
    func saveAddsNewReadingDatedToday() throws {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        let saved = try viewModel.save(readingText: "15000.25")

        #expect(saved.kWh == 15000.25)
        #expect(saved.date == Calendar.current.startOfDay(for: Date()))
        #expect(saved.meterID == meter.id)
    }

    @Test("save updates an existing reading")
    func saveUpdatesExistingReading() throws {
        let existingReading = try repository.addReading(MRKReadingInput(kWh: 100, date: Calendar.current.startOfDay(for: Date()), meterID: meter.id))
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: existingReading)

        let saved = try viewModel.save(readingText: "999.99")

        #expect(saved.id == existingReading.id)
        #expect(saved.kWh == 999.99)
    }
}
