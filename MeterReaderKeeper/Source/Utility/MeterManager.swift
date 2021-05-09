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
    
    var exportURL: URL {
        get {
            let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
            let writableFileURL = documentDirectoryURL.appendingPathComponent("exportData.plist", isDirectory: false)
            return writableFileURL
        }
    }
    
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
        
        if !FileManager.default.fileExists(atPath: exportURL.path) {
            FileManager.default.createFile(atPath: exportURL.path, contents: nil, attributes: nil)
            print("created exportData.plist file successfully")
            return
        }
        
        load()
    }
    
    func load() {
        loadBuildings()
        loadFloors()
        loadMeters()
    }
    
    // MARK: - Buildings
    func addBuilding(withName name: String, floors: Int16, autoCreateFloors: Bool? = true) -> Building? {
        let managedContext = persistentContainer.viewContext
        
        let building = Building(context: managedContext)
        building.name = name
        
        if autoCreateFloors == true {
            for i in 1...floors {
                let floor = Floor(context: managedContext)
                floor.building = building
                floor.number = i
                floor.map = Data()
                saveFloor(floor)
            }
        }
        
        do {
            try managedContext.save()
            print("Added building: \(String(describing: building.name)) with \(floors) floors")
            load()
            return building
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return nil
    }

    func loadBuildings() {
        let managedContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Building> = Building.fetchRequest()
        
        do {
            buildings = try managedContext.fetch(fetchRequest)
            buildings.sort { (build1, build2) -> Bool in
                return build1.name < build2.name
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
    func addFloor(toBuilding building: Building, number: Int16, mapData: Data) -> Floor? {
        let managedContext = persistentContainer.viewContext
        
        let floor = Floor(context: managedContext)
        floor.building = building
        floor.number = number
        floor.map = mapData
        
        do {
            try managedContext.save()
            print("Saved floor: \(String(describing: building.name)) - \(floor.number)")
            load()
            return floor
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func saveFloor(_ floor: Floor) {
        let managedContext = persistentContainer.viewContext
        
        do {
            try managedContext.save()
            print("Saved floor: \(String(describing: floor.building.name)) - \(floor.number)")
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
                let floor1BuildName = floor1.building.name
                let floor2BuildName = floor2.building.name
                if floor1BuildName == floor2BuildName {
                    return floor1.number < floor2.number
                } else {
                    return floor1BuildName < floor2BuildName
                }
            }
            print("\(floors.count) floors loaded")
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - Meters
    func addMeter(withName name: String, description: String, floor: Floor, image: Data, buildingName: String) -> Meter? {
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
            return meter
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return nil
    }
    
    func updateMeter(_ meter: Meter, withName name: String, description: String, floor: Floor, image: Data, buildingName: String) -> Meter? {
        let managedContext = persistentContainer.viewContext
        
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
            return meter
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return nil
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

        reading.meter.latestReading = date
        
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
            if localReadingsByDate[reading.date] == nil {
                localReadingsByDate[reading.date] = [Reading]()
            }
            localReadingsByDate[reading.date]?.append(reading)
        }
        allReadingsDates = localReadingsByDate
    }
    
    private func structureReadings() {
        var localMeters = [Meter : [Reading]]()
        for reading in allReadings {
            if localMeters[reading.meter] == nil {
                localMeters[reading.meter] = [Reading]()
            }
            localMeters[reading.meter]?.append(reading)
        }
        
        var localFloors = [Floor : [Meter : [Reading]]]()
        for (meter, readings) in localMeters {
            if localFloors[meter.floor] == nil {
                localFloors[meter.floor] = [Meter : [Reading]]()
            }
            var thisMeter = [Meter : [Reading]]()
            thisMeter[meter] = readings
            localFloors[meter.floor]?.merge(thisMeter, uniquingKeysWith: { (r1, _) -> [Reading] in r1 })
        }
        
        var localBuildings = [Building : [Floor : [Meter : [Reading]]]]()
        for (floor, meters) in localFloors {
            if localBuildings[floor.building] == nil {
                localBuildings[floor.building] = [Floor : [Meter : [Reading]]]()
            }
            var thisFloor = [Floor : [Meter : [Reading]]]()
            thisFloor[floor] = meters
            localBuildings[floor.building]?.merge(thisFloor, uniquingKeysWith: { (r1, _) -> [Meter : [Reading]] in r1 })
        }
        
        allReadingsStructured = localBuildings
    }
    
    func saveDataToPlist() {
        
        let exportArray = NSMutableArray()
        for building in buildings {
            exportArray.add(building.getExportDictionary())
        }
        do {
            try exportArray.write(to: exportURL)
        } catch let error as NSError {
            print("An error occurred while writing to plist: \(error.localizedDescription)")
        }
    }
    
//    func savePlistDictToCoreData(_ dict: [[String : Any]]) {
//        for buildingDict in dict {
//            if
//                let buildingName = buildingDict["name"] as? String,
//                let floorsArray = buildingDict["floors"] as? [[String : Any]]
//               {
//                if let building = addBuilding(withName: buildingName, floors: Int16(floorsArray.count), autoCreateFloors: false) {
//
//                    for floorDict in floorsArray {
//                        if let floorNumber = Int16(floorDict["number"] as! String) {
//                            var metersArray = [[String : Any]]()
//                            if let dictMetersArray = floorDict["meters"] as? [[String : Any]] {
//                                metersArray = dictMetersArray
//                            }
//                            var mapData = Data()
//                            if let dictMapData = floorDict["map"] as? Data {
//                                mapData = dictMapData
//                            }
//                            if let floor = addFloor(toBuilding: building, number: floorNumber, mapData: mapData) {
//                                for meterDict in metersArray {
//                                    if let meterName = meterDict["name"] as? String {
//                                        let meterDescription = meterDict["meterDescription"] as? String ?? ""
//                                        let meterImage = meterDict["image"] as? Data
//                                        let latestReading = meterDict["latestReading"] as? Date
//                                        if let meter = addMeter(withName: meterName, description: meterDescription, floor: floor, image: meterImage, buildingName: building.name) {
//                                            if let dictReadingsArray = meterDict["readings"] as? [[String : Any]] {
//                                                for readingDict in dictReadingsArray {
//                                                    if
//                                                        let kWhString = readingDict["kWh"] as? String,
//                                                        let kWh = Double(kWhString),
//                                                        let date = readingDict["date"] as? Date {
//                                                        addReading(toMeter: meter, withKWH: kWh, date: date)
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    func saveAllReadingsToPlist() {
        
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
            let floorsDict = allReadingsStructured[floor.building],
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
            let floorsDict = allReadingsStructured[meter.floor.building],
            let meterDict = floorsDict[meter.floor],
            let readings = meterDict[meter]
        else {
            print("No readings for meter")
            return []
        }
        return readings
    }
    
    // MARK: - CSV Data
    func getCSVData(forBuilding building: Building) -> Data? {
        var csvString = "\(building.name)"
        let buildFloors = building.buildingFloors
        for floor in buildFloors {
            csvString.append("\nFloor \(floor.number)\n")
            let floorMeters = floor.floorMeters
            for meter in floorMeters {
                var readings = meter.meterReadings
                readings.sort { (r1, r2) -> Bool in
                    return r1.date > r2.date
                }
                if readings.count > 0 {
                    let latestReading = readings[0]
                    let latestReadingDate = latestReading.date
                    if latestReadingDate == Calendar.current.startOfDay(for: Date()) {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .short
                        formatter.timeStyle = .none
                        let latestReadingString = formatter.string(from: latestReadingDate)
                        
                        let meterId = "\(building.name)::\(floor.number)::\(meter.name)"
                        let latestReadingKWH = String(format: "%.2f kWh", latestReading.kWh)
                        csvString.append(",\(meterId),\(latestReadingKWH),\(latestReadingString)\n")
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
