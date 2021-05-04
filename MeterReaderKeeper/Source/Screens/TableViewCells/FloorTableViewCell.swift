//
//  FloorTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class FloorTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var metersLabel: UILabel!

    func setup(withFloor floor: Floor) {
        var nameString = ""
        if
            let building = floor.building,
            let buildingName = building.name
        {
            nameString += "\(buildingName) - "
        }
        nameString += "Floor \(floor.number)"
        nameLabel.text = nameString
        if let meters = floor.meters {
            metersLabel.text = "\(meters.count) Meters"
        }
    }
}
