//
//  FloorTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class FloorTableViewCell: UITableViewCell {

    @IBOutlet weak var floorMapImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var metersLabel: UILabel!

    var floor = Floor()
    
    func setup(withFloor floor: Floor) {
        self.floor = floor
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
        if let mapData = floor.map {
            floorMapImageView.image = UIImage(data: mapData)
        }
    }
}
