//
//  PreviousReadingsViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/PreviousReadingsViewModel.swift`.
final class PreviousReadingsViewModelTests: XCTestCase {

    private var repository: SwiftDataMeterRepository!
    private var viewModel: PreviousReadingsViewModel!

    private var buildingA: MRKBuilding!
    private var meterA: MRKMeter!
    private var meterB: MRKMeter!

    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = SwiftDataMeterRepository(inMemory: true)
        viewModel = PreviousReadingsViewModel(repository: repository)

        buildingA = try repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 1, autoCreateFloors: true))
        let floorA = buildingA.floors[0]
        meterA = try repository.addMeter(MRKMeterInput(name: "Meter A", description: "", imageData: Data(), floorID: floorA.id))
        meterB = try repository.addMeter(MRKMeterInput(name: "Meter B", description: "", imageData: Data(), floorID: floorA.id))

        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        _ = try repository.addReading(MRKReadingInput(kWh: 100, date: today, meterID: meterA.id))
        _ = try repository.addReading(MRKReadingInput(kWh: 200, date: yesterday, meterID: meterB.id))
    }

    override func tearDownWithError() throws {
        repository = nil
        viewModel = nil
        buildingA = nil
        meterA = nil
        meterB = nil
        try super.tearDownWithError()
    }

    func testLoadDataPopulatesBuildingsAndUniqueSortedDates() {
        viewModel.loadData()

        XCTAssertEqual(viewModel.buildings.count, 1)
        XCTAssertEqual(viewModel.dates.count, 2)
        // Most recent date first.
        XCTAssertTrue(viewModel.dates[0] > viewModel.dates[1])
    }

    func testDisplayInfoReturnsNameAndLocationForKnownMeter() throws {
        viewModel.loadData()
        let refreshedMeterA = try XCTUnwrap(
            repository.getBuildings().first?.floors.first?.meters.first(where: { $0.id == meterA.id })
        )
        let reading = try XCTUnwrap(refreshedMeterA.readings.first)

        let info = viewModel.displayInfo(for: reading)

        XCTAssertEqual(info?.name, "Meter A")
        XCTAssertEqual(info?.location, "Building A - Floor 1")
    }

    func testApplyFiltersWithNoSelectionReturnsAllReadingsSortedDescending() {
        viewModel.loadData()

        viewModel.applyFilters(segment: .date)

        XCTAssertEqual(viewModel.readings.count, 2)
        XCTAssertTrue(viewModel.readings[0].date >= viewModel.readings[1].date)
    }

    func testSelectDateAtRowZeroClearsFilter() {
        viewModel.loadData()
        viewModel.selectDate(at: 0)
        viewModel.applyFilters(segment: .date)

        XCTAssertEqual(viewModel.readings.count, 2)
    }

    func testSelectDateFiltersToJustThatDate() {
        viewModel.loadData()
        viewModel.selectDate(at: 1) // row 0 = "any date"

        viewModel.applyFilters(segment: .date)

        XCTAssertEqual(viewModel.readings.count, 1)
        XCTAssertEqual(viewModel.readings.first?.date, viewModel.dates[0])
    }

    func testSelectBuildingResetsFloorAndMeterSelection() {
        viewModel.loadData()
        viewModel.selectBuilding(at: 1) // row 0 = "any building"

        XCTAssertEqual(viewModel.selectedBuilding?.id, buildingA.id)
        XCTAssertFalse(viewModel.floors.isEmpty)
        XCTAssertNil(viewModel.selectedFloor)
        XCTAssertTrue(viewModel.meters.isEmpty)
        XCTAssertNil(viewModel.selectedMeter)
    }

    func testSelectMeterFiltersToThatMeterOnly() throws {
        viewModel.loadData()
        viewModel.selectBuilding(at: 1)
        viewModel.selectFloor(at: 1)
        let indexOfMeterA = try XCTUnwrap(viewModel.meters.firstIndex { $0.id == meterA.id })
        viewModel.selectMeter(at: indexOfMeterA + 1) // +1 for the "any meter" row

        viewModel.applyFilters(segment: .meter)

        XCTAssertEqual(viewModel.readings.count, 1)
        XCTAssertEqual(viewModel.readings.first?.meterID, meterA.id)
    }
}
