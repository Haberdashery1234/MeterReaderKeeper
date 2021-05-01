//
//  MeterManager.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/1/21.
//

import UIKit
import CoreData

class MeterManager {
    
    static let shared = MeterManager()
    
    var persistentContainer: NSPersistentContainer
    var meters: [NSManagedObject] = []
    
    init() {
        persistentContainer = NSPersistentContainer(name: "MeterReader")
        persistentContainer.loadPersistentStores { (descrioption, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        load()
    }
    
    func load() {
        let managedContext =
            persistentContainer.viewContext
          
          let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Meter")
          
          do {
            meters = try managedContext.fetch(fetchRequest)
          } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
          }
    }
    
    func save(name: String, description: String, qrString: NSUUID, map: Data?, image: Data?) {
        let managedContext = persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Meter", in: managedContext)!
        
        let meter = NSManagedObject(entity: entity, insertInto: managedContext)
        
        meter.setValue(name, forKey: "name")
        meter.setValue(description, forKey: "meterDescription")
        meter.setValue(image, forKey: "image")
        meter.setValue(qrString, forKey: "qrString")
        
        do {
            try managedContext.save()
            meters.append(meter)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func delete(meter: NSManagedObject) {
        let managedContext = persistentContainer.viewContext
        
        managedContext.delete(meter)
        
        do {
            try managedContext.save()
            load()
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }
}
