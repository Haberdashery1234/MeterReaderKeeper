//
//  Building+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/3/21.
//
//

import Foundation
import CoreData


extension Building {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Building> {
        return NSFetchRequest<Building>(entityName: "Building")
    }

    @NSManaged public var name: String?
    @NSManaged public var uuid: UUID?
    @NSManaged public var floors: NSSet?

}

// MARK: Generated accessors for floors
extension Building {

    @objc(addFloorsObject:)
    @NSManaged public func addToFloors(_ value: Floor)

    @objc(removeFloorsObject:)
    @NSManaged public func removeFromFloors(_ value: Floor)

    @objc(addFloors:)
    @NSManaged public func addToFloors(_ values: NSSet)

    @objc(removeFloors:)
    @NSManaged public func removeFromFloors(_ values: NSSet)

}

extension Building : Identifiable {

}
