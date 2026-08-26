//
//  ManagementViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//

import Foundation
import Combine
import os.log

/// Business logic and repository access for the Management screen (the
/// segmented Buildings/Floors/Meters list).
///
/// The three lists are `@Published` so a subscriber could react to
/// reloads, though the view controller currently just calls `loadData()`
/// then reloads its table synchronously in `viewWillAppear`, the same
/// point the original screen refreshed at.
final class ManagementViewModel {

    enum Segment: Int, CaseIterable {
        case buildings = 0
        case floors = 1
        case meters = 2
    }

    struct FloorItem {
        let floor: MRKFloor
        let building: MRKBuilding
    }

    struct MeterItem {
        let meter: MRKMeter
        let floor: MRKFloor
        let building: MRKBuilding
    }

    private let repository: MeterRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "ManagementViewModel")

    @Published private(set) var buildings: [MRKBuilding] = []
    @Published private(set) var floorItems: [FloorItem] = []
    @Published private(set) var meterItems: [MeterItem] = []

    init(repository: MeterRepositoryProtocol) {
        self.repository = repository
    }

    /// True once there's at least one floor to attach a meter to, matching
    /// the original screen's "only offer to add a Meter if a floor exists"
    /// rule.
    var hasFloors: Bool { !floorItems.isEmpty }

    func loadData() {
        buildings = (try? repository.getBuildings()) ?? []

        floorItems = buildings.flatMap { building in
            building.sortedFloors.map { FloorItem(floor: $0, building: building) }
        }

        meterItems = buildings.flatMap { building in
            building.sortedFloors.flatMap { floor in
                floor.sortedMeters.map { MeterItem(meter: $0, floor: floor, building: building) }
            }
        }

        logger.info("Loaded \(self.buildings.count) buildings, \(self.floorItems.count) floors, \(self.meterItems.count) meters")
    }
}
