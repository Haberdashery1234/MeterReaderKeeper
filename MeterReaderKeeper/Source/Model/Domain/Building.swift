//
//  Building.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation

// MARK: - Domain Models (No Core Data Dependencies)

/// Represents a building with multiple floors
struct Building: Identifiable, Hashable {
    let id: UUID
    let name: String
    let floors: [Floor]
    
    /// Total number of meters in this building
    var totalMeterCount: Int {
        floors.reduce(0) { $0 + $1.meters.count }
    }
    
    /// Retrieves floors sorted by floor number
    var sortedFloors: [Floor] {
        floors.sorted { $0.number < $1.number }
    }
    
    /// Validates building data
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Building name"))
        }
    }
}

/// Data required to create or update a building
struct BuildingInput {
    let name: String
    let numberOfFloors: Int16
    let autoCreateFloors: Bool
    
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Building name"))
        }
        guard numberOfFloors > 0 && numberOfFloors <= 200 else {
            throw MeterKeeperError.validationError(.invalidInput("Floor count must be between 1 and 200"))
        }
    }
}
