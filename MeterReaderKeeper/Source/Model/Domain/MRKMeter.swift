//
//  MRKMeter.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation

/// Represents a meter on a floor
struct MRKMeter: Identifiable, Hashable {
    let id: UUID
    let name: String
    let meterDescription: String
    let qrString: String
    let imageData: Data
    let latestReadingDate: Date
    let floorID: UUID
    let readings: [MRKReading]
    
    /// Gets the most recent reading, if available
    var mostRecentReading: MRKReading? {
        sortedReadings.first
    }
    
    /// Retrieves readings sorted by date (most recent first)
    var sortedReadings: [MRKReading] {
        readings.sorted { $0.date > $1.date }
    }
    
    /// Validates meter data
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Meter name"))
        }
    }
}

/// Data required to create or update a meter
struct MRKMeterInput {
    let name: String
    let description: String
    let imageData: Data
    let floorID: UUID
    
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Meter name"))
        }
    }
}
