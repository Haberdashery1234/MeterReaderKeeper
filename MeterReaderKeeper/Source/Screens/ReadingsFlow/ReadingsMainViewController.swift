//
//  ReadingsMainViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit
import MessageUI

class ReadingsMainViewController: UIViewController {

    @IBOutlet weak var metersTableView: UITableView!
    @IBOutlet weak var floorTextField: UITextField! {
        didSet {
            floorTextField.inputView = floorPickerView
            floorTextField.inputAccessoryView = keyboardToolbar
        }
    }
    
    var building: Building! {
        didSet {
            floor = building.buildingFloors[0]
        }
    }
    var floors = [Floor]()
    var floor: Floor! {
        didSet {
            if floorTextField != nil {
                floorTextField.text = "Floor \(floor.number)"
            }
            meters = MeterManager.shared.getMeters(forFloor: floor)
        }
    }
    var meters = [Meter]() {
        didSet {
            if metersTableView != nil {
                metersTableView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var floorMapContainer: UIView!
    @IBOutlet weak var floorMapImageView: UIImageView!
    
    var floorPickerView = UIPickerView()
    
    @objc var keyboardToolbar = KeyboardToolbar.init(type: .done)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let building = building {
            floors = building.buildingFloors
            for floor in floors {
                meters.append(contentsOf: floor.floorMeters)
            }
        }
        
        floorPickerView.dataSource = self
        floorPickerView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let buildFloors = building?.floors {
            floors = buildFloors.array as! [Floor]
            metersTableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ReadingMainToAddReadingSegue" {
            let readingVC = segue.destination as? AddEditReadingViewController
            readingVC?.reading = sender as? Reading
            readingVC?.meter = readingVC?.reading?.meter
        } else if segue.identifier == "TakeReadingsMainToQRScannerSegue" {
            let qrVC = segue.destination as? QrScannerViewController
            qrVC?.scannerDelegate = self
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {

        guard
            let building = building,
            let csvData = MeterManager.shared.getCSVData(forBuilding: building)
        else {
            print("Building is nil or csvData is nil")
            return
        }
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([])
            mail.setMessageBody("Readings from today!", isHTML: false)
            mail.addAttachmentData(csvData, mimeType: "text/csv", fileName: "ReadingsCSV.csv")
            
            present(mail, animated: true)
        } else {
            let alertController = UIAlertController(title: "", message: "Email is not configured on this device", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true)
        }
    }
    
    @IBAction func scanQRCodeTapped(_ sender: Any) {
        performSegue(withIdentifier: "TakeReadingsMainToQRScannerSegue", sender: nil)
    }
    
    @IBAction func mapButtonTapped(_ sender: Any) {
        let floorMapData = floor.map
        // DO SOMETHING WITH MAP DATA
        if floorMapData.count > 0 {
            let floorMapImage = UIImage(data: floorMapData)
            floorMapImageView.image = floorMapImage
            UIView.animate(withDuration: Constants.UIValues.animationDuration) {
                self.floorMapContainer.isHidden = false
            }
        } else {
            let alertController = UIAlertController(title: "", message: "No map for this floor", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true)
        }
    }
    
    @IBAction func closeMapButtonTapped(_ sender: Any) {
        UIView.animate(withDuration: Constants.UIValues.animationDuration) {
            self.floorMapContainer.isHidden = true
        }
    }
}

extension ReadingsMainViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension ReadingsMainViewController: QRScannerDelegate {
    func scannedCode(_ codeString: String, errorCompletion: (NSError?) -> ()) {
        print("\(codeString)")
        let filteredMeters = meters.filter { (meter) -> Bool in
            return meter.qrString == codeString
        }
        
        if filteredMeters.count == 1 {
            let meter = filteredMeters[0]
            performSegue(withIdentifier: "ReadingMainToAddReadingSegue", sender: meter)
            dismiss(animated: true, completion: nil)
        } else {
            let error = NSError(domain: "MeterScannerFailed", code: filteredMeters.count, userInfo: nil)
            errorCompletion(error)
        }
    }
}

extension ReadingsMainViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingMeterCell") as? ReadingMeterTableViewCell ?? ReadingMeterTableViewCell(style: .default, reuseIdentifier: "ReadingMeterCell")
        let meter = meters[indexPath.row]
        cell.setup(withMeter: meter)
        return cell
    }
}

extension ReadingsMainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? ReadingMeterTableViewCell
        if let reading = cell?.reading {
            performSegue(withIdentifier: "ReadingMainToAddReadingSegue", sender: reading)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ReadingsMainViewController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        floor = floors[row]
    }
}

extension ReadingsMainViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return floors.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "Floor \(row + 1)"
    }
}

extension ReadingsMainViewController: KeyboardToolbarDelegate {
    func doneButtonTapped() {
        floorTextField.resignFirstResponder()
    }
}
