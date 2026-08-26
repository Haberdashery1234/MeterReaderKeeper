//
//  Floor+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/6/21.
//
//

import Foundation
import CoreData

@objc(CoreDataFloor)
public class CoreDataFloor: NSManagedObject {

    /// Safely retrieves all meters for this floor
    var floorMeters: [CoreDataMeter] {
        guard let metersArray = meters.array as? [CoreDataMeter] else {
            print("⚠️ Warning: Failed to cast meters to [Meter] for floor: \(number)")
            return []
        }
        return metersArray
    }
    
    /// Retrieves meters sorted by name
    var sortedMeters: [CoreDataMeter] {
        floorMeters.sorted { $0.name < $1.name }
    }
    
    /// Display name for the floor
    var displayName: String {
        "Floor \(number)"
    }
    
    /// Exports floor data to a dictionary for serialization
    /// - Returns: Dictionary containing floor data including all meters
    func getExportDictionary() -> [String: Any] {
        var exportDict: [String: Any] = [:]
        exportDict["number"] = number
        
        // Compress map image for export
        if let compressedMap = UIService.shared.getExportSizeImageData(from: map, ofMaxSizeMB: 0.25) {
            exportDict["map"] = compressedMap
        } else {
            exportDict["map"] = Data()
        }
        
        // Export all meters
        let metersData = floorMeters.map { $0.getExportDictionary() }
        exportDict["meters"] = metersData
        
        return exportDict
    }
}

extension CoreDataFloor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataFloor> {
        return NSFetchRequest<CoreDataFloor>(entityName: "CoreDataFloor")
    }

    @NSManaged public var map: Data
    @NSManaged public var number: Int16
    @NSManaged public var building: CoreDataBuilding
    @NSManaged public var meters: NSOrderedSet

}

// MARK: Generated accessors for meters
extension CoreDataFloor {

    @objc(insertObject:inMetersAtIndex:)
    @NSManaged public func insertIntoMeters(_ value: CoreDataMeter, at idx: Int)

    @objc(removeObjectFromMetersAtIndex:)
    @NSManaged public func removeFromMeters(at idx: Int)

    @objc(insertMeters:atIndexes:)
    @NSManaged public func insertIntoMeters(_ values: [CoreDataMeter], at indexes: NSIndexSet)

    @objc(removeMetersAtIndexes:)
    @NSManaged public func removeFromMeters(at indexes: NSIndexSet)

    @objc(replaceObjectInMetersAtIndex:withObject:)
    @NSManaged public func replaceMeters(at idx: Int, with value: CoreDataMeter)

    @objc(replaceMetersAtIndexes:withMeters:)
    @NSManaged public func replaceMeters(at indexes: NSIndexSet, with values: [CoreDataMeter])

    @objc(addMetersObject:)
    @NSManaged public func addToMeters(_ value: CoreDataMeter)

    @objc(removeMetersObject:)
    @NSManaged public func removeFromMeters(_ value: CoreDataMeter)

    @objc(addMeters:)
    @NSManaged public func addToMeters(_ values: NSOrderedSet)

    @objc(removeMeters:)
    @NSManaged public func removeFromMeters(_ values: NSOrderedSet)

}

extension CoreDataFloor : Identifiable {

}
