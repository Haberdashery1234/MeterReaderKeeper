//
//  MeterQRReader.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/1/21.
//

import UIKit
import AVKit

class MeterQRReaderViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        determineCaptureAuthorization()
    }
    
    func determineCaptureAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
          AVCaptureDevice.requestAccess(for: .video) { [self] granted in
            if !granted {
              showPermissionsAlert()
            }
          }

        case .denied, .restricted:
          showPermissionsAlert()

        default:
          return
        }
    }
    
    func showPermissionsAlert() {
        
    }
    
    func setupCameraLiveView() {
        
    }
}
