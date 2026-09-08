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

    /// The Previous Readings screen's cascading filter picker.
    enum FilterSegment: Int, CaseIterable {
        case date = 0
        case building = 1
        case floor = 2
        case meter = 3
    }

    private let repository: MeterRepositoryProtocol

    /// Every building, name-sorted. Loaded by `loadData()`.
    private(set) var buildings: [MRKBuilding] = []
    /// Every distinct reading date across every meter, most recent first.
    /// Loaded by `loadData()`.
    private(set) var dates: [Date] = []
    /// The selected building's floors, sorted by number. Populated by `selectBuilding(at:)`.
    private(set) var floors: [MRKFloor] = []
    /// The selected floor's meters, name-sorted. Populated by `selectFloor(at:)`.
    private(set) var meters: [MRKMeter] = []

    /// The Date filter's current selection, or `nil` for "All".
    private(set) var selectedDate: Date?
    /// The Building filter's current selection, or `nil` for "All".
    private(set) var selectedBuilding: MRKBuilding?
    /// The Floor filter's current selection, or `nil` for "All".
    private(set) var selectedFloor: MRKFloor?
    /// The Meter filter's current selection, or `nil` for "All".
    private(set) var selectedMeter: MRKMeter?

    /// The readings matching the current filter, most recent first.
    /// Populated by `applyFilters(segment:)`.
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
    /// many readings make up that group. Collapsed from a previous
    /// one-row-per-reading list down to this grouped form (2026-08-28).
    struct MeterReadingSummary: Identifiable, Hashable {
        let id: UUID // meterID
        let meterName: String
        /// "Building - Floor N".
        let location: String
        /// The most recent reading date within the current filter's matches.
        let lastReadingDate: Date
        /// The most recent reading's value within the current filter's matches.
        let lastReadingValue: Double
        /// How many readings for this meter match the current filter (not
        /// the meter's lifetime total — see open follow-up in project notes).
        let readingCount: Int
        let meter: MRKMeter
        let floor: MRKFloor
        let building: MRKBuilding

        /// `lastReadingValue` formatted for display, e.g. "245.10 kWh".
        var formattedLastReadingValue: String {
            String(format: "%.2f kWh", lastReadingValue)
        }

        /// `lastReadingDate` formatted for display as a medium-style date.
        var formattedLastReadingDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: lastReadingDate)
        }

        /// "1 reading" or "`N` readings".
        var readingCountText: String {
            readingCount == 1 ? "1 reading" : "\(readingCount) readings"
        }
    }

    /// Creates the Previous Readings view model.
    ///
    /// - Parameter repository: The repository to load readings from.
    init(repository: MeterRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Loading

    /// Fetches every building and rebuilds `buildings`, `dates`, and the
    /// internal meter lookup tables from it. Call this before applying any filter.
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

    /// Every reading across every building, unfiltered and unsorted.
    private func allReadings() -> [MRKReading] {
        buildings.flatMap { building in
            building.floors.flatMap { floor in
                floor.meters.flatMap { $0.readings }
            }
        }
    }

    /// The cached name/location text for a reading's meter, or `nil` if
    /// `loadData()` hasn't populated it (or the meter no longer exists).
    func displayInfo(for reading: MRKReading) -> (name: String, location: String)? {
        meterDisplayInfo[reading.meterID]
    }

    // MARK: - Filter selection
    // Each picker's row 0 is always "All" (`nil`), matching the original
    // screen's picker convention.

    /// Selects the Date filter's picker row.
    func selectDate(at row: Int) {
        selectedDate = row == 0 ? nil : dates[row - 1]
    }

    /// Selects the Building filter's picker row, resetting the
    /// dependent Floor/Meter selections and reloading `floors`.
    func selectBuilding(at row: Int) {
        selectedBuilding = row == 0 ? nil : buildings[row - 1]
        floors = selectedBuilding?.sortedFloors ?? []
        selectedFloor = nil
        meters = []
        selectedMeter = nil
    }

    /// Selects the Floor filter's picker row, resetting the dependent
    /// Meter selection and reloading `meters`.
    func selectFloor(at row: Int) {
        selectedFloor = row == 0 ? nil : floors[row - 1]
        meters = selectedFloor?.sortedMeters ?? []
        selectedMeter = nil
    }

    /// Selects the Meter filter's picker row.
    func selectMeter(at row: Int) {
        selectedMeter = row == 0 ? nil : meters[row - 1]
    }

    // MARK: - Filtering

    /// Filters `allReadings()` by whichever segment's selection is
    /// currently set, then rebuilds `readings` and `meterSummaries` from
    /// the result.
    ///
    /// - Parameter segment: Which filter picker's current selection to apply.
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
