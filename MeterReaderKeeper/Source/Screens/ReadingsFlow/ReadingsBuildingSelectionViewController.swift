//
//  ReadingsBuildingSelectionViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class ReadingsBuildingSelectionViewController: UIViewController {

    @IBOutlet weak var buildingPickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if MeterManager.shared.buildings.count == 1 {
            proceedToStart(with: MeterManager.shared.buildings[0])
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func startReadingsTapped(_ sender: Any) {
        let building = MeterManager.shared.buildings[buildingPickerView.selectedRow(inComponent: 0)]
        
        proceedToStart(with: building)
    }
    
    func proceedToStart(with building: Building) {
        performSegue(withIdentifier: "startReadingsSegue", sender: building)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startReadingsSegue" {
            let readingMainVC = segue.destination as? ReadingsMainViewController
            if let building = sender as? Building {
                readingMainVC?.building = building
                readingMainVC?.title = building.name
            }
        }
    }
}

extension ReadingsBuildingSelectionViewController: UIPickerViewDataSource, UIPickerViewDelegate {
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
