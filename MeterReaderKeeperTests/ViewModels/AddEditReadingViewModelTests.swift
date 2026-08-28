//
//  AddEditReadingViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//  Converted to async throws on 8/27/26 when AddEditReadingViewModel's
//  save() became async (see "Proper concurrency" migration note).
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditReadingViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from
/// `TestSupport/FormValidationErrorAssertion.swift`.
@MainActor @Suite("AddEditReadingViewModel")
struct AddEditReadingViewModelTests {

    let repository: SwiftDataMeterRepository
    let building: MRKBuilding
    let floor: MRKFloor
    let meter: MRKMeter

    init() async throws {
        repository = SwiftDataMeterRepository(inMemory: true)
        building = try await repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        floor = building.floors[0]
        meter = try await repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
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
    func editingReadingDisplayState() async throws {
        let reading = try await repository.addReading(MRKReadingInput(kWh: 1234.5, date: Calendar.current.startOfDay(for: Date()), meterID: meter.id))
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: reading)

        #expect(viewModel.isEditing)
        #expect(viewModel.screenTitle == "Edit Reading")
        #expect(viewModel.initialReadingText == "1234.50")
    }

    // MARK: - save validation

    @Test("save rejects missing reading text")
    func saveRejectsMissingReadingText() async {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        await assertThrowsFormValidationError(try await viewModel.save(readingText: nil), title: "Missing Reading")
    }

    @Test("save rejects blank reading text")
    func saveRejectsBlankReadingText() async {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        await assertThrowsFormValidationError(try await viewModel.save(readingText: "   "), title: "Missing Reading")
    }

    @Test("save rejects non-numeric reading text")
    func saveRejectsNonNumericReadingText() async {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        await assertThrowsFormValidationError(try await viewModel.save(readingText: "not-a-number"), title: "Invalid Reading")
    }

    @Test("save rejects a negative reading value")
    func saveRejectsNegativeReadingValue() async {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        await assertThrowsFormValidationError(try await viewModel.save(readingText: "-5"), title: "Invalid Reading")
    }

    @Test("save accepts zero")
    func saveAcceptsZero() async throws {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        let saved = try await viewModel.save(readingText: "0")

        #expect(saved.kWh == 0)
    }

    // MARK: - save behavior

    @Test("save adds a new reading dated today")
    func saveAddsNewReadingDatedToday() async throws {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        let saved = try await viewModel.save(readingText: "15000.25")

        #expect(saved.kWh == 15000.25)
        #expect(saved.date == Calendar.current.startOfDay(for: Date()))
        #expect(saved.meterID == meter.id)
    }

    @Test("save updates an existing reading")
    func saveUpdatesExistingReading() async throws {
        let existingReading = try await repository.addReading(MRKReadingInput(kWh: 100, date: Calendar.current.startOfDay(for: Date()), meterID: meter.id))
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: existingReading)

        let saved = try await viewModel.save(readingText: "999.99")

        #expect(saved.id == existingReading.id)
        #expect(saved.kWh == 999.99)
    }
}
