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
    @IBOutlet weak var readingTextField: UITextField!
    @IBOutlet weak var meterImageView: UIImageView!
    
    var floor: Floor!
    var meter: Meter!
    var reading: Reading?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
            MeterManager.shared.addReading(toMeter: meter, with: meterReading)
        }
        navigationController?.popViewController(animated: true)
    }
    
}
