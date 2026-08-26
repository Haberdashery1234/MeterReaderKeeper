//
//  Building+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/6/21.
//
//

import Foundation
import CoreData

@objc(CoreDataBuilding)
public class CoreDataBuilding: NSManagedObject {
    
    /// Safely retrieves all floors for this building
    var buildingFloors: [CoreDataFloor] {
        guard let floorsArray = floors.array as? [CoreDataFloor] else {
            print("⚠️ Warning: Failed to cast floors to [Floor] for building: \(name)")
            return []
        }
        return floorsArray
    }
    
    /// Retrieves floors sorted by floor number
    var sortedFloors: [CoreDataFloor] {
        buildingFloors.sorted { $0.number < $1.number }
    }
    
    /// Total number of meters in this building
    var totalMeterCount: Int {
        buildingFloors.reduce(0) { $0 + $1.floorMeters.count }
    }
    
    /// Exports building data to a dictionary for serialization
    /// - Returns: Dictionary containing building data including all floors
    func getExportDictionary() -> [String: Any] {
        var exportDict: [String: Any] = [:]
        exportDict["name"] = name
        
        // Export all floors
        let floorsData = buildingFloors.map { $0.getExportDictionary() }
        exportDict["floors"] = floorsData
        
        return exportDict
    }
    
    /// Validates building data
    /// - Throws: MeterKeeperError.validationError if validation fails
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Building name"))
        }
    }
}

extension CoreDataBuilding {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataBuilding> {
        return NSFetchRequest<CoreDataBuilding>(entityName: "CoreDataBuilding")
    }

    @NSManaged public var name: String
    @NSManaged public var floors: NSOrderedSet

}

// MARK: Generated accessors for floors
extension CoreDataBuilding {

    @objc(insertObject:inFloorsAtIndex:)
    @NSManaged public func insertIntoFloors(_ value: CoreDataFloor, at idx: Int)

    @objc(removeObjectFromFloorsAtIndex:)
    @NSManaged public func removeFromFloors(at idx: Int)

    @objc(insertFloors:atIndexes:)
    @NSManaged public func insertIntoFloors(_ values: [CoreDataFloor], at indexes: NSIndexSet)

    @objc(removeFloorsAtIndexes:)
    @NSManaged public func removeFromFloors(at indexes: NSIndexSet)

    @objc(replaceObjectInFloorsAtIndex:withObject:)
    @NSManaged public func replaceFloors(at idx: Int, with value: CoreDataFloor)

    @objc(replaceFloorsAtIndexes:withFloors:)
    @NSManaged public func replaceFloors(at indexes: NSIndexSet, with values: [CoreDataFloor])

    @objc(addFloorsObject:)
    @NSManaged public func addToFloors(_ value: CoreDataFloor)

    @objc(removeFloorsObject:)
    @NSManaged public func removeFromFloors(_ value: CoreDataFloor)

    @objc(addFloors:)
    @NSManaged public func addToFloors(_ values: NSOrderedSet)

    @objc(removeFloors:)
    @NSManaged public func removeFromFloors(_ values: NSOrderedSet)

}

extension CoreDataBuilding : Identifiable {

}
