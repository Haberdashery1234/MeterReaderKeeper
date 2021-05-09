//
//  AddEditReadingViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//

import UIKit

class AddEditReadingViewController: UIViewController {
    
    @IBOutlet weak var buildingNameLabel: UILabel!
    @IBOutlet weak var floorLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var readingTextField: UITextField!
    @IBOutlet weak var meterImageView: UIImageView!
    
    var floor: Floor!
    var meter: Meter!
    var reading: Reading?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let meter = meter {
            let floor = meter.floor
            let building = floor.building
            let buildingName = building.name
            buildingNameLabel.text = buildingName
            floorLabel.text = "Floor \(floor.number)"
            descriptionLabel.text = meter.meterDescription
            meterImageView.image = UIImage(data: meter.image)
        }
        
        if let reading = reading {
            readingTextField.text = "\(reading.kWh)"
        }
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        guard
            let meterReadingString = readingTextField.text,
            let meter = meter,
            let meterReading = Double(meterReadingString)
        else {
            print("Missing required data")
            return
        }
        
        if let reading = reading {
            MeterManager.shared.updateReading(reading, with: meterReading)
        } else {
            let date = Calendar.current.startOfDay(for: Date())
            MeterManager.shared.addReading(toMeter: meter, withKWH: meterReading, date: date)
        }
        navigationController?.popViewController(animated: true)
    }
    
}
