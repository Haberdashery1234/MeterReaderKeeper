//
//  Building+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/6/21.
//
//

import Foundation
import CoreData

@objc(Building)
public class Building: NSManagedObject {
    
    var buildingFloors: [Floor] {
        get {
            return floors.array as! [Floor]
        }
    }
    
    func getExportDictionary() -> [String : Any] {
        var exportDict = [String : Any]()
        exportDict["name"] = name
        
        var localFloors = [[String : Any]]()
        for floor in buildingFloors {
            localFloors.append(floor.getExportDictionary())
        }
        exportDict["floors"] = localFloors
        return exportDict
    }
    
}

extension Building {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Building> {
        return NSFetchRequest<Building>(entityName: "Building")
    }

    @NSManaged public var name: String
    @NSManaged public var floors: NSOrderedSet

}

// MARK: Generated accessors for floors
extension Building {

    @objc(insertObject:inFloorsAtIndex:)
    @NSManaged public func insertIntoFloors(_ value: Floor, at idx: Int)

    @objc(removeObjectFromFloorsAtIndex:)
    @NSManaged public func removeFromFloors(at idx: Int)

    @objc(insertFloors:atIndexes:)
    @NSManaged public func insertIntoFloors(_ values: [Floor], at indexes: NSIndexSet)

    @objc(removeFloorsAtIndexes:)
    @NSManaged public func removeFromFloors(at indexes: NSIndexSet)

    @objc(replaceObjectInFloorsAtIndex:withObject:)
    @NSManaged public func replaceFloors(at idx: Int, with value: Floor)

    @objc(replaceFloorsAtIndexes:withFloors:)
    @NSManaged public func replaceFloors(at indexes: NSIndexSet, with values: [Floor])

    @objc(addFloorsObject:)
    @NSManaged public func addToFloors(_ value: Floor)

    @objc(removeFloorsObject:)
    @NSManaged public func removeFromFloors(_ value: Floor)

    @objc(addFloors:)
    @NSManaged public func addToFloors(_ values: NSOrderedSet)

    @objc(removeFloors:)
    @NSManaged public func removeFromFloors(_ values: NSOrderedSet)

}

extension Building : Identifiable {

}
