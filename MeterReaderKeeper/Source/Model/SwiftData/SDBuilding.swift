//
//  SDBuilding.swift
//  MeterReaderKeeper
//
//  Migrated to SwiftData on 8/26/26.
//

import Foundation
import SwiftData

/// SwiftData-backed building entity.
///
/// This is the *only* place in the app (besides the other `Model/SwiftData`
/// files and `SwiftDataMeterRepository`) that should import `SwiftData` or
/// touch these `@Model` classes directly. Everything above the repository
/// layer — view models, views — works exclusively with the plain
/// `MRKBuilding` domain struct in `Model/Domain`.
///
/// This has a real persisted `id` attribute instead of one derived from
/// an object identifier — a long-standing "would be nice to have a real
/// id" goal that's now satisfied.
@Model
final class SDBuilding {
    /// Stable, uniquely-constrained identity for this building.
    @Attribute(.unique) var id: UUID
    /// The building's display name.
    var name: String

    /// This building's floors. Cascade-deleting a building deletes every
    /// floor (and, transitively, every meter and reading) that belongs to it.
    @Relationship(deleteRule: .cascade, inverse: \SDFloor.building)
    var floors: [SDFloor] = []

    /// Creates a new building record.
    ///
    /// - Parameters:
    ///   - id: The building's identity. Defaults to a freshly generated UUID.
    ///   - name: The building's display name.
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    /// Exports building data to a dictionary for serialization. Floors are
    /// explicitly sorted by number — SwiftData to-many relationships don't
    /// guarantee stored insertion order, so this can't rely on `floors`
    /// already being in a sensible order.
    ///
    /// - Returns: A `[String: Any]` dictionary with a `"name"` string and a
    ///   `"floors"` array of each floor's own export dictionary.
    func getExportDictionary() -> [String: Any] {
        var exportDict: [String: Any] = [:]
        exportDict["name"] = name

        let sortedFloors = floors.sorted { $0.number < $1.number }
        exportDict["floors"] = sortedFloors.map { $0.getExportDictionary() }

        return exportDict
    }
}
