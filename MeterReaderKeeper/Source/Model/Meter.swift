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
public class Meter: NSManagedObject {

    var meterReadings: [Reading] {
        get {
            return readings.array as! [Reading]
        }
    }
    
    func getExportDictionary() -> [String : Any] {
        var exportDict = [String : Any]()
        exportDict["image"] = UIService.shared.getExportSizeImageData(from: image, ofMaxSizeMB: 0.25)
        exportDict["latestReading"] = latestReading
        exportDict["meterDescription"] = meterDescription
        exportDict["latestReading"] = latestReading
        exportDict["name"] = name
        exportDict["qrString"] = qrString
        
        var localReadings = [[String : Any]]()
        for reading in meterReadings {
            localReadings.append(reading.getExportDictionary())
        }
        exportDict["readings"] = localReadings
        return exportDict
    }
}

extension Meter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meter> {
        return NSFetchRequest<Meter>(entityName: "Meter")
    }

    @NSManaged public var image: Data
    @NSManaged public var latestReading: Date
    @NSManaged public var meterDescription: String
    @NSManaged public var name: String
    @NSManaged public var qrString: String
    @NSManaged public var floor: Floor
    @NSManaged public var readings: NSOrderedSet

}

// MARK: Generated accessors for readings
extension Meter {

    @objc(insertObject:inReadingsAtIndex:)
    @NSManaged public func insertIntoReadings(_ value: Reading, at idx: Int)

    @objc(removeObjectFromReadingsAtIndex:)
    @NSManaged public func removeFromReadings(at idx: Int)

    @objc(insertReadings:atIndexes:)
    @NSManaged public func insertIntoReadings(_ values: [Reading], at indexes: NSIndexSet)

    @objc(removeReadingsAtIndexes:)
    @NSManaged public func removeFromReadings(at indexes: NSIndexSet)

    @objc(replaceObjectInReadingsAtIndex:withObject:)
    @NSManaged public func replaceReadings(at idx: Int, with value: Reading)

    @objc(replaceReadingsAtIndexes:withReadings:)
    @NSManaged public func replaceReadings(at indexes: NSIndexSet, with values: [Reading])

    @objc(addReadingsObject:)
    @NSManaged public func addToReadings(_ value: Reading)

    @objc(removeReadingsObject:)
    @NSManaged public func removeFromReadings(_ value: Reading)

    @objc(addReadings:)
    @NSManaged public func addToReadings(_ values: NSOrderedSet)

    @objc(removeReadings:)
    @NSManaged public func removeFromReadings(_ values: NSOrderedSet)

}

extension Meter : Identifiable {

}
