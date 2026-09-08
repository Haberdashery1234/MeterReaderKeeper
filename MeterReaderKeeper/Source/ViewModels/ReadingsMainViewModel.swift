//
//  ReadingsMainViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//  Converted to async/await + @MainActor on 8/27/26.
//

import Foundation

/// Business logic and repository access for the "take readings" screen for
/// one building: the floor picker's data, the meter list for the selected
/// floor, deciding whether tapping a meter should add or edit today's
/// reading, and the CSV export call. Map-overlay presentation and the QR
/// scanner stub stay in the view controller since they're pure UI.
@MainActor
final class ReadingsMainViewModel {

    /// Where tapping a meter row should navigate, decided by
    /// `readingRoute(forMeterAt:)`.
    enum ReadingRoute {
        /// No reading exists yet for today — open Add Reading.
        case add(meter: MRKMeter, floor: MRKFloor, building: MRKBuilding)
        /// A reading already exists for today — open Edit Reading on it.
        case edit(reading: MRKReading, meter: MRKMeter, floor: MRKFloor, building: MRKBuilding)
    }

    private let repository: MeterRepositoryProtocol

    /// The building readings are being taken for. Refreshed by `refreshBuilding()`.
    private(set) var building: MRKBuilding
    /// `building`'s floors, sorted by number. Refreshed by `refreshBuilding()`.
    private(set) var floors: [MRKFloor]
    /// The currently selected floor, if any.
    private(set) var floor: MRKFloor?
    /// The selected floor's meters, name-sorted.
    private(set) var meters: [MRKMeter]

    /// Creates the readings-entry view model, defaulting to the building's
    /// first floor (by number) selected.
    ///
    /// - Parameters:
    ///   - repository: The repository to load from.
    ///   - building: The building to take readings for.
    init(repository: MeterRepositoryProtocol, building: MRKBuilding) {
        self.repository = repository
        self.building = building
        let sortedFloors = building.sortedFloors
        self.floors = sortedFloors
        self.floor = sortedFloors.first
        self.meters = sortedFloors.first?.sortedMeters ?? []
        print("Loaded \(sortedFloors.count) floors for building \(building.name)")
    }

    /// Selects the floor at `row` in `floors`, reloading `meters` for it.
    ///
    /// - Parameter row: The picker row that was selected.
    /// - Returns: The newly selected floor, or `nil` if `row` is out of range.
    @discardableResult
    func selectFloor(at row: Int) -> MRKFloor? {
        guard floors.indices.contains(row) else { return nil }
        let selected = floors[row]
        floor = selected
        meters = selected.sortedMeters
        print("Selected floor: \(selected.number)")
        return selected
    }

    /// Re-fetches the current building from the repository so readings
    /// taken elsewhere (or on a previous visit to this screen) are
    /// reflected, preserving the selected floor if it still exists.
    func refreshBuilding() async {
        guard let refreshedBuilding = (try? await repository.getBuildings())?.first(where: { $0.id == building.id }) else {
            return
        }

        let selectedFloorID = floor?.id
        building = refreshedBuilding
        floors = refreshedBuilding.sortedFloors
        floor = floors.first(where: { $0.id == selectedFloorID }) ?? floors.first
        meters = floor?.sortedMeters ?? []
    }

    /// Whether tapping a meter should open Add or Edit Reading, based on
    /// whether a reading already exists for today.
    func readingRoute(forMeterAt row: Int) -> ReadingRoute? {
        guard let floor = floor, meters.indices.contains(row) else { return nil }
        let meter = meters[row]

        let date = Calendar.current.startOfDay(for: Date())
        let todaysReadings = meter.readings.filter { $0.date == date }

        if let existingReading = todaysReadings.first {
            return .edit(reading: existingReading, meter: meter, floor: floor, building: building)
        } else {
            return .add(meter: meter, floor: floor, building: building)
        }
    }

    /// Builds a CSV summary of today's readings for `building`.
    ///
    /// - Returns: The CSV file's raw UTF-8 bytes.
    /// - Throws: Whatever error the repository throws while building it.
    func getCSVData() async throws -> Data {
        try await repository.getCSVData(forBuilding: building.id)
    }
}
