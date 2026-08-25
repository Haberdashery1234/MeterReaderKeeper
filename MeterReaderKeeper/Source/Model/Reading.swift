//
//  Reading.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/6/21.
//  Updated by Modernization on 8/25/26.
//

import Foundation
import CoreData

@objc(Reading)
public class Reading: NSManagedObject {

    /// Exports reading data to a dictionary for serialization
    /// - Returns: Dictionary containing date and kWh values
    func getExportDictionary() -> [String: Any] {
        [
            "date": date as Any,
            "kWh": kWh as Any
        ]
    }
    
    /// Validates that the reading data is correct
    /// - Throws: MeterKeeperError.validationError if validation fails
    func validate() throws {
        if kWh < 0 {
            throw MeterKeeperError.validationError(.negativeValue)
        }
        
        if date > Date() {
            throw MeterKeeperError.validationError(.readingInFuture)
        }
    }
    
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
}

extension Reading {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reading> {
        return NSFetchRequest<Reading>(entityName: "Reading")
    }

    @NSManaged public var date: Date
    @NSManaged public var kWh: Double
    @NSManaged public var meter: Meter

}

extension Reading : Identifiable {

}
