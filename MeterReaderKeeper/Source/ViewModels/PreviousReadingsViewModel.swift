//
//  PreviousReadingsViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//

import Foundation
import os.log

/// Business logic and repository access for the Previous Readings screen:
/// loading every reading across all buildings, the four cascading filter
/// pickers (Date / Building / Floor / Meter), and the filtered, sorted
/// list the table displays.
final class PreviousReadingsViewModel {

    enum FilterSegment: Int, CaseIterable {
        case date = 0
        case building = 1
        case floor = 2
        case meter = 3
    }

    private let repository: MeterRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "PreviousReadingsViewModel")

    private(set) var buildings: [MRKBuilding] = []
    private(set) var dates: [Date] = []
    private(set) var floors: [MRKFloor] = []
    private(set) var meters: [MRKMeter] = []

    private(set) var selectedDate: Date?
    private(set) var selectedBuilding: MRKBuilding?
    private(set) var selectedFloor: MRKFloor?
    private(set) var selectedMeter: MRKMeter?

    private(set) var readings: [MRKReading] = []

    /// meterID -> (display name, "Building - Floor N"), built once from
    /// `buildings` so cells can show context without each reading needing
    /// to carry its own meter/floor/building references.
    private var meterDisplayInfo: [UUID: (name: String, location: String)] = [:]

    init(repository: MeterRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Loading

    func loadData() {
        buildings = (try? repository.getBuildings()) ?? []

        var displayInfo: [UUID: (name: String, location: String)] = [:]
        var allReadingDates = Set<Date>()
        for building in buildings {
            for floor in building.floors {
                for meter in floor.meters {
                    let location = "\(building.name) - Floor \(floor.number)"
                    displayInfo[meter.id] = (name: meter.name, location: location)
                    for reading in meter.readings {
                        allReadingDates.insert(reading.date)
                    }
                }
            }
        }
        meterDisplayInfo = displayInfo
        dates = allReadingDates.sorted(by: >)

        logger.info("Loaded \(self.buildings.count) buildings and \(self.dates.count) dates")
    }

    private func allReadings() -> [MRKReading] {
        buildings.flatMap { building in
            building.floors.flatMap { floor in
                floor.meters.flatMap { $0.readings }
            }
        }
    }

    func displayInfo(for reading: MRKReading) -> (name: String, location: String)? {
        meterDisplayInfo[reading.meterID]
    }

    // MARK: - Filter selection

    func selectDate(at row: Int) {
        selectedDate = row == 0 ? nil : dates[row - 1]
    }

    func selectBuilding(at row: Int) {
        selectedBuilding = row == 0 ? nil : buildings[row - 1]
        floors = selectedBuilding?.sortedFloors ?? []
        selectedFloor = nil
        meters = []
        selectedMeter = nil
    }

    func selectFloor(at row: Int) {
        selectedFloor = row == 0 ? nil : floors[row - 1]
        meters = selectedFloor?.sortedMeters ?? []
        selectedMeter = nil
    }

    func selectMeter(at row: Int) {
        selectedMeter = row == 0 ? nil : meters[row - 1]
    }

    // MARK: - Filtering

    func applyFilters(segment: FilterSegment) {
        let all = allReadings()

        switch segment {
        case .date:
            readings = selectedDate.map { date in all.filter { $0.date == date } } ?? all
        case .building:
            readings = selectedBuilding.map { building in
                building.floors.flatMap { $0.meters.flatMap { $0.readings } }
            } ?? all
        case .floor:
            readings = selectedFloor.map { floor in
                floor.meters.flatMap { $0.readings }
            } ?? all
        case .meter:
            readings = selectedMeter.map { $0.readings } ?? all
        }

        readings.sort { $0.date > $1.date }

        logger.info("Applied filters, showing \(self.readings.count) readings")
    }
}
