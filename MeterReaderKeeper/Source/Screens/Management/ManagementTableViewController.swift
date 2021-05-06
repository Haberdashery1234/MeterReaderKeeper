//
//  ViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 4/30/21.
//

import UIKit

class ManagementTableViewController: UIViewController {

    let buildingDetailsSegue = "MeterTableToBuildingDetailsSegue"
    let floorDetailsSegue = "MeterTableToFloorDetailsSegue"
    let meterDetailsSegue = "MeterTableToMeterDetailsSegue"
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var listSourceSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @IBAction func addTapped(_ sender: Any) {
        
        if MeterManager.shared.buildings.count == 0 {
            performSegue(withIdentifier: buildingDetailsSegue, sender: nil)
            return
        }
        
        let alert = UIAlertController(title: "", message: "What would you like to add?", preferredStyle: .actionSheet)
        let buildingAction = UIAlertAction(title: "Building", style: .default) { (_) in
            self.performSegue(withIdentifier: self.buildingDetailsSegue, sender: nil)
        }
        alert.addAction(buildingAction)
        
        if MeterManager.shared.floors.count > 0 {
            let meterAction = UIAlertAction(title: "Meter", style: .default) { (_) in
                self.performSegue(withIdentifier: self.meterDetailsSegue, sender: nil)
            }
            alert.addAction(meterAction)
        }
        
        present(alert, animated: true, completion: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == buildingDetailsSegue {
            let buildingDetailsVC = segue.destination as? AddEditBuildingViewController
            if let building = sender as? Building {
                buildingDetailsVC?.building = building
            }
        } else if segue.identifier == floorDetailsSegue {
            let floorDetailsVC = segue.destination as? AddEditFloorViewController
            if let floor = sender as? Floor {
                floorDetailsVC?.floor = floor
            }
        } else if segue.identifier == meterDetailsSegue {
            let meterDetailsVC = segue.destination as? AddEditMeterViewController
            if let meter = sender as? Meter {
                meterDetailsVC?.meter = meter
            }
        }
    }
    
    @IBAction func listSegmentedControlChanged(_ sender: Any) {
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate
extension ManagementTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch listSourceSegmentedControl.selectedSegmentIndex {
        case 0:
            performSegue(withIdentifier: buildingDetailsSegue, sender: MeterManager.shared.buildings[indexPath.row])
        case 1:
            performSegue(withIdentifier: floorDetailsSegue, sender: MeterManager.shared.floors[indexPath.row])
        case 2:
            performSegue(withIdentifier: meterDetailsSegue, sender: MeterManager.shared.meters[indexPath.row])
        default:
            return
        }
    }
}

// MARK: - UITableViewDataSource
extension ManagementTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch listSourceSegmentedControl.selectedSegmentIndex {
        case 0:
            return MeterManager.shared.buildings.count
        case 1:
            return MeterManager.shared.floors.count
        case 2:
            return MeterManager.shared.meters.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch listSourceSegmentedControl.selectedSegmentIndex {
        case 0:
            return 65
        case 1:
            return 50
        case 2:
            return 40
        default:
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch listSourceSegmentedControl.selectedSegmentIndex {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BuildingCell") as? BuildingTableViewCell ?? BuildingTableViewCell(style: .default, reuseIdentifier: "BuildingCell")
            let building = MeterManager.shared.buildings[indexPath.row]
            cell.setup(withBuilding: building)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FloorCell") as? FloorTableViewCell ?? FloorTableViewCell(style: .default, reuseIdentifier: "FloorCell")
            let floor = MeterManager.shared.floors[indexPath.row]
            cell.setup(withFloor: floor)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MeterCell") as? MeterTableViewCell ?? MeterTableViewCell(style: .default, reuseIdentifier: "MeterCell")
            let meter = MeterManager.shared.meters[indexPath.row]
            cell.setup(withMeter: meter)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = "Nothing"
            return cell
        }
        
    }
}
