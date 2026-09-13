//
//  ManagementViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//  Converted to async/await + @MainActor on 8/27/26.
//

import Foundation
import Combine
import os

/// Business logic and repository access for the Management screen (the
/// segmented Buildings/Floors/Meters list).
///
/// The three lists are `@Published` so a subscriber could react to
/// reloads, though the view controller currently just calls `loadData()`
/// then reloads its table synchronously right after, the same point the
/// original screen refreshed at.
@MainActor
final class ManagementViewModel {

    /// The Management screen's segmented control.
    enum Segment: Int, CaseIterable {
        case buildings = 0
        case floors = 1
        case meters = 2
    }

    /// One row in the Floors segment: a floor plus the building it belongs to.
    struct FloorItem {
        let floor: MRKFloor
        let building: MRKBuilding
    }

    /// One row in the Meters segment: a meter plus its floor and building.
    struct MeterItem {
        let meter: MRKMeter
        let floor: MRKFloor
        let building: MRKBuilding
    }

    /// One building's worth of rows for a grouped (sectioned) list. The
    /// Floors/Meters segments used to list every floor/meter from every
    /// building in one flat list with no indication of which building they
    /// belonged to, which stopped making sense once there's more than one
    /// building (2026-08-28). `items` is never empty —
    /// `floorSections`/`meterSections` below drop any building with
    /// nothing to show in that segment.
    struct BuildingSection<Item> {
        /// The building this section groups rows under.
        let building: MRKBuilding
        /// The section's rows (never empty — see the type-level note above).
        let items: [Item]
    }

    private let repository: MeterRepositoryProtocol

    /// Every building, name-sorted. Reloaded by `loadData()`.
    @Published private(set) var buildings: [MRKBuilding] = []
    /// Every floor across every building, flattened. Reloaded by `loadData()`.
    @Published private(set) var floorItems: [FloorItem] = []
    /// Every meter across every building, flattened. Reloaded by `loadData()`.
    @Published private(set) var meterItems: [MeterItem] = []

    /// Creates the Management view model.
    ///
    /// - Parameter repository: The repository to load buildings/floors/meters from.
    init(repository: MeterRepositoryProtocol) {
        self.repository = repository
    }

    /// True once there's at least one floor to attach a meter to, matching
    /// the original screen's "only offer to add a Meter if a floor exists"
    /// rule.
    var hasFloors: Bool { !floorItems.isEmpty }

    /// `floorItems` grouped into one section per building, in the same
    /// building order (`buildings`, sorted by name). A building with no
    /// floors is impossible today (creating one always seeds at least 1),
    /// but the filter is here for the same reason `meterSections` needs
    /// one — consistency, and safety if that ever changes.
    var floorSections: [BuildingSection<FloorItem>] {
        buildings.compactMap { building in
            let items = floorItems.filter { $0.building.id == building.id }
            return items.isEmpty ? nil : BuildingSection(building: building, items: items)
        }
    }

    /// `meterItems` grouped into one section per building. Unlike floors, a
    /// building with zero meters is common (e.g. right after its floors
    /// are created), so that building is simply omitted from this list
    /// rather than shown as an empty section.
    var meterSections: [BuildingSection<MeterItem>] {
        buildings.compactMap { building in
            let items = meterItems.filter { $0.building.id == building.id }
            return items.isEmpty ? nil : BuildingSection(building: building, items: items)
        }
    }

    /// Fetches every building and rebuilds `buildings`, `floorItems`, and
    /// `meterItems` from it. Call this, then reload the table.
    func loadData() async {
        buildings = (try? await repository.getBuildings()) ?? []

        floorItems = buildings.flatMap { building in
            building.sortedFloors.map { FloorItem(floor: $0, building: building) }
        }

        meterItems = buildings.flatMap { building in
            building.sortedFloors.flatMap { floor in
                floor.sortedMeters.map { MeterItem(meter: $0, floor: floor, building: building) }
            }
        }

        AppLogger.viewModel.debug("Loaded \(self.buildings.count) buildings, \(self.floorItems.count) floors, \(self.meterItems.count) meters")
    }
}
