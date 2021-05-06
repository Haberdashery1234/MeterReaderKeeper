//
//  PreviousReadingsViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//

import UIKit

class PreviousReadingsViewController: UIViewController, UIToolbarDelegate {

    @IBOutlet weak var dateTextField: UITextField! {
        didSet {
            dateTextField.inputView = datePickerView
            dateTextField.inputAccessoryView = keyboardToolbar
        }
    }
    
    @IBOutlet weak var buildingTextField: UITextField! {
        didSet {
            buildingTextField.inputView = buildingPickerView
            buildingTextField.inputAccessoryView = keyboardToolbar
        }
    }
    @IBOutlet weak var floorTextField: UITextField! {
        didSet {
            floorTextField.inputView = floorPickerView
            floorTextField.inputAccessoryView = keyboardToolbar
        }
    }
    @IBOutlet weak var meterTextField: UITextField! {
        didSet {
            meterTextField.inputView = meterPickerView
            meterTextField.inputAccessoryView = keyboardToolbar
        }
    }
    
    @IBOutlet weak var previousReadingsSegmentedControl: UISegmentedControl!
    
    var activeField: UITextField?
    
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var buildingStackView: UIStackView!
    @IBOutlet weak var floorStackView: UIStackView!
    @IBOutlet weak var meterStackView: UIStackView!
    
    @IBOutlet weak var readingsTableView: UITableView!
    
    var datePickerView = UIPickerView()
    var buildingPickerView = UIPickerView()
    var floorPickerView = UIPickerView()
    var meterPickerView = UIPickerView()
    
    var buildings = [Building]()
    var building: Building? {
        didSet {
            if let building = building {
                buildingTextField.text = building.name
                if let buildFloors = building.floors {
                    floors = buildFloors.array as! [Floor]
                }
            } else {
                buildingTextField.text = "All"
            }
            floor = nil
        }
    }
    
    var floors = [Floor]()
    var floor: Floor? {
        didSet {
            if let floor = floor {
                floorTextField.text = "Floor \(floor.number)"
                if let floorMeters = floor.meters {
                    meters = floorMeters.array as! [Meter]
                }
            } else {
                floorTextField.text = "All"
            }
            meter = nil
        }
    }
    
    var meters = [Meter]()
    var meter: Meter? {
        didSet {
            if let meter = meter {
                meterTextField.text = meter.name
            } else {
                meterTextField.text = "All"
            }
        }
    }
    var dates = [Date]()
    var date: Date? {
        didSet {
            if let date = date {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .none
                dateTextField.text = formatter.string(from: date)
            } else {
                dateTextField.text = "All"
            }
        }
    }
    
    var readings = [Reading]()
    
    @objc var keyboardToolbar = KeyboardToolbar.init(type: .done)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        keyboardToolbar.delegate = self
        
        buildingPickerView.dataSource = self
        buildingPickerView.delegate = self
        
        floorPickerView.dataSource = self
        floorPickerView.delegate = self
        
        meterPickerView.dataSource = self
        meterPickerView.delegate = self
        
        datePickerView.dataSource = self
        datePickerView.delegate = self
        
        MeterManager.shared.loadAllReadings()

        buildings = MeterManager.shared.buildings
        dates = Array(MeterManager.shared.allReadingsDates.keys)
        
        if MeterManager.shared.buildings.count == 1 {
            building = MeterManager.shared.buildings[0]
        }
        
        building = nil
        date = nil
        
        updateReadings()
    }
    
    func updateReadings() {
        print("Updating readings")
        if previousReadingsSegmentedControl.selectedSegmentIndex == 0 {
            if let meter = meter {
                readings = MeterManager.shared.getReadings(forMeter: meter)
            } else if let floor = floor {
                readings = MeterManager.shared.getReadings(forFloor: floor)
            } else if let building = building {
                readings = MeterManager.shared.getReadings(forBuilding: building)
            } else {
                readings = MeterManager.shared.allReadings
            }
        } else if previousReadingsSegmentedControl.selectedSegmentIndex == 1 {
            if let date = date {
                readings = MeterManager.shared.getReadings(forDate: date)
            } else {
                readings = MeterManager.shared.allReadings
            }
        }
        readingsTableView.reloadData()
    }
    @IBAction func previousMethodChanged(_ sender: Any) {
        if previousReadingsSegmentedControl.selectedSegmentIndex == 0 {
            UIView.animate(withDuration: Constants.UIValues.animationDuration) {
                self.dateStackView.isHidden = true
                self.buildingStackView.isHidden = false
                self.floorStackView.isHidden = false
                self.meterStackView.isHidden = false
                self.view.setNeedsLayout()
            }
        } else if previousReadingsSegmentedControl.selectedSegmentIndex == 1 {
            UIView.animate(withDuration: Constants.UIValues.animationDuration) {
                self.dateStackView.isHidden = false
                self.buildingStackView.isHidden = true
                self.floorStackView.isHidden = true
                self.meterStackView.isHidden = true
                self.view.setNeedsLayout()
            }
        }
    }
}

extension PreviousReadingsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false // don't want people with external keyboards typing in here
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeField = textField
        return true
    }
}


extension PreviousReadingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return readings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PreviousReadingCell") as? PreviousReadingTableViewCell ?? PreviousReadingTableViewCell(style: .default, reuseIdentifier: "PreviousReadingCell")
        let reading = readings[indexPath.row]
        cell.setup(withReading: reading)
        return cell
    }
}

extension PreviousReadingsViewController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView == buildingPickerView {
            if row == 0 {
                building = nil
            } else {
                building = MeterManager.shared.buildings[row-1]
            }
        } else if pickerView == floorPickerView {
            if row == 0 {
                floor = nil
            } else {
                floor = floors[row-1]
            }
        } else if pickerView == meterPickerView {
            if row == 0 {
                meter = nil
            } else {
                meter = meters[row-1]
            }
        } else if pickerView == datePickerView {
            if row == 0 {
                date = nil
            } else {
                date = dates[row-1]
            }
        }
    }
}

extension PreviousReadingsViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == buildingPickerView {
            return MeterManager.shared.buildings.count + 1
        } else if pickerView == floorPickerView {
            return floors.count + 1
        } else if pickerView == meterPickerView {
            return meters.count + 1
        } else if pickerView == datePickerView {
            return dates.count + 1
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "All"
        } else if pickerView == buildingPickerView {
            let building = MeterManager.shared.buildings[row-1]
            return building.name
        } else if pickerView == floorPickerView {
            return "\(row)"
        } else if pickerView == meterPickerView {
            let meter = meters[row-1]
            return meter.name
        } else if pickerView == datePickerView {
            let date = dates[row-1]
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        return ""
    }
}

extension PreviousReadingsViewController: KeyboardToolbarDelegate {
    func doneButtonTapped() {
        activeField?.resignFirstResponder()
        updateReadings()
    }
}
