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

    enum ReadingRoute {
        case add(meter: MRKMeter, floor: MRKFloor, building: MRKBuilding)
        case edit(reading: MRKReading, meter: MRKMeter, floor: MRKFloor, building: MRKBuilding)
    }

    private let repository: MeterRepositoryProtocol

    private(set) var building: MRKBuilding
    private(set) var floors: [MRKFloor]
    private(set) var floor: MRKFloor?
    private(set) var meters: [MRKMeter]

    init(repository: MeterRepositoryProtocol, building: MRKBuilding) {
        self.repository = repository
        self.building = building
        let sortedFloors = building.sortedFloors
        self.floors = sortedFloors
        self.floor = sortedFloors.first
        self.meters = sortedFloors.first?.sortedMeters ?? []
        print("Loaded \(sortedFloors.count) floors for building \(building.name)")
    }

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

    func getCSVData() async throws -> Data {
        try await repository.getCSVData(forBuilding: building.id)
    }
}
