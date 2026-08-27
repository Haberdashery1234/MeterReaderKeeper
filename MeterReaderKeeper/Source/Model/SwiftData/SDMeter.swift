//
//  SDMeter.swift
//  MeterReaderKeeper
//
//  Created by Core Data -> SwiftData Migration on 8/26/26.
//

import Foundation
import SwiftData

/// SwiftData-backed meter entity. See `SDBuilding` for the module-boundary
/// note that applies to every file in this directory.
@Model
final class SDMeter {
    @Attribute(.unique) var id: UUID
    var name: String
    var meterDescription: String
    var qrString: String
    var imageData: Data
    var latestReading: Date
    var floor: SDFloor?

    @Relationship(deleteRule: .cascade, inverse: \SDReading.meter)
    var readings: [SDReading] = []

    init(
        id: UUID = UUID(),
        name: String,
        meterDescription: String,
        qrString: String,
        imageData: Data,
        latestReading: Date,
        floor: SDFloor?
    ) {
        self.id = id
        self.name = name
        self.meterDescription = meterDescription
        self.qrString = qrString
        self.imageData = imageData
        self.latestReading = latestReading
        self.floor = floor
    }

    /// Exports meter data to a dictionary for serialization, including all
    /// readings. Readings are explicitly sorted most-recent-first for the
    /// same reason `SDBuilding.getExportDictionary()` sorts its floors —
    /// SwiftData doesn't guarantee relationship storage order.
    func getExportDictionary() -> [String: Any] {
        var exportDict: [String: Any] = [:]

        exportDict["name"] = name
        exportDict["meterDescription"] = meterDescription
        exportDict["qrString"] = qrString
        exportDict["latestReading"] = latestReading

        // Compress image for export
        if let compressedImage = UIService.shared.getExportSizeImageData(from: imageData, ofMaxSizeMB: 0.25) {
            exportDict["image"] = compressedImage
        } else {
            exportDict["image"] = Data()
        }

        let sortedReadings = readings.sorted { $0.date > $1.date }
        exportDict["readings"] = sortedReadings.map { $0.getExportDictionary() }

        return exportDict
    }
}
