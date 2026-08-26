//
//  Floor.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation

/// Represents a floor within a building
struct Floor: Identifiable, Hashable {
    let id: UUID
    let number: Int16
    let mapImageData: Data
    let buildingID: UUID
    let meters: [Meter]
    
    /// Display name for the floor
    var displayName: String {
        "Floor \(number)"
    }
    
    /// Retrieves meters sorted by name
    var sortedMeters: [Meter] {
        meters.sorted { $0.name < $1.name }
    }
}

/// Data required to create or update a floor
struct FloorInput {
    let number: Int16
    let mapImageData: Data
    let buildingID: UUID
}
