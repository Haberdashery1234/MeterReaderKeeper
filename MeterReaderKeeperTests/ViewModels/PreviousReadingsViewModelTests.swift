//
//  PreviousReadingsViewModelTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//  Converted to async throws on 8/27/26 when PreviousReadingsViewModel.loadData()
//  became async (see "Proper concurrency" migration note).
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/PreviousReadingsViewModel.swift`.
@Suite("PreviousReadingsViewModel")
struct PreviousReadingsViewModelTests {

    let repository: SwiftDataMeterRepository
    let viewModel: PreviousReadingsViewModel
    let buildingA: MRKBuilding
    let meterA: MRKMeter
    let meterB: MRKMeter

    init() async throws {
        repository = SwiftDataMeterRepository(inMemory: true)
        viewModel = PreviousReadingsViewModel(repository: repository)

        buildingA = try await repository.addBuilding(MRKBuildingInput(name: "Building A", numberOfFloors: 1, autoCreateFloors: true))
        let floorA = buildingA.floors[0]
        meterA = try await repository.addMeter(MRKMeterInput(name: "Meter A", description: "", imageData: Data(), floorID: floorA.id))
        meterB = try await repository.addMeter(MRKMeterInput(name: "Meter B", description: "", imageData: Data(), floorID: floorA.id))

        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        _ = try await repository.addReading(MRKReadingInput(kWh: 100, date: today, meterID: meterA.id))
        _ = try await repository.addReading(MRKReadingInput(kWh: 200, date: yesterday, meterID: meterB.id))
    }

    @Test("loadData populates buildings and unique sorted dates")
    func loadDataPopulatesBuildingsAndUniqueSortedDates() async {
        await viewModel.loadData()

        #expect(viewModel.buildings.count == 1)
        #expect(viewModel.dates.count == 2)
        // Most recent date first.
        #expect(viewModel.dates[0] > viewModel.dates[1])
    }

    @Test("displayInfo returns the name and location for a known meter")
    func displayInfoReturnsNameAndLocationForKnownMeter() async throws {
        await viewModel.loadData()
        let refreshedMeterA = try #require(
            try await repository.getBuildings().first?.floors.first?.meters.first(where: { $0.id == meterA.id })
        )
        let reading = try #require(refreshedMeterA.readings.first)

        let info = viewModel.displayInfo(for: reading)

        #expect(info?.name == "Meter A")
        #expect(info?.location == "Building A - Floor 1")
    }

    @Test("applyFilters with no selection returns all readings sorted descending")
    func applyFiltersWithNoSelectionReturnsAllReadingsSortedDescending() async {
        await viewModel.loadData()

        viewModel.applyFilters(segment: .date)

        #expect(viewModel.readings.count == 2)
        #expect(viewModel.readings[0].date >= viewModel.readings[1].date)
    }

    @Test("selectDate at row zero clears the filter")
    func selectDateAtRowZeroClearsFilter() async {
        await viewModel.loadData()
        viewModel.selectDate(at: 0)
        viewModel.applyFilters(segment: .date)

        #expect(viewModel.readings.count == 2)
    }

    @Test("selectDate filters to just that date")
    func selectDateFiltersToJustThatDate() async {
        await viewModel.loadData()
        viewModel.selectDate(at: 1) // row 0 = "any date"

        viewModel.applyFilters(segment: .date)

        #expect(viewModel.readings.count == 1)
        #expect(viewModel.readings.first?.date == viewModel.dates[0])
    }

    @Test("selectBuilding resets the floor and meter selection")
    func selectBuildingResetsFloorAndMeterSelection() async {
        await viewModel.loadData()
        viewModel.selectBuilding(at: 1) // row 0 = "any building"

        #expect(viewModel.selectedBuilding?.id == buildingA.id)
        #expect(!viewModel.floors.isEmpty)
        #expect(viewModel.selectedFloor == nil)
        #expect(viewModel.meters.isEmpty)
        #expect(viewModel.selectedMeter == nil)
    }

    @Test("selectMeter filters to just that meter")
    func selectMeterFiltersToThatMeterOnly() async throws {
        await viewModel.loadData()
        viewModel.selectBuilding(at: 1)
        viewModel.selectFloor(at: 1)
        let indexOfMeterA = try #require(viewModel.meters.firstIndex { $0.id == meterA.id })
        viewModel.selectMeter(at: indexOfMeterA + 1) // +1 for the "any meter" row

        viewModel.applyFilters(segment: .meter)

        #expect(viewModel.readings.count == 1)
        #expect(viewModel.readings.first?.meterID == meterA.id)
    }
}
