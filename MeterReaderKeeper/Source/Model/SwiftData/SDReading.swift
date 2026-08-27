//
//  SDReading.swift
//  MeterReaderKeeper
//
//  Created by Core Data -> SwiftData Migration on 8/26/26.
//

import Foundation
import SwiftData

/// SwiftData-backed reading entity. See `SDBuilding` for the module-boundary
/// note that applies to every file in this directory.
@Model
final class SDReading {
    @Attribute(.unique) var id: UUID
    var date: Date
    var kWh: Double
    var meter: SDMeter?

    init(id: UUID = UUID(), date: Date, kWh: Double, meter: SDMeter?) {
        self.id = id
        self.date = date
        self.kWh = kWh
        self.meter = meter
    }

    /// Exports reading data to a dictionary for serialization.
    func getExportDictionary() -> [String: Any] {
        [
            "date": date as Any,
            "kWh": kWh as Any
        ]
    }
}
