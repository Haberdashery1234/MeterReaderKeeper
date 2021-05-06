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
    var allReadings: [Reading] = []
    var allReadingsStructured: [Building : [Floor : [Meter : [Reading]]]] = [:]
    var allReadingsDates: [Date : [Reading]] = [:]
    
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
    func addBuilding(withName name: String, floors: Int16) {
        let managedContext = persistentContainer.viewContext
        
        let building = Building(context: managedContext)
        building.name = name
        
        for i in 1...floors {
            let floor = Floor(context: managedContext)
            floor.building = building
            floor.number = i
            saveFloor(floor)
        }
        
        do {
            try managedContext.save()
            print("Added building: \(String(describing: building.name)) with \(floors) floors")
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
        
        let buildFloors = floors.filter { (flr) -> Bool in
            return flr.building == building
        }
        for floor in buildFloors {
            managedContext.delete(floor)
        }
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
    func addMeter(withName name: String, description: String, floor: Floor, image: Data?, buildingName: String) -> Meter {
        let managedContext = persistentContainer.viewContext
        
        let meter = Meter(context: managedContext)
        meter.name = name
        meter.meterDescription = description
        meter.image = image
        meter.floor = floor
        let qrString = "\(buildingName)::\(floor.number)::\(name)"
        meter.qrString = qrString
        
        do {
            try managedContext.save()
            print("Added meter: \(qrString)")
            load()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return meter
    }
    
    func deleteMeter(_ meter: Meter) {
        let managedContext = persistentContainer.viewContext
        
        managedContext.delete(meter)
        
        do {
            try managedContext.save()
            print("Deleted meter: \(String(describing: meter.name))")
            load()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
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
    
    // MARK: - Readings
    func addReading(toMeter meter: Meter, withKWH kWh: Double, date: Date) {
        let managedContext = persistentContainer.viewContext
        
        meter.latestReading = date
        let reading = Reading(context: managedContext)
        reading.kWh = kWh
        reading.meter = meter
        reading.date = date
        
        do {
            try managedContext.save()
            print("Added reading: \(kWh) kWh to meter: \(String(describing: meter.name))")
            load()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func updateReading(_ reading: Reading, with kWh: Double) {
        let managedContext = persistentContainer.viewContext
        
        let date = Calendar.current.startOfDay(for: Date())

        if let meter = reading.meter {
            meter.latestReading = date
        }
        
        reading.kWh = kWh
        reading.date = date
        
        do {
            try managedContext.save()
            print("Updated reading")
            load()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func loadAllReadings() {
        let managedContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Reading> = Reading.fetchRequest()
        
        do {
            allReadings = try managedContext.fetch(fetchRequest)
            print("\(allReadings.count) readings loaded")
            structureReadings()
            groupReadingsByDate()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    private func groupReadingsByDate() {
        var localReadingsByDate: [Date : [Reading]] = [:]
        for reading in allReadings {
            if let date = reading.date {
                if localReadingsByDate[date] == nil {
                    localReadingsByDate[date] = [Reading]()
                }
                localReadingsByDate[date]?.append(reading)
            }
        }
        allReadingsDates = localReadingsByDate
    }
    
    private func structureReadings() {
        var localMeters = [Meter : [Reading]]()
        for reading in allReadings {
            if let meter = reading.meter {
                if localMeters[meter] == nil {
                    localMeters[meter] = [Reading]()
                }
                localMeters[meter]?.append(reading)
            }
        }
        
        var localFloors = [Floor : [Meter : [Reading]]]()
        for (meter, readings) in localMeters {
            if let floor = meter.floor {
                if localFloors[floor] == nil {
                    localFloors[floor] = [Meter : [Reading]]()
                }
                var thisMeter = [Meter : [Reading]]()
                thisMeter[meter] = readings
                localFloors[floor]?.merge(thisMeter, uniquingKeysWith: { (r1, _) -> [Reading] in r1 })
            }
        }
        
        var localBuildings = [Building : [Floor : [Meter : [Reading]]]]()
        for (floor, meters) in localFloors {
            if let building = floor.building {
                if localBuildings[building] == nil {
                    localBuildings[building] = [Floor : [Meter : [Reading]]]()
                }
                var thisFloor = [Floor : [Meter : [Reading]]]()
                thisFloor[floor] = meters
                localBuildings[building]?.merge(thisFloor, uniquingKeysWith: { (r1, _) -> [Meter : [Reading]] in r1 })
            }
        }
        
        allReadingsStructured = localBuildings
    }
    
    func getReadings(forDate date: Date) -> [Reading] {
        return allReadingsDates[date] ?? []
    }
    
    func getReadings(forBuilding building: Building) -> [Reading] {
        guard let floorsDict = allReadingsStructured[building] else {
            print("No floors in building")
            return []
        }
        var readings = [Reading]()
        for (_, floorMeters) in floorsDict {
            for (_, meterReadings) in floorMeters {
                readings.append(contentsOf: meterReadings)
            }
        }
        return readings
    }
    
    func getReadings(forFloor floor: Floor) -> [Reading] {
        guard
            let building = floor.building,
            let floorsDict = allReadingsStructured[building],
            let meterDict = floorsDict[floor]
        else {
            print("No meters in floor")
            return []
        }
        var readings = [Reading]()
        for (_, meterReadings) in meterDict {
            readings.append(contentsOf: meterReadings)
        }
        return readings
    }
    
    func getReadings(forMeter meter: Meter) -> [Reading] {
        guard
            let floor = meter.floor,
            let building = floor.building,
            let floorsDict = allReadingsStructured[building],
            let meterDict = floorsDict[floor],
            let readings = meterDict[meter]
        else {
            print("No readings for meter")
            return []
        }
        return readings
    }
    
    // MARK: - CSV Data
    func getCSVData(forBuilding building: Building) -> Data? {
        var csvString = ""
        if let buildingName = building.name {
            csvString.append("\(buildingName)")
            if let buildFloors = building.floors?.array as? [Floor] {
                for floor in buildFloors {
                    csvString.append("\nFloor \(floor.number)\n")
                    if let floorMeters = floor.meters?.array as? [Meter] {
                        for meter in floorMeters {
                            if
                                var readings = meter.readings?.array as? [Reading],
                                let meterName = meter.name {
                                readings.sort { (r1, r2) -> Bool in
                                    guard let r1Date = r1.date, let r2Date = r2.date else {
                                        return true
                                    }
                                    return r1Date > r2Date
                                }
                                if readings.count > 0 {
                                    let latestReading = readings[0]
                                    if let latestReadingDate = latestReading.date,
                                       latestReadingDate == Calendar.current.startOfDay(for: Date())
                                    {
                                        let formatter = DateFormatter()
                                        formatter.dateStyle = .short
                                        formatter.timeStyle = .none
                                        let latestReadingString = formatter.string(from: latestReadingDate)
                                        
                                        let meterId = "\(buildingName)::\(floor.number)::\(meterName)"
                                        let latestReadingKWH = String(format: "%.2f kWh", latestReading.kWh)
                                        csvString.append(",\(meterId),\(latestReadingKWH),\(latestReadingString)\n")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("ReadingsCSVFile.csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
         
            if fileManager.fileExists(atPath: fileURL.path){
                if let csvData = NSData(contentsOfFile: fileURL.path) {
                    return csvData as Data
                }
            }
        } catch {
            print("error creating file")
        }
        return nil
    }
}
