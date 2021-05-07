//
//  HomeViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//

import UIKit
import MessageUI

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func seedData() {
        if MeterManager.shared.buildings.count == 0 {
            DataSeeder.shared.seedData()
        } else {
            DataSeeder.shared.seedMoreReadings()
        }
    }
    
    @IBAction func exportData(_ sender: Any) {
        MeterManager.shared.saveDataToPlist()
        sendPlist()
    }
    
    func sendPlist() {

        do {
            let fileManager = FileManager.default
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("ExportData.plist")
            
            if fileManager.fileExists(atPath: fileURL.path){
                if let plistData = NSData(contentsOfFile: fileURL.path) {
                    if MFMailComposeViewController.canSendMail() {
                        let mail = MFMailComposeViewController()
                        mail.mailComposeDelegate = self
                        mail.setToRecipients([])
                        mail.setMessageBody("Export!", isHTML: false)
                        mail.addAttachmentData(plistData as Data, mimeType: "application/xml", fileName: "exportData.plist")
                        
                        present(mail, animated: true)
                    } else {
                        let alertController = UIAlertController(title: "", message: "Email is not configured on this device", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        present(alertController, animated: true)
                    }
                }
            }
        } catch {
            print("error creating file")
        }
    }
    
    @IBAction func previousReadingsTapped(_ sender: Any) {
        performSegue(withIdentifier: "HomeToPreviousReadingsSegue", sender: nil)
    }
}

extension HomeViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
