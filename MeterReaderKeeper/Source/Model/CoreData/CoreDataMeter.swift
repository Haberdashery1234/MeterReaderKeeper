//
//  Meter+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/6/21.
//
//

import Foundation
import CoreData

@objc(Meter)
public class CoreDataMeter: NSManagedObject {

    /// Safely retrieves all readings for this meter
    var meterReadings: [CoreDataReading] {
        guard let readingsArray = readings.array as? [CoreDataReading] else {
            print("⚠️ Warning: Failed to cast readings to [Reading] for meter: \(name)")
            return []
        }
        return readingsArray
    }
    
    /// Retrieves readings sorted by date (most recent first)
    var sortedReadings: [CoreDataReading] {
        meterReadings.sorted { $0.date > $1.date }
    }
    
    /// Gets the most recent reading, if available
    var mostRecentReading: CoreDataReading? {
        sortedReadings.first
    }
    
    /// Exports meter data to a dictionary for serialization
    /// - Returns: Dictionary containing all meter data including readings
    func getExportDictionary() -> [String: Any] {
        var exportDict: [String: Any] = [:]
        
        // Basic properties
        exportDict["name"] = name
        exportDict["meterDescription"] = meterDescription
        exportDict["qrString"] = qrString
        exportDict["latestReading"] = latestReading
        
        // Compress image for export
        if let compressedImage = UIService.shared.getExportSizeImageData(from: image, ofMaxSizeMB: 0.25) {
            exportDict["image"] = compressedImage
        } else {
            exportDict["image"] = Data()
        }
        
        // Export all readings
        let readingsData = meterReadings.map { $0.getExportDictionary() }
        exportDict["readings"] = readingsData
        
        return exportDict
    }
    
    /// Validates meter data
    /// - Throws: MeterKeeperError.validationError if validation fails
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Meter name"))
        }
    }
}

extension CoreDataMeter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataMeter> {
        return NSFetchRequest<CoreDataMeter>(entityName: "Meter")
    }

    @NSManaged public var image: Data
    @NSManaged public var latestReading: Date
    @NSManaged public var meterDescription: String
    @NSManaged public var name: String
    @NSManaged public var qrString: String
    @NSManaged public var floor: CoreDataFloor
    @NSManaged public var readings: NSOrderedSet

}

// MARK: Generated accessors for readings
extension CoreDataMeter {

    @objc(insertObject:inReadingsAtIndex:)
    @NSManaged public func insertIntoReadings(_ value: CoreDataReading, at idx: Int)

    @objc(removeObjectFromReadingsAtIndex:)
    @NSManaged public func removeFromReadings(at idx: Int)

    @objc(insertReadings:atIndexes:)
    @NSManaged public func insertIntoReadings(_ values: [CoreDataReading], at indexes: NSIndexSet)

    @objc(removeReadingsAtIndexes:)
    @NSManaged public func removeFromReadings(at indexes: NSIndexSet)

    @objc(replaceObjectInReadingsAtIndex:withObject:)
    @NSManaged public func replaceReadings(at idx: Int, with value: CoreDataReading)

    @objc(replaceReadingsAtIndexes:withReadings:)
    @NSManaged public func replaceReadings(at indexes: NSIndexSet, with values: [CoreDataReading])

    @objc(addReadingsObject:)
    @NSManaged public func addToReadings(_ value: CoreDataReading)

    @objc(removeReadingsObject:)
    @NSManaged public func removeFromReadings(_ value: CoreDataReading)

    @objc(addReadings:)
    @NSManaged public func addToReadings(_ values: NSOrderedSet)

    @objc(removeReadings:)
    @NSManaged public func removeFromReadings(_ values: NSOrderedSet)

}

extension CoreDataMeter : Identifiable {

}
