//
//  Floor+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//
//

import Foundation
import CoreData


extension Floor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Floor> {
        return NSFetchRequest<Floor>(entityName: "Floor")
    }

    @NSManaged public var map: Data?
    @NSManaged public var number: Int16
    @NSManaged public var building: Building
    @NSManaged public var meters: NSOrderedSet?

}

// MARK: Generated accessors for meters
extension Floor {

    @objc(insertObject:inMetersAtIndex:)
    @NSManaged public func insertIntoMeters(_ value: Meter, at idx: Int)

    @objc(removeObjectFromMetersAtIndex:)
    @NSManaged public func removeFromMeters(at idx: Int)

    @objc(insertMeters:atIndexes:)
    @NSManaged public func insertIntoMeters(_ values: [Meter], at indexes: NSIndexSet)

    @objc(removeMetersAtIndexes:)
    @NSManaged public func removeFromMeters(at indexes: NSIndexSet)

    @objc(replaceObjectInMetersAtIndex:withObject:)
    @NSManaged public func replaceMeters(at idx: Int, with value: Meter)

    @objc(replaceMetersAtIndexes:withMeters:)
    @NSManaged public func replaceMeters(at indexes: NSIndexSet, with values: [Meter])

    @objc(addMetersObject:)
    @NSManaged public func addToMeters(_ value: Meter)

    @objc(removeMetersObject:)
    @NSManaged public func removeFromMeters(_ value: Meter)

    @objc(addMeters:)
    @NSManaged public func addToMeters(_ values: NSOrderedSet)

    @objc(removeMeters:)
    @NSManaged public func removeFromMeters(_ values: NSOrderedSet)

}

extension Floor : Identifiable {

}
