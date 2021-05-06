//
//  DataSeeder.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//

import Foundation

class DataSeeder {
    
    static let shared = DataSeeder()
    
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func seedData() {
        let manager = MeterManager.shared
        
        let buildings = [
            "121 Seaport",
            "25 State",
            "141 Franklin",
            "16 Pinkham"
        ]
        
        for name in buildings {
            manager.addBuilding(withName: name, floors: Int16(Int.random(in: 5...35)))
            
            for building in manager.buildings {
                if let floors = building.floors?.array as? [Floor] {
                    for floor in floors {
                        let numberOfMeters = Int.random(in: 3...8)
                        for i in 1...numberOfMeters {
                            if let buildingName = building.name {
                                let meterName = "\(randomString(length: 5))-\(i)"
                                let meterDescription = "This is a short description for \(meterName)"
                                
                                let meter = manager.addMeter(withName: meterName, description: meterDescription, floor: floor, image: nil, buildingName: buildingName)
                                
                                let randomDays = Int.random(in: -30...0)
                                var date = Calendar.current.startOfDay(for: Date())
                                date = Calendar.current.date(byAdding: .day, value: randomDays, to: date) ?? Date()
                                
                                manager.addReading(toMeter: meter, withKWH: Double.random(in: 10000...50000), date: date)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func seedMoreReadings() {
        let manager = MeterManager.shared
        for building in manager.buildings {
            if let floors = building.floors?.array as? [Floor] {
                for floor in floors {
                    if let meters = floor.meters?.array as? [Meter] {
                        for meter in meters {
                            let date = Calendar.current.startOfDay(for: Date())
                            
                            manager.addReading(toMeter: meter, withKWH: Double.random(in: 10000...50000), date: date)
                        }
                    }
                }
            }
        }
    }
}
