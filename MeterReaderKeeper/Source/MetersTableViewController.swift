//
//  ViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 4/30/21.
//

import UIKit

class MetersTableViewController: UIViewController {

    let buildingDetailsSegue = "MeterTableToBuildingDetailsSegue"
    let floorDetailsSegue = "MeterTableToFloorDetailsSegue"
    let meterDetailsSegue = "MeterTableToMeterDetailsSegue"
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.register(UITableViewCell.self,
                             forCellReuseIdentifier: "Cell")
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
        
        let floorAction = UIAlertAction(title: "Floor", style: .default) { (_) in
            self.performSegue(withIdentifier: self.floorDetailsSegue, sender: nil)
        }
        alert.addAction(floorAction)
        
        if MeterManager.shared.floors.count > 0 {
            let meterAction = UIAlertAction(title: "Meter", style: .default) { (_) in
                self.performSegue(withIdentifier: self.meterDetailsSegue, sender: nil)
            }
            alert.addAction(meterAction)
        }
        
        present(alert, animated: true, completion: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == meterDetailsSegue {
            let meterDetailsVC = segue.destination as? AddEditMeterViewController
            if let meter = sender as? Meter {
                meterDetailsVC?.meter = meter
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension MetersTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: meterDetailsSegue, sender: MeterManager.shared.meters[indexPath.row])
    }
}

// MARK: - UITableViewDataSource
extension MetersTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MeterManager.shared.meters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let meter = MeterManager.shared.meters[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = meter.value(forKeyPath: "name") as? String
        return cell
    }
}
