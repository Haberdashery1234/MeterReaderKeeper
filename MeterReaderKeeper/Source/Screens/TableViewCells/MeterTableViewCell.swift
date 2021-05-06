//
//  MeterTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class MeterTableViewCell: UITableViewCell {

    @IBOutlet weak var meterImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!

    var meter = Meter()
    
    func setup(withMeter meter: Meter) {
        self.meter = meter
        nameLabel.text = meter.name
        var locationString = ""
        if
            let floor = meter.floor,
            let building = floor.building,
            let buildingName = building.name
        {
            locationString += "\(buildingName) - Floor \(floor.number)"
        }
        locationLabel.text = locationString
        if let imageData = meter.image {
            meterImageView.image = UIImage(data: imageData)
        }
    }
}
