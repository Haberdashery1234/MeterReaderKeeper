//
//  ReadingMeterTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class ReadingMeterTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var readingDoneCheckImageView: UIImageView!
    
    func setup(withMeter meter: Meter) {
        nameLabel.text = meter.name
    }
    
    func readingMade() {
        // update cell for readings
        readingDoneCheckImageView.isHidden = false
    }
}
