//
//  PreviousReadingTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//

import UIKit

class PreviousReadingTableViewCell: UITableViewCell {

    @IBOutlet weak var readingMeterLabel: UILabel!
    @IBOutlet weak var readingLocationLabel: UILabel!
    @IBOutlet weak var readingValueLabel: UILabel!
    @IBOutlet weak var readingDateLabel: UILabel!

    var reading = Reading()
    
    func setup(withReading reading: Reading) {
        self.reading = reading
        readingValueLabel.text = String(format: "%.2f kWh", reading.kWh)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        readingDateLabel.text = formatter.string(from: reading.date)
        
        let meter = reading.meter
        readingMeterLabel.text = meter.name
        let floor = meter.floor
        let building = floor.building
        let locationString = "\(building.name) - Floor \(floor.number)"
        readingLocationLabel.text = locationString
    }
}
