//
//  AddEditFloorViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class AddEditFloorViewController: UIViewController {

    
    @IBOutlet weak var buildingTextField: UITextField! {
        didSet {
            buildingTextField.inputView = buildingPickerView
        }
    }
    @IBOutlet weak var floorTextField: UITextField!
    @IBOutlet weak var currentMapImageView: UIImageView!
    @IBOutlet weak var addMapButton: UIButton!

    var buildingPickerView = UIPickerView()
    
    var building: Building? {
        didSet {
            buildingTextField.text = building?.name
        }
    }
    var floor: Floor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildingPickerView.dataSource = self
        buildingPickerView.delegate = self
        
        if MeterManager.shared.buildings.count == 1 {
            building = MeterManager.shared.buildings[0]
        }
        
        if let floor = floor {
            building = floor.building
            buildingTextField.text = building?.name
            floorTextField.text = "\(floor.number)"
            if floor.map != Data() {
                currentMapImageView.image = UIImage(data: floor.map)
            } else {
                currentMapImageView.isHidden = true
            }
        }
    }
    
    @IBAction func addMapTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        guard
            let building = building,
            let floorNumberText = floorTextField.text,
            let floorNumber = Int16(floorNumberText)
        else {
            print("MISSING DATA")
            return
        }
        
        var mapData = Data()
        if let image = currentMapImageView.image {
            mapData = image.pngData() ?? Data()
        }
        guard let floor = floor else {
            print("Floor is nil")
            return
        }
        floor.building = building
        floor.number = floorNumber
        floor.map = mapData
        
        MeterManager.shared.saveFloor(floor)
        
        navigationController?.popViewController(animated: true)
    }
}

extension AddEditFloorViewController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        building = MeterManager.shared.buildings[row]
    }
}

extension AddEditFloorViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return MeterManager.shared.buildings.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let building = MeterManager.shared.buildings[row]
        return building.name
    }
}

extension AddEditFloorViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            currentMapImageView.contentMode = .scaleAspectFit
            currentMapImageView.image = pickedImage
            currentMapImageView.isHidden = false
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension AddEditFloorViewController: UINavigationControllerDelegate {
    
}
