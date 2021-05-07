//
//  PreviousReadingTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//

import UIKit

class PreviousReadingTableViewCell: UITableViewCell {

    @IBOutlet weak var readingDetailsLabel: UILabel!
    @IBOutlet weak var readingValueLabel: UILabel!

    var reading = Reading()
    
    func setup(withReading reading: Reading) {
        self.reading = reading
        readingValueLabel.text = String(format: "%.2f kWh", reading.kWh)
        var locationString = ""
        let meter = reading.meter
        let floor = meter.floor
        let building = floor.building
        locationString += "\(meter.name)\n\(building.name) - Floor \(floor.number)"
        readingDetailsLabel.text = locationString
    }
}
