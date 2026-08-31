//
//  SDFloor.swift
//  MeterReaderKeeper
//
//  Migrated to SwiftData on 8/26/26.
//

import Foundation
import SwiftData

/// SwiftData-backed floor entity. See `SDBuilding` for the module-boundary
/// note that applies to every file in this directory.
@Model
final class SDFloor {
    /// Stable, uniquely-constrained identity for this floor.
    @Attribute(.unique) var id: UUID
    /// The floor's 1-based number within its building.
    var number: Int16
    /// Raw image data for the floor's map, or empty `Data()` if unset.
    var mapImageData: Data
    /// The building this floor belongs to. Optional because SwiftData
    /// relationships must be optional on the "to-one" side.
    var building: SDBuilding?

    /// This floor's meters. Cascade-deleting a floor deletes every meter
    /// (and, transitively, every reading) that belongs to it.
    @Relationship(deleteRule: .cascade, inverse: \SDMeter.floor)
    var meters: [SDMeter] = []

    /// Creates a new floor record.
    ///
    /// - Parameters:
    ///   - id: The floor's identity. Defaults to a freshly generated UUID.
    ///   - number: The floor's 1-based number within its building.
    ///   - mapImageData: Raw image data for the floor's map, or empty `Data()`.
    ///   - building: The building this floor belongs to.
    init(id: UUID = UUID(), number: Int16, mapImageData: Data, building: SDBuilding?) {
        self.id = id
        self.number = number
        self.mapImageData = mapImageData
        self.building = building
    }

    /// Exports floor data to a dictionary for serialization. Meters are
    /// explicitly sorted by name for the same reason `SDBuilding.getExportDictionary()`
    /// sorts its floors — SwiftData doesn't guarantee relationship storage order.
    ///
    /// - Returns: A `[String: Any]` dictionary with the floor's `"number"`,
    ///   a size-compressed `"map"` image, and a `"meters"` array of each
    ///   meter's own export dictionary.
    func getExportDictionary() -> [String: Any] {
        var exportDict: [String: Any] = [:]
        exportDict["number"] = number

        // Compress map image for export
        if let compressedMap = UIService.shared.getExportSizeImageData(from: mapImageData, ofMaxSizeMB: 0.25) {
            exportDict["map"] = compressedMap
        } else {
            exportDict["map"] = Data()
        }

        let sortedMeters = meters.sorted { $0.name < $1.name }
        exportDict["meters"] = sortedMeters.map { $0.getExportDictionary() }

        return exportDict
    }
}
