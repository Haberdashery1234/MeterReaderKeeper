//
//  Floor+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/3/21.
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
    @NSManaged public var building: Building?
    @NSManaged public var meters: NSSet?

}

// MARK: Generated accessors for meters
extension Floor {

    @objc(addMetersObject:)
    @NSManaged public func addToMeters(_ value: Meter)

    @objc(removeMetersObject:)
    @NSManaged public func removeFromMeters(_ value: Meter)

    @objc(addMeters:)
    @NSManaged public func addToMeters(_ values: NSSet)

    @objc(removeMeters:)
    @NSManaged public func removeFromMeters(_ values: NSSet)

}

extension Floor : Identifiable {

}
