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
    func addBuilding(withName name: String, uuid: UUID, floors: Int16) {
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
            print("Saved building: \(String(describing: building.name)) with \(floors) floors")
            load()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    func loadBuildings() {
        let managedContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Building> = Building.fetchRequest()
        
        do {
            buildings = try managedContext.fetch(fetchRequest)
            buildings.sort { (build1, build2) -> Bool in
                if let build1Name = build1.name, let build2Name = build2.name {
                    return build1Name < build2Name
                } else {
                    return true
                }
            }
            print("\(buildings.count) Buildings loaded")
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func deleteBuilding(_ building: Building) {
        let managedContext = persistentContainer.viewContext
        
        managedContext.delete(building)
        
        do {
            try managedContext.save()
            print("Deleted building: \(String(describing: building.name))")
            load()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - Floors
    func saveFloor(_ floor: Floor) {
        let managedContext = persistentContainer.viewContext
        
        do {
            try managedContext.save()
            print("Saved floor: \(String(describing: floor.building?.name)) - \(floor.number)")
            load()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    func loadFloors() {
        let managedContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Floor> = Floor.fetchRequest()
        
        do {
            floors = try managedContext.fetch(fetchRequest)
            floors.sort { (floor1, floor2) -> Bool in
                if let floor1Build = floor1.building, let floor2Build = floor2.building,
                   let floor1BuildName = floor1Build.name, let floor2BuildName = floor2Build.name {
                    if floor1BuildName == floor2BuildName {
                        return floor1.number < floor2.number
                    } else {
                        return floor1BuildName < floor2BuildName
                    }
                } else {
                    return true
                }
            }
            print("\(floors.count) floors loaded")
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - Meters
    func saveMeter() {
        
    }
    
    func deleteMeter(_ meter: Meter) {
        
    }
    
    func loadMeters() {
        let managedContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Meter> = Meter.fetchRequest()
        
        do {
            meters = try managedContext.fetch(fetchRequest)
            print("\(meters.count) Meters loaded")
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}
