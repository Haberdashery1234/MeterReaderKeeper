//
//  FloorMetersViewModel.swift
//  MeterReaderKeeper
//
//  Created for the Floor Meters screen on 2026-08-28. Reached by tapping a
//  Floor row in Management: lists the floor's meters, supports adding and
//  deleting a meter on this floor, and shows each meter's last reading
//  date and value.
//
//  This replaces `showFloorDetails` (the Add/Edit Floor form) as the
//  destination for a Floor row tap in Management — that form is still
//  reachable from here via an Edit button, since it's the only place a
//  floor's own map image can be set.
//

import Foundation

/// Business logic and repository access for the Floor Meters screen.
@MainActor
final class FloorMetersViewModel {

    private let repository: MeterRepositoryProtocol

    /// The floor's building. Refreshed by `loadData()`.
    private(set) var building: MRKBuilding
    /// The floor whose meters this screen lists. Refreshed by `loadData()`.
    private(set) var floor: MRKFloor
    /// `floor`'s meters, name-sorted. Refreshed by `loadData()`.
    private(set) var meters: [MRKMeter] = []

    /// Creates the Floor Meters view model.
    ///
    /// - Parameters:
    ///   - repository: The repository to load from and delete through.
    ///   - floor: The floor whose meters to list.
    ///   - building: The floor's building.
    init(repository: MeterRepositoryProtocol, floor: MRKFloor, building: MRKBuilding) {
        self.repository = repository
        self.floor = floor
        self.building = building
        self.meters = floor.sortedMeters
    }

    /// The floor's display name, e.g. "Floor 3".
    var floorDisplayName: String { floor.displayName }
    /// The floor's building's name.
    var buildingName: String { building.name }

    /// Whether the floor currently has any meters.
    var hasMeters: Bool { !meters.isEmpty }

    /// Re-fetches the building (and this floor within it) from the
    /// repository, so meters added/deleted here — or floor/building
    /// changes made elsewhere — are reflected. If the floor has since
    /// been deleted out from under this screen (e.g. its building's
    /// floor count was reduced from the Management screen while this
    /// screen was also open), `floor`/`meters` are simply left as they
    /// were rather than crashing; the view controller is expected to be
    /// popped in that case by the user backing out, not by this method.
    func loadData() async {
        guard let refreshedBuilding = try? await repository.getBuilding(id: building.id),
              let refreshedFloor = refreshedBuilding.floors.first(where: { $0.id == floor.id }) else {
            return
        }
        building = refreshedBuilding
        floor = refreshedFloor
        meters = refreshedFloor.sortedMeters
    }

    /// Deletes a meter (and its reading history, via the repository's
    /// existing cascade) and reloads.
    ///
    /// - Parameter meter: The meter to delete.
    /// - Throws: Whatever error the repository throws while deleting.
    func deleteMeter(_ meter: MRKMeter) async throws {
        try await repository.deleteMeter(id: meter.id)
        await loadData()
    }
}
