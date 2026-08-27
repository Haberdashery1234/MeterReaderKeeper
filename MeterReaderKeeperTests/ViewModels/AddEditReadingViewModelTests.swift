//
//  AddEditReadingViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/AddEditReadingViewModel.swift`. Uses
/// `assertThrowsFormValidationError` from `TestSupport/XCTestCase+FormValidationError.swift`.
final class AddEditReadingViewModelTests: XCTestCase {

    private var repository: SwiftDataMeterRepository!
    private var building: MRKBuilding!
    private var floor: MRKFloor!
    private var meter: MRKMeter!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = SwiftDataMeterRepository(inMemory: true)
        building = try repository.addBuilding(MRKBuildingInput(name: "121 Seaport", numberOfFloors: 1, autoCreateFloors: true))
        floor = building.floors[0]
        meter = try repository.addMeter(MRKMeterInput(name: "M1", description: "", imageData: Data(), floorID: floor.id))
    }

    override func tearDownWithError() throws {
        repository = nil
        building = nil
        floor = nil
        meter = nil
        try super.tearDownWithError()
    }

    // MARK: - Display

    func testAddingReadingDisplayState() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        XCTAssertFalse(viewModel.isEditing)
        XCTAssertEqual(viewModel.screenTitle, "Add Reading")
        XCTAssertNil(viewModel.initialReadingText)
    }

    func testEditingReadingDisplayState() throws {
        let reading = try repository.addReading(MRKReadingInput(kWh: 1234.5, date: Calendar.current.startOfDay(for: Date()), meterID: meter.id))
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: reading)

        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.screenTitle, "Edit Reading")
        XCTAssertEqual(viewModel.initialReadingText, "1234.50")
    }

    // MARK: - save validation

    func testSaveRejectsMissingReadingText() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        assertThrowsFormValidationError(try viewModel.save(readingText: nil), title: "Missing Reading")
    }

    func testSaveRejectsBlankReadingText() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        assertThrowsFormValidationError(try viewModel.save(readingText: "   "), title: "Missing Reading")
    }

    func testSaveRejectsNonNumericReadingText() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        assertThrowsFormValidationError(try viewModel.save(readingText: "not-a-number"), title: "Invalid Reading")
    }

    func testSaveRejectsNegativeReadingValue() {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        assertThrowsFormValidationError(try viewModel.save(readingText: "-5"), title: "Invalid Reading")
    }

    func testSaveAcceptsZero() throws {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        let saved = try viewModel.save(readingText: "0")

        XCTAssertEqual(saved.kWh, 0)
    }

    // MARK: - save behavior

    func testSaveAddsNewReadingDatedToday() throws {
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)

        let saved = try viewModel.save(readingText: "15000.25")

        XCTAssertEqual(saved.kWh, 15000.25)
        XCTAssertEqual(saved.date, Calendar.current.startOfDay(for: Date()))
        XCTAssertEqual(saved.meterID, meter.id)
    }

    func testSaveUpdatesExistingReading() throws {
        let existingReading = try repository.addReading(MRKReadingInput(kWh: 100, date: Calendar.current.startOfDay(for: Date()), meterID: meter.id))
        let viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: existingReading)

        let saved = try viewModel.save(readingText: "999.99")

        XCTAssertEqual(saved.id, existingReading.id)
        XCTAssertEqual(saved.kWh, 999.99)
    }
}
