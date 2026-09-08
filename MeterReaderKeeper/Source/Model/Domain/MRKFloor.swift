//
//  MRKFloor.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation

/// A single floor within a `MRKBuilding`, identified by a 1-based floor
/// number that is contiguous within its building.
struct MRKFloor: Identifiable, Hashable {
    /// Stable identity for the floor, shared with its SwiftData record.
    let id: UUID

    /// The floor's 1-based number within its building (floor numbers are
    /// contiguous per building — see the Management screen's floor-count
    /// reconciliation for how that invariant is maintained).
    let number: Int16

    /// Raw image data for the floor's map, or empty `Data()` if none has
    /// been set (seed data never populates this).
    let mapImageData: Data

    /// The `id` of the `MRKBuilding` this floor belongs to.
    let buildingID: UUID

    /// The meters located on this floor, in no particular order. Use
    /// `sortedMeters` for a name-ordered list.
    let meters: [MRKMeter]

    /// A user-facing label for the floor, e.g. "Floor 3".
    var displayName: String {
        "Floor \(number)"
    }

    /// `meters` sorted alphabetically by name.
    var sortedMeters: [MRKMeter] {
        meters.sorted { $0.name < $1.name }
    }
}

/// The data needed to create or update a floor.
struct MRKFloorInput {
    /// The floor's 1-based number within its building.
    let number: Int16

    /// Raw image data for the floor's map; pass empty `Data()` if none.
    let mapImageData: Data

    /// The `id` of the `MRKBuilding` this floor belongs to.
    let buildingID: UUID
}
