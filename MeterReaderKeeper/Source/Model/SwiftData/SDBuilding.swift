//
//  SDBuilding.swift
//  MeterReaderKeeper
//
//  Created by Core Data -> SwiftData Migration on 8/26/26.
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
/// Unlike the Core Data entity it replaces, this has a real persisted `id`
/// attribute instead of one derived from an object identifier — the
/// long-standing "would be nice to have a real id" item from the Core Data
/// repository's docs.
@Model
final class SDBuilding {
    @Attribute(.unique) var id: UUID
    var name: String

    @Relationship(deleteRule: .cascade, inverse: \SDFloor.building)
    var floors: [SDFloor] = []

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    /// Exports building data to a dictionary for serialization. Floors are
    /// explicitly sorted by number — SwiftData to-many relationships don't
    /// guarantee stored insertion order the way Core Data's `NSOrderedSet`
    /// did, so (unlike the Core Data version of this method) this can't
    /// rely on `floors` already being in a sensible order.
    func getExportDictionary() -> [String: Any] {
        var exportDict: [String: Any] = [:]
        exportDict["name"] = name

        let sortedFloors = floors.sorted { $0.number < $1.number }
        exportDict["floors"] = sortedFloors.map { $0.getExportDictionary() }

        return exportDict
    }
}
