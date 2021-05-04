//
//  AddEditBuildingViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/3/21.
//

import UIKit
import CoreData

class AddEditBuildingViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var floorsTextField: UITextField!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    var building: Building?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let building = building {
            nameTextField.text = building.name
            if let floors = building.floors {
                floorsTextField.text = "\(floors.count)"
            }
        }
        deleteButton.isHidden = building == nil
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        guard
            let nameText = nameTextField.text,
            let floorsText = floorsTextField.text
        else {
            return
        }
        
        
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        guard let building = building else {
            print("Nothing to delete.")
            return
        }
        
        navigationController?.popViewController(animated: true)
    }
    
}
