//
//  DataSeeder.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//

import Foundation
import os.log

class DataSeeder {
    
    static let shared = DataSeeder()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "DataSeeder")
    
    /// Generates a random alphanumeric string
    /// - Parameter length: Desired string length
    /// - Returns: Random string of specified length
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    /// Seeds initial building, floor, meter, and reading data
    func seedData() {
        logger.info("Starting data seeding...")
        let manager = MeterManager.shared
        
        let buildingNames = [
            "121 Seaport",
            "25 State",
            "141 Franklin",
            "16 Pinkham"
        ]
        
        for buildingName in buildingNames {
            let floorCount = Int16(Int.random(in: 5...35))
            
            guard let newBuilding = manager.addBuilding(withName: buildingName, floors: floorCount) else {
                logger.error("Failed to create building: \(buildingName)")
                continue
            }
            
            logger.info("Created building '\(buildingName)' with \(floorCount) floors")
            
            // Process ONLY the newly created building, not all buildings
            let floors = newBuilding.buildingFloors
            for floor in floors {
                let numberOfMeters = Int.random(in: 3...8)
                
                for meterIndex in 1...numberOfMeters {
                    let meterName = "\(randomString(length: 5))-\(meterIndex)"
                    let meterDescription = "This is a short description for \(meterName)"
                    
                    guard let meter = manager.addMeter(
                        withName: meterName,
                        description: meterDescription,
                        floor: floor,
                        image: Data(),
                        buildingName: newBuilding.name
                    ) else {
                        logger.error("Failed to create meter: \(meterName)")
                        continue
                    }
                    
                    // Add 5 historical readings (monthly intervals)
                    for readingIndex in 0...4 {
                        var date = Calendar.current.startOfDay(for: Date())
                        date = Calendar.current.date(byAdding: .day, value: readingIndex * 30, to: date) ?? Date()
                        let kWh = Double.random(in: 10_000...30_000)
                        
                        manager.addReading(toMeter: meter, withKWH: kWh, date: date)
                    }
                }
                
                logger.debug("Added \(numberOfMeters) meters to floor \(floor.number)")
            }
        }
        
        logger.info("Data seeding complete. Total buildings: \(manager.buildings.count)")
    }
    
    /// Adds additional readings to all existing meters for today's date
    func seedMoreReadings() {
        logger.info("Seeding additional readings...")
        let manager = MeterManager.shared
        let date = Calendar.current.startOfDay(for: Date())
        
        var readingCount = 0
        
        for building in manager.buildings {
            let floors = building.buildingFloors
            for floor in floors {
                let meters = floor.floorMeters
                for meter in meters {
                    let kWh = Double.random(in: 10_000...50_000)
                    manager.addReading(toMeter: meter, withKWH: kWh, date: date)
                    readingCount += 1
                }
            }
        }
        
        logger.info("Added \(readingCount) new readings")
    }
}
