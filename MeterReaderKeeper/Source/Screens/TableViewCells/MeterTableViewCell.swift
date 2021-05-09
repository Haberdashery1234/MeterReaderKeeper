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
        let floor = meter.floor
        locationLabel.text =  "\(floor.building.name) - Floor \(floor.number)"
        meterImageView.image = UIImage(data: meter.image)
    }
}
