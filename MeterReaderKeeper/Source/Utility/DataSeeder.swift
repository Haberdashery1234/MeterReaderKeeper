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
                                let floorNumber = floor.number
                                let meterName = "\(randomString(length: 5))-\(i)"
                                
                                let qrString = "\(NSUUID())-\(buildingName)-\(floorNumber)-\(meterName)"
                                
                                let meter = manager.addMeter(withName: meterName, description: "", floor: floor, qrString: qrString, image: nil)
                                manager.addReading(toMeter: meter, with: Double.random(in: 10000...50000))
                            }
                        }
                    }
                }
            }
        }
    }
}
