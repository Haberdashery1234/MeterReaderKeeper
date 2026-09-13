//
//  ReadingsMainViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//  Converted to async/await + @MainActor on 8/27/26.
//

import Foundation
import os

/// Business logic and repository access for the "take readings" screen for
/// one building: the floor picker's data, the meter list for the selected
/// floor, deciding whether tapping a meter should add or edit today's
/// reading, resolving a scanned QR code to a meter, and the CSV export
/// call. Map-overlay presentation and the QR scanner screen itself stay in
/// the view controller since they're pure UI.
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
        AppLogger.viewModel.debug("Loaded \(sortedFloors.count) floors for building \(building.name, privacy: .public)")
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
        AppLogger.viewModel.debug("Selected floor: \(selected.number)")
        return selected
    }

    /// Selects `floor` if it's one of `floors`, reloading `meters` for it —
    /// like `selectFloor(at:)`, but by floor identity rather than picker
    /// row. Used after a QR scan resolves to a meter on a floor other than
    /// the one currently selected.
    ///
    /// - Returns: `floor` if it was found and selected, otherwise `nil`.
    @discardableResult
    func selectFloor(matching floor: MRKFloor) -> MRKFloor? {
        guard let row = floors.firstIndex(where: { $0.id == floor.id }) else { return nil }
        return selectFloor(at: row)
    }

    /// Re-fetches the current building from the repository so readings
    /// taken elsewhere (or on a previous visit to this screen) are
    /// reflected, preserving the selected floor if it still exists.
    func refreshBuilding() async {
        guard let refreshedBuilding = try? await repository.getBuilding(id: building.id) else {
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
        return readingRoute(for: meters[row], floor: floor)
    }

    /// Whether `meter` (on `floor`) should open Add or Edit Reading, based
    /// on whether a reading already exists for today. Shared by
    /// `readingRoute(forMeterAt:)` and `resolveScannedCode(_:)`, which may
    /// resolve a meter on a floor other than the one currently selected.
    private func readingRoute(for meter: MRKMeter, floor: MRKFloor) -> ReadingRoute {
        let date = Calendar.current.startOfDay(for: Date())
        let todaysReadings = meter.readings.filter { $0.date == date }

        if let existingReading = todaysReadings.first {
            return .edit(reading: existingReading, meter: meter, floor: floor, building: building)
        } else {
            return .add(meter: meter, floor: floor, building: building)
        }
    }

    /// The outcome of resolving a scanned QR code against this building's
    /// meters, keyed by `MRKMeter.qrString`.
    enum QRScanResult {
        /// Exactly one meter matched. `floor` is that meter's floor,
        /// which may differ from the currently selected `floor`.
        case matched(route: ReadingRoute, floor: MRKFloor)
        /// Zero (or, if two meters ended up with the same name on the
        /// same floor, more than one) meters matched. `count` is how many.
        case unmatched(count: Int)
    }

    /// Resolves a scanned QR code to a meter within `building`, searching
    /// every floor (not just the currently selected one).
    func resolveScannedCode(_ codeString: String) -> QRScanResult {
        let matches = floors.flatMap { floor in
            floor.sortedMeters
                .filter { $0.qrString == codeString }
                .map { (meter: $0, floor: floor) }
        }
        guard matches.count == 1, let match = matches.first else {
            return .unmatched(count: matches.count)
        }
        return .matched(route: readingRoute(for: match.meter, floor: match.floor), floor: match.floor)
    }

    /// Builds a CSV summary of today's readings for `building`.
    ///
    /// - Returns: The CSV file's raw UTF-8 bytes.
    /// - Throws: Whatever error the repository throws while building it.
    func getCSVData() async throws -> Data {
        try await repository.getCSVData(forBuilding: building.id)
    }
}
