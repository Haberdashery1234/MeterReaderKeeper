//
//  HomeViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if MeterManager.shared.buildings.count == 0 {        
            DataSeeder.shared.seedData()
        }
    }
    
    @IBAction func previousReadingsTapped(_ sender: Any) {
        performSegue(withIdentifier: "HomeToPreviousReadingsSegue", sender: nil)
    }
}
