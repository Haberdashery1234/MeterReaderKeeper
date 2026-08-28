//
//  PreviousReadingsViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//  Converted to async/await + @MainActor on 8/27/26.
//

import Foundation

/// Business logic and repository access for the Previous Readings screen:
/// loading every reading across all buildings, the four cascading filter
/// pickers (Date / Building / Floor / Meter), and the filtered, sorted
/// list the table displays.
@MainActor
final class PreviousReadingsViewModel {

    enum FilterSegment: Int, CaseIterable {
        case date = 0
        case building = 1
        case floor = 2
        case meter = 3
    }

    private let repository: MeterRepositoryProtocol

    private(set) var buildings: [MRKBuilding] = []
    private(set) var dates: [Date] = []
    private(set) var floors: [MRKFloor] = []
    private(set) var meters: [MRKMeter] = []

    private(set) var selectedDate: Date?
    private(set) var selectedBuilding: MRKBuilding?
    private(set) var selectedFloor: MRKFloor?
    private(set) var selectedMeter: MRKMeter?

    private(set) var readings: [MRKReading] = []

    /// One row per meter, derived from `readings` — see `MeterReadingSummary`.
    private(set) var meterSummaries: [MeterReadingSummary] = []

    /// meterID -> (display name, "Building - Floor N"), built once from
    /// `buildings` so cells can show context without each reading needing
    /// to carry its own meter/floor/building references.
    private var meterDisplayInfo: [UUID: (name: String, location: String)] = [:]

    /// meterID -> the meter plus its floor/building, built alongside
    /// `meterDisplayInfo` in the same loop (always populated together, so a
    /// meter present in one is present in the other). Lets a table row jump
    /// straight to Meter Details on tap without a second repository round
    /// trip (2026-08-28).
    private var meterContext: [UUID: (meter: MRKMeter, floor: MRKFloor, building: MRKBuilding)] = [:]

    /// One row per meter for the Previous Readings list: the meter's most
    /// recent reading (within whatever the current filter selects) plus how
    /// many readings make up that group. Christian asked to collapse the
    /// previously one-row-per-reading list down to this (2026-08-28).
    struct MeterReadingSummary: Identifiable, Hashable {
        let id: UUID // meterID
        let meterName: String
        let location: String
        let lastReadingDate: Date
        let lastReadingValue: Double
        let readingCount: Int
        let meter: MRKMeter
        let floor: MRKFloor
        let building: MRKBuilding

        var formattedLastReadingValue: String {
            String(format: "%.2f kWh", lastReadingValue)
        }

        var formattedLastReadingDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: lastReadingDate)
        }

        var readingCountText: String {
            readingCount == 1 ? "1 reading" : "\(readingCount) readings"
        }
    }

    init(repository: MeterRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Loading

    func loadData() async {
        buildings = (try? await repository.getBuildings()) ?? []

        var displayInfo: [UUID: (name: String, location: String)] = [:]
        var context: [UUID: (meter: MRKMeter, floor: MRKFloor, building: MRKBuilding)] = [:]
        var allReadingDates = Set<Date>()
        for building in buildings {
            for floor in building.floors {
                for meter in floor.meters {
                    let location = "\(building.name) - Floor \(floor.number)"
                    displayInfo[meter.id] = (name: meter.name, location: location)
                    context[meter.id] = (meter: meter, floor: floor, building: building)
                    for reading in meter.readings {
                        allReadingDates.insert(reading.date)
                    }
                }
            }
        }
        meterDisplayInfo = displayInfo
        meterContext = context
        dates = allReadingDates.sorted(by: >)

        print("Loaded \(self.buildings.count) buildings and \(self.dates.count) dates")
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
        meterSummaries = Self.summarize(readings, displayInfo: meterDisplayInfo, context: meterContext)

        print("Applied filters, showing \(self.readings.count) readings across \(self.meterSummaries.count) meters")
    }

    /// Groups `readings` by meter, keeping each meter's most recent reading
    /// (within the group) as the row's displayed value/date, sorted with the
    /// most-recently-read meter first — same ordering `readings` itself uses.
    private static func summarize(
        _ readings: [MRKReading],
        displayInfo: [UUID: (name: String, location: String)],
        context: [UUID: (meter: MRKMeter, floor: MRKFloor, building: MRKBuilding)]
    ) -> [MeterReadingSummary] {
        let grouped = Dictionary(grouping: readings, by: \.meterID)
        let summaries = grouped.compactMap { meterID, meterReadings -> MeterReadingSummary? in
            guard let latest = meterReadings.max(by: { $0.date < $1.date }) else { return nil }
            // `context` and `displayInfo` are always built together in the
            // same loop in `loadData()`, so this can't actually miss — the
            // guard is just a safe fallback rather than a force-unwrap.
            guard let ctx = context[meterID] else { return nil }
            let info = displayInfo[meterID]
            return MeterReadingSummary(
                id: meterID,
                meterName: info?.name ?? ctx.meter.name,
                location: info?.location ?? "",
                lastReadingDate: latest.date,
                lastReadingValue: latest.kWh,
                readingCount: meterReadings.count,
                meter: ctx.meter,
                floor: ctx.floor,
                building: ctx.building
            )
        }
        return summaries.sorted { $0.lastReadingDate > $1.lastReadingDate }
    }
}
