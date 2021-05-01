//
//  AddMeterViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//

import UIKit
import CoreData

class AddEditMeterViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    var meter: NSManagedObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let meter = meter {
            nameTextField.text = meter.value(forKey: "name") as? String
            descriptionTextField.text = meter.value(forKey: "meterDescription") as? String
        }
        deleteButton.isHidden = meter == nil
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        guard
            let nameText = nameTextField.text,
            let descriptionText = descriptionTextField.text
        else {
            return
        }
        
        let qrUUID = NSUUID()
        
        MeterManager.shared.save(name: nameText, description: descriptionText, qrString: qrUUID, map: nil, image: nil)
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        guard let meter = meter else {
            print("Nothing to delete.")
            return
        }
        MeterManager.shared.delete(meter: meter)
        navigationController?.popViewController(animated: true)
    }
    
}
