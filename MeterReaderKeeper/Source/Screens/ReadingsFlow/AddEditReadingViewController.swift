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
        
    }
    
}
