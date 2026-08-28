//
//  MeterHistoryViewModel.swift
//  MeterReaderKeeper
//
//  Created for the meter details screen on 2026-08-28. Reached by tapping a
//  meter row on Previous Readings: shows the meter's building/floor, most
//  recent reading, and a chart of every reading over time.
//

import Foundation

/// Business logic and repository access for the read-only Meter Details
/// screen.
@MainActor
final class MeterHistoryViewModel {

    private let repository: MeterRepositoryProtocol

    private(set) var meter: MRKMeter
    private(set) var floor: MRKFloor
    private(set) var building: MRKBuilding

    init(repository: MeterRepositoryProtocol, meter: MRKMeter, floor: MRKFloor, building: MRKBuilding) {
        self.repository = repository
        self.meter = meter
        self.floor = floor
        self.building = building
    }

    var buildingName: String {
        building.name
    }

    var floorDisplayName: String {
        floor.displayName
    }

    var mostRecentReading: MRKReading? {
        meter.mostRecentReading
    }

    var hasReadings: Bool {
        !meter.readings.isEmpty
    }

    var formattedMostRecentValue: String {
        mostRecentReading?.formattedValue ?? "\u{2013}"
    }

    var formattedMostRecentDate: String {
        guard let reading = mostRecentReading else { return "" }
        return "As of \(reading.formattedDate)"
    }

    /// Every reading for this meter, chronological (oldest first) — the
    /// order Swift Charts expects to plot left-to-right.
    var chartPoints: [MRKReading] {
        meter.readings.sorted { $0.date < $1.date }
    }

    /// Re-fetches the meter/floor/building from the repository so the
    /// screen reflects any reading added elsewhere since navigating here
    /// (e.g. from Home's "Needs Attention" or Take Readings). Falls back to
    /// whatever was passed at construction if the refresh fails or the
    /// meter/floor no longer exists — matches this app's existing
    /// `try?`-and-keep-going pattern elsewhere (e.g. `HomeViewModel.loadSummary()`).
    func refresh() async {
        guard let refreshedBuilding = try? await repository.getBuilding(id: building.id) else { return }
        guard let refreshedFloor = refreshedBuilding.floors.first(where: { $0.id == floor.id }) else { return }
        guard let refreshedMeter = refreshedFloor.meters.first(where: { $0.id == meter.id }) else { return }
        building = refreshedBuilding
        floor = refreshedFloor
        meter = refreshedMeter
    }
}
