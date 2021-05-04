//
//  Reading+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/3/21.
//
//

import Foundation
import CoreData


extension Reading {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reading> {
        return NSFetchRequest<Reading>(entityName: "Reading")
    }

    @NSManaged public var date: Date?
    @NSManaged public var kWh: Double
    @NSManaged public var meter: Meter?

}

extension Reading : Identifiable {

}
