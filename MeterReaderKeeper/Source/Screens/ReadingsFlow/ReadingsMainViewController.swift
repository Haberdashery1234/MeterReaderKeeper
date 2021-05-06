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
    
    var building: Building?
    var floors = [Floor]()
    var meters = [Meter]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let building = building {
            if let buildFloors = building.floors?.array as? [Floor] {
                floors = buildFloors
                for floor in floors {
                    if let floorMeters = floor.meters {
                        meters.append(contentsOf: floorMeters.array as! [Meter])
                    }
                }
            }
        }
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
            readingVC?.meter = sender as? Meter
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
        return floors.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let meters = floors[section].meters {
            return meters.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingMeterCell") as? ReadingMeterTableViewCell ?? ReadingMeterTableViewCell(style: .default, reuseIdentifier: "ReadingMeterCell")
        if
            let meters = floors[indexPath.section].meters,
            let metersArray = meters.array as? [Meter]
        {
            let meter = metersArray[indexPath.row]
            cell.setup(withMeter: meter)
        }
        return cell
    }
}

extension ReadingsMainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? ReadingMeterTableViewCell
        if let meter = cell?.meter {
            performSegue(withIdentifier: "ReadingMainToAddReadingSegue", sender: meter)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
