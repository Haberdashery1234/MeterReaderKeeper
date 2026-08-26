//
//  MRKReading.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation

/// Represents a meter reading
struct MRKReading: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let kWh: Double
    let meterID: UUID
    
    /// Formatted string for display
    var formattedValue: String {
        String(format: "%.2f kWh", kWh)
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Validates that the reading data is correct
    func validate() throws {
        if kWh < 0 {
            throw MeterKeeperError.validationError(.negativeValue)
        }
        
        if date > Date() {
            throw MeterKeeperError.validationError(.readingInFuture)
        }
    }
}

/// Data required to create a reading
struct MRKReadingInput {
    let kWh: Double
    let date: Date
    let meterID: UUID
    
    func validate() throws {
        if kWh < 0 {
            throw MeterKeeperError.validationError(.negativeValue)
        }
        
        if date > Date() {
            throw MeterKeeperError.validationError(.readingInFuture)
        }
    }
}
