//
//  ViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 4/30/21.
//

import UIKit
import CoreData

class MetersTableViewController: UIViewController {

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
    
    @IBAction func addMeter(_ sender: Any) {
        performSegue(withIdentifier: meterDetailsSegue, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == meterDetailsSegue {
            let meterDetailsVC = segue.destination as? AddEditMeterViewController
            if let meter = sender as? NSManagedObject {
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
