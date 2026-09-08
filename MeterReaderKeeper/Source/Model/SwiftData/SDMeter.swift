//
//  SDMeter.swift
//  MeterReaderKeeper
//
//  Migrated to SwiftData on 8/26/26.
//

import Foundation
import SwiftData

/// SwiftData-backed meter entity. See `SDBuilding` for the module-boundary
/// note that applies to every file in this directory.
@Model
final class SDMeter {
    /// Stable, uniquely-constrained identity for this meter.
    @Attribute(.unique) var id: UUID
    /// The meter's display name.
    var name: String
    /// A free-form description of the meter (e.g. what it serves).
    var meterDescription: String
    /// The string encoded in this meter's QR label.
    var qrString: String
    /// Raw image data for a photo of the meter, or empty `Data()` if unset.
    var imageData: Data
    /// The date of this meter's most recent reading, or `.distantPast` if
    /// it has never been read.
    var latestReading: Date
    /// The floor this meter is located on. Optional because SwiftData
    /// relationships must be optional on the "to-one" side.
    var floor: SDFloor?

    /// This meter's full reading history. Cascade-deleting a meter deletes
    /// every reading that belongs to it.
    @Relationship(deleteRule: .cascade, inverse: \SDReading.meter)
    var readings: [SDReading] = []

    /// Creates a new meter record.
    ///
    /// - Parameters:
    ///   - id: The meter's identity. Defaults to a freshly generated UUID.
    ///   - name: The meter's display name.
    ///   - meterDescription: A free-form description of the meter.
    ///   - qrString: The string encoded in this meter's QR label.
    ///   - imageData: Raw image data for a photo of the meter, or empty `Data()`.
    ///   - latestReading: The date of the most recent reading, or `.distantPast`.
    ///   - floor: The floor this meter is located on.
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
    ///
    /// - Returns: A `[String: Any]` dictionary with the meter's `"name"`,
    ///   `"meterDescription"`, `"qrString"`, `"latestReading"`, a
    ///   size-compressed `"image"`, and a `"readings"` array of each
    ///   reading's own export dictionary.
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
