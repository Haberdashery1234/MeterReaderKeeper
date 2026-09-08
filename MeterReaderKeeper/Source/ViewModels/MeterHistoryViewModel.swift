//
//  MeterHistoryViewModel.swift
//  MeterReaderKeeper
//
//  Created for the meter details screen on 2026-08-28. Reached by tapping a
//  meter row on Previous Readings: shows the meter's building/floor, most
//  recent reading, and a chart of every reading over time.
//

import Foundation

/// One bar on the reading-history chart: the kWh used between a reading and
/// the one immediately before it (rollover-corrected).
struct MeterUsagePoint {
    /// The later of the two readings' dates — the bar is plotted at this date.
    let date: Date
    /// The rollover-corrected kWh used since the previous reading.
    let kWh: Double
}

/// Business logic and repository access for the read-only Meter Details
/// screen.
@MainActor
final class MeterHistoryViewModel {

    private let repository: MeterRepositoryProtocol

    /// The meter this screen shows history for. Refreshed by `refresh()`.
    private(set) var meter: MRKMeter
    /// The meter's floor. Refreshed by `refresh()`.
    private(set) var floor: MRKFloor
    /// The meter's building. Refreshed by `refresh()`.
    private(set) var building: MRKBuilding

    /// Creates the Meter History view model.
    ///
    /// - Parameters:
    ///   - repository: The repository to load from.
    ///   - meter: The meter to show history for.
    ///   - floor: The meter's floor.
    ///   - building: The meter's building.
    init(repository: MeterRepositoryProtocol, meter: MRKMeter, floor: MRKFloor, building: MRKBuilding) {
        self.repository = repository
        self.meter = meter
        self.floor = floor
        self.building = building
    }

    /// The meter's building's name.
    var buildingName: String {
        building.name
    }

    /// The meter's floor's display name, e.g. "Floor 3".
    var floorDisplayName: String {
        floor.displayName
    }

    /// The meter's most recent reading, or `nil` if it has never been read.
    var mostRecentReading: MRKReading? {
        meter.mostRecentReading
    }

    /// Whether the meter has any readings at all.
    var hasReadings: Bool {
        !meter.readings.isEmpty
    }

    /// Whether there's enough history to plot a usage bar — needs at least
    /// two readings, since a single reading has no prior reading to diff
    /// against.
    var hasUsageData: Bool {
        !usagePoints.isEmpty
    }

    /// Message shown in place of the chart when there isn't enough data yet
    /// to plot usage.
    var chartEmptyStateMessage: String {
        meter.readings.count == 1
            ? "Add another reading to see usage over time."
            : "No readings recorded yet."
    }

    /// The most recent reading's formatted value, or an em dash if unread.
    var formattedMostRecentValue: String {
        mostRecentReading?.formattedValue ?? "\u{2013}"
    }

    /// "As of \<date\>" for the most recent reading, or an empty string if unread.
    var formattedMostRecentDate: String {
        guard let reading = mostRecentReading else { return "" }
        return "As of \(reading.formattedDate)"
    }

    /// The kWh used between each consecutive pair of readings, chronological
    /// (oldest first), rollover-corrected (see `MRKReading.usage`). An
    /// N-reading history produces N-1 usage points, since the very first
    /// reading has no prior reading to diff against. The chart shows usage
    /// since the last reading rather than the raw value (2026-08-28).
    var usagePoints: [MeterUsagePoint] {
        let readings = meter.readings.sorted { $0.date < $1.date }
        guard readings.count > 1 else { return [] }
        return zip(readings, readings.dropFirst()).map { previous, current in
            MeterUsagePoint(date: current.date, kWh: MRKReading.usage(from: previous, to: current))
        }
    }

    /// Re-fetches the meter/floor/building from the repository so the
    /// screen reflects any reading added elsewhere since navigating here
    /// (e.g. from Home's "Needs Attention" or Take Readings). Falls back to
    /// whatever was passed at construction if the refresh fails or the
    /// meter/floor no longer exists — matches this app's existing
    /// `try?`-and-keep-going pattern elsewhere (e.g. `HomeViewModel.loadSummary()`).
    ///
    /// - Note: Silently keeps the previous `meter`/`floor`/`building` on failure.
    func refresh() async {
        guard let refreshedBuilding = try? await repository.getBuilding(id: building.id) else { return }
        guard let refreshedFloor = refreshedBuilding.floors.first(where: { $0.id == floor.id }) else { return }
        guard let refreshedMeter = refreshedFloor.meters.first(where: { $0.id == meter.id }) else { return }
        building = refreshedBuilding
        floor = refreshedFloor
        meter = refreshedMeter
    }
}
