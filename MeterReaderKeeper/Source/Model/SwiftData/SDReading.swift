//
//  SDReading.swift
//  MeterReaderKeeper
//
//  Migrated to SwiftData on 8/26/26.
//

import Foundation
import SwiftData

/// SwiftData-backed reading entity. See `SDBuilding` for the module-boundary
/// note that applies to every file in this directory.
@Model
final class SDReading {
    /// Stable, uniquely-constrained identity for this reading.
    @Attribute(.unique) var id: UUID
    /// The date this reading was recorded.
    var date: Date
    /// The raw meter value, in kilowatt-hours.
    var kWh: Double
    /// The meter this reading belongs to. Optional because SwiftData
    /// relationships must be optional on the "to-one" side.
    var meter: SDMeter?

    /// Creates a new reading record.
    ///
    /// - Parameters:
    ///   - id: The reading's identity. Defaults to a freshly generated UUID.
    ///   - date: The date this reading was recorded.
    ///   - kWh: The raw meter value, in kilowatt-hours.
    ///   - meter: The meter this reading belongs to.
    init(id: UUID = UUID(), date: Date, kWh: Double, meter: SDMeter?) {
        self.id = id
        self.date = date
        self.kWh = kWh
        self.meter = meter
    }

    /// Exports reading data to a dictionary for serialization.
    ///
    /// - Returns: A `[String: Any]` dictionary with `"date"` and `"kWh"`.
    func getExportDictionary() -> [String: Any] {
        [
            "date": date as Any,
            "kWh": kWh as Any
        ]
    }
}
