//
//  AddMeterViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//

import UIKit
import CoreData

class AddEditMeterViewController: UIViewController {

    @IBOutlet weak var buildingTextField: UITextField! {
        didSet {
            buildingTextField.inputView = buildingPickerView
        }
    }
    @IBOutlet weak var floorTextField: UITextField! {
        didSet {
            floorTextField.inputView = floorPickerView
        }
    }
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var meterImageImageView: UIImageView!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    var buildingPickerView = UIPickerView()
    var floorPickerView = UIPickerView()
    
    var building: Building? {
        didSet {
            if let building = building {
                buildingTextField.text = building.name
                if let buildFloors = building.floors {
                    floors = buildFloors.array as! [Floor]
                }
            }
        }
    }
        
    var floors = [Floor]()
    var floor: Floor? {
        didSet {
            if let floor = floor {
                floorTextField.text = "Floor \(floor.number)"
            }
        }
    }
    var meter: Meter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildingPickerView.dataSource = self
        buildingPickerView.delegate = self
        
        floorPickerView.dataSource = self
        floorPickerView.delegate = self
        
        if MeterManager.shared.buildings.count == 1 {
            building = MeterManager.shared.buildings[0]
        }
        
        if let meter = meter {
            if let meterFloor = meter.floor,
               let meterBuilding = meterFloor.building {
                building = meterBuilding
                floor = meterFloor
            }
            nameTextField.text = meter.name
            descriptionTextField.text = meter.meterDescription
        }
        deleteButton.isHidden = meter == nil
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        guard
            let building = building,
            let buildingName = building.name,
            let floor = floor,
            let nameText = nameTextField.text,
            let descriptionText = descriptionTextField.text
        else {
            return
        }
        
        _ = MeterManager.shared.addMeter(withName: nameText, description: descriptionText, floor: floor, image: meterImageImageView.image?.pngData(), buildingName: buildingName)
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        guard let meter = meter else {
            print("Nothing to delete.")
            return
        }
        MeterManager.shared.deleteMeter(meter)
        navigationController?.popViewController(animated: true)
    }
    
}

extension AddEditMeterViewController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == buildingPickerView {
            building = MeterManager.shared.buildings[row]
        } else if pickerView == floorPickerView {
            floor = floors[row]
        }
    }
}

extension AddEditMeterViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == buildingPickerView {
            return MeterManager.shared.buildings.count
        } else if pickerView == floorPickerView {
            return floors.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == buildingPickerView {
            let building = MeterManager.shared.buildings[row]
            return building.name
        } else if pickerView == floorPickerView {
            return "\(row+1)"
        }
        return ""
    }
}

extension AddEditMeterViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            meterImageImageView.contentMode = .scaleAspectFit
            meterImageImageView.image = pickedImage
            meterImageImageView.isHidden = false
        }
        
        dismiss(animated: true, completion: nil)
    }
}
