//
//  DataSeeder.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//

import Foundation
import os.log

class DataSeeder {
    
    private let repository: MeterRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "DataSeeder")
    
    init(repository: MeterRepositoryProtocol) {
        self.repository = repository
    }
    
    /// Generates a random alphanumeric string
    /// - Parameter length: Desired string length
    /// - Returns: Random string of specified length
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    /// Seeds initial building, floor, meter, and reading data
    func seedData() throws {
        logger.info("Starting data seeding...")
        
        let buildingNames = [
            "121 Seaport",
            "25 State",
            "141 Franklin",
            "16 Pinkham"
        ]
        
        for buildingName in buildingNames {
            let floorCount = Int16(Int.random(in: 5...35))
            
            let newBuilding = try repository.addBuilding(
                MRKBuildingInput(name: buildingName, numberOfFloors: floorCount, autoCreateFloors: true)
            )
            
            logger.info("Created building '\(buildingName)' with \(floorCount) floors")
            
            for floor in newBuilding.floors {
                let numberOfMeters = Int.random(in: 3...8)
                
                for meterIndex in 1...numberOfMeters {
                    let meterName = "\(randomString(length: 5))-\(meterIndex)"
                    let meterDescription = "This is a short description for \(meterName)"
                    
                    let meter = try repository.addMeter(
                        MRKMeterInput(name: meterName, description: meterDescription, imageData: Data(), floorID: floor.id)
                    )
                    
                    // Add 5 historical readings (monthly intervals, going backwards from today)
                    for readingIndex in 0...4 {
                        var date = Calendar.current.startOfDay(for: Date())
                        date = Calendar.current.date(byAdding: .day, value: -(readingIndex * 30), to: date) ?? Date()
                        let kWh = Double.random(in: 10_000...30_000)
                        
                        _ = try repository.addReading(MRKReadingInput(kWh: kWh, date: date, meterID: meter.id))
                    }
                }
                
                logger.debug("Added \(numberOfMeters) meters to floor \(floor.number)")
            }
        }
        
        logger.info("Data seeding complete.")
    }
    
    /// Adds additional readings to all existing meters for today's date
    func seedMoreReadings() throws {
        logger.info("Seeding additional readings...")
        let date = Calendar.current.startOfDay(for: Date())
        
        var readingCount = 0
        
        for building in try repository.getBuildings() {
            for floor in building.floors {
                for meter in floor.meters {
                    let kWh = Double.random(in: 10_000...50_000)
                    _ = try repository.addReading(MRKReadingInput(kWh: kWh, date: date, meterID: meter.id))
                    readingCount += 1
                }
            }
        }
        
        logger.info("Added \(readingCount) new readings")
    }
}
