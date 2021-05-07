//
//  ReadingMeterTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class ReadingMeterTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var readingDoneCheckImageView: UIImageView!

    var meter = Meter()
    var reading: Reading?
    
    func setup(withMeter meter: Meter) {
        readingDoneCheckImageView.isHidden = true
        self.meter = meter
        nameLabel.text = meter.name
        
        let floorNumber = meter.floor.number
        locationLabel.text = "Floor \(floorNumber)"
        
        let meterReadings = meter.meterReadings
        let date = Calendar.current.startOfDay(for: Date())
        let todaysReadings = meterReadings.filter { (reading) -> Bool in
            return reading.date == date
        }
        
        if todaysReadings.count > 0 {
            reading = todaysReadings[0]
            readingMade()
        }
    }
    
    func readingMade() {
        // update cell for readings
        readingDoneCheckImageView.isHidden = false
    }
}
