//
//  Reading+CoreDataProperties.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/6/21.
//
//

import Foundation
import CoreData

@objc(Reading)
public class Reading: NSManagedObject {

    func getExportDictionary() -> [String : Any] {
        var exportDict = [String : Any]()
        exportDict["date"] = date
        exportDict["kWh"] = kWh
        return exportDict
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
