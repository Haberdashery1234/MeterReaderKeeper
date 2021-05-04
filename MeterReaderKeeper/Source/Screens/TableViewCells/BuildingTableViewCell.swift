//
//  BuildingTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class BuildingTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var floorsLabel: UILabel!
    @IBOutlet weak var metersLabel: UILabel!
    
    func setup(withBuilding building: Building) {
        nameLabel.text = building.name
        if let floors = building.floors {
            floorsLabel.text = "\(floors.count) Floors"
        }
        // TODO: - Implement meter count by building
        metersLabel.text = "XX Meters"
    }
}
