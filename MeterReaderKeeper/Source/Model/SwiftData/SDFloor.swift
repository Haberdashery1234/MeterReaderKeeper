//
//  SDFloor.swift
//  MeterReaderKeeper
//
//  Created by Core Data -> SwiftData Migration on 8/26/26.
//

import Foundation
import SwiftData

/// SwiftData-backed floor entity. See `SDBuilding` for the module-boundary
/// note that applies to every file in this directory.
@Model
final class SDFloor {
    @Attribute(.unique) var id: UUID
    var number: Int16
    var mapImageData: Data
    var building: SDBuilding?

    @Relationship(deleteRule: .cascade, inverse: \SDMeter.floor)
    var meters: [SDMeter] = []

    init(id: UUID = UUID(), number: Int16, mapImageData: Data, building: SDBuilding?) {
        self.id = id
        self.number = number
        self.mapImageData = mapImageData
        self.building = building
    }

    /// Exports floor data to a dictionary for serialization. Meters are
    /// explicitly sorted by name for the same reason `SDBuilding.getExportDictionary()`
    /// sorts its floors — SwiftData doesn't guarantee relationship storage order.
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
