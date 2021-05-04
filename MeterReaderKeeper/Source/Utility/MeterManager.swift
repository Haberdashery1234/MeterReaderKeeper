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
    var buildings: [Building] = []
    var floors: [Floor] = []
    var meters: [Meter] = []
    
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
        loadBuildings()
        loadFloors()
        loadMeters()
    }
    
    // MARK: - Buildings
    func saveBuilding(withName name: String, uuid: UUID, floors: Int16) {
        let managedContext = persistentContainer.viewContext
        
        let building = Building(context: managedContext)
        building.name = name
        building.uuid = uuid
        
        for i in 1...floors {
            let floor = Floor(context: managedContext)
            floor.building = building
            floor.number = i
            saveFloor(floor)
        }
        
        do {
            try managedContext.save()
            buildings.append(building)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    func loadBuildings() {
        let managedContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Building> = Building.fetchRequest()
        
        do {
            buildings = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - Floors
    func saveFloor(with building: Building, number: Int16, map: Data?) {
        let managedContext = persistentContainer.viewContext
        
        let floor = Floor(context: managedContext)
        floor.building = building
        floor.number = number
        
        saveFloor(floor)
    }
    
    func saveFloor(_ floor: Floor) {
        let managedContext = persistentContainer.viewContext
        
        do {
            try managedContext.save()
            floors.append(floor)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    func loadFloors() {
        let managedContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Floor> = Floor.fetchRequest()
        
        do {
            floors = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - Meters
    func saveMeter() {
        
    }
    
    func loadMeters() {
        let managedContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Meter> = Meter.fetchRequest()
        
        do {
            meters = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}
