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
    
    var building = Building()
    
    func setup(withBuilding building: Building) {
        self.building = building
        nameLabel.text = building.name
        floorsLabel.text = "\(building.floors.count) Floors"
        
        // TODO: - Implement meter count by building
        metersLabel.text = "XX Meters"
    }
}
