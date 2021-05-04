//
//  Meter+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/3/21.
//
//

import Foundation
import CoreData


extension Meter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meter> {
        return NSFetchRequest<Meter>(entityName: "Meter")
    }

    @NSManaged public var image: Data?
    @NSManaged public var meterDescription: String?
    @NSManaged public var name: String?
    @NSManaged public var qrString: UUID?
    @NSManaged public var floor: Floor?
    @NSManaged public var readings: NSSet?

}

// MARK: Generated accessors for readings
extension Meter {

    @objc(addReadingsObject:)
    @NSManaged public func addToReadings(_ value: Reading)

    @objc(removeReadingsObject:)
    @NSManaged public func removeFromReadings(_ value: Reading)

    @objc(addReadings:)
    @NSManaged public func addToReadings(_ values: NSSet)

    @objc(removeReadings:)
    @NSManaged public func removeFromReadings(_ values: NSSet)

}

extension Meter : Identifiable {

}
