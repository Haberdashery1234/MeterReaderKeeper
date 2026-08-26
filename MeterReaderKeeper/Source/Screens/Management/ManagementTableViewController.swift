//
//  ManagementTableViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 4/30/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//

import UIKit
import os.log

class ManagementTableViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var repository: MeterRepositoryProtocol!
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "ManagementVC")
    
    private var buildings: [MRKBuilding] = []
    private var floorItems: [(floor: MRKFloor, building: MRKBuilding)] = []
    private var meterItems: [(meter: MRKMeter, floor: MRKFloor, building: MRKBuilding)] = []
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BuildingTableViewCell.self, forCellReuseIdentifier: "BuildingCell")
        tableView.register(FloorTableViewCell.self, forCellReuseIdentifier: "FloorCell")
        tableView.register(MeterTableViewCell.self, forCellReuseIdentifier: "MeterCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Buildings", "Floors", "Meters"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        tableView.reloadData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
        navigationItem.rightBarButtonItem = addButton
    }
    
    // MARK: - Data
    private func loadData() {
        buildings = (try? repository.getBuildings()) ?? []
        floorItems = buildings.flatMap { building in
            building.sortedFloors.map { (floor: $0, building: building) }
        }
        meterItems = buildings.flatMap { building in
            building.sortedFloors.flatMap { floor in
                floor.sortedMeters.map { (meter: $0, floor: floor, building: building) }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func addTapped() {
        if buildings.isEmpty {
            // No buildings exist, must create one first
            coordinator?.showBuildingDetails()
            return
        }
        
        let alert = UIAlertController(
            title: "Add Item",
            message: "What would you like to add?",
            preferredStyle: .actionSheet
        )
        
        // Always allow adding buildings
        alert.addAction(UIAlertAction(title: "Building", style: .default) { [weak self] _ in
            self?.coordinator?.showBuildingDetails()
        })
        
        // Only allow adding meters if floors exist
        if !floorItems.isEmpty {
            alert.addAction(UIAlertAction(title: "Meter", style: .default) { [weak self] _ in
                self?.coordinator?.showMeterDetails()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    @objc private func segmentChanged() {
        logger.info("Segment changed to index: \(self.segmentedControl.selectedSegmentIndex)")
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate
extension ManagementTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Buildings
            let building = buildings[indexPath.row]
            coordinator?.showBuildingDetails(building: building)
            
        case 1: // Floors
            let item = floorItems[indexPath.row]
            coordinator?.showFloorDetails(floor: item.floor, building: item.building)
            
        case 2: // Meters
            let item = meterItems[indexPath.row]
            coordinator?.showMeterDetails(meter: item.meter, floor: item.floor, building: item.building)
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch segmentedControl.selectedSegmentIndex {
        case 0: return 65  // Buildings
        case 1: return 50  // Floors
        case 2: return 40  // Meters
        default: return 40
        }
    }
}

// MARK: - UITableViewDataSource
extension ManagementTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0: return buildings.count
        case 1: return floorItems.count
        case 2: return meterItems.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Buildings
            let cell = tableView.dequeueReusableCell(withIdentifier: "BuildingCell", for: indexPath) as! BuildingTableViewCell
            cell.setup(withBuilding: buildings[indexPath.row])
            return cell
            
        case 1: // Floors
            let cell = tableView.dequeueReusableCell(withIdentifier: "FloorCell", for: indexPath) as! FloorTableViewCell
            let item = floorItems[indexPath.row]
            cell.setup(floor: item.floor, buildingName: item.building.name)
            return cell
            
        case 2: // Meters
            let cell = tableView.dequeueReusableCell(withIdentifier: "MeterCell", for: indexPath) as! MeterTableViewCell
            let item = meterItems[indexPath.row]
            cell.setup(meter: item.meter, locationString: "\(item.building.name) - Floor \(item.floor.number)")
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}
