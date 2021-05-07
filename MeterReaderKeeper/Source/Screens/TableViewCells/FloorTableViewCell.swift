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
        let nameString = "\(floor.building.name) - Floor \(floor.number)"
        nameLabel.text = nameString
        metersLabel.text = "\(floor.floorMeters.count) Meters"
        if let mapData = floor.map {
            floorMapImageView.image = UIImage(data: mapData)
        }
    }
}
