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
    
    func setup(withMeter meter: Meter) {
        readingDoneCheckImageView.isHidden = true
        self.meter = meter
        nameLabel.text = meter.name
        if let floor = meter.floor {
            let floorNumber = floor.number
            locationLabel.text = "Floor \(floorNumber)"
        }
        if let readings = meter.readings {
            let date = Calendar.current.startOfDay(for: Date()) as NSDate
            let todaysReadings = readings.filtered(using: NSPredicate(format: "date == %@", date))
            if todaysReadings.count > 0 {
                readingMade()
            }
        }
    }
    
    func readingMade() {
        // update cell for readings
        readingDoneCheckImageView.isHidden = false
    }
}
