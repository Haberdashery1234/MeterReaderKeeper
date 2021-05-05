//
//  ReadingsMainViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class ReadingsMainViewController: UIViewController {

    @IBOutlet weak var metersTableView: UITableView!
    
    var building: Building?
    var floors = [Floor]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let buildFloors = building?.floors {
            floors = buildFloors.array as! [Floor]
            metersTableView.reloadData()
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
    
}
