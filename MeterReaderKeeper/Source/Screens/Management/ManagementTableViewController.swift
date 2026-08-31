//
//  ManagementTableViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 4/30/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//  Thinned to use ManagementViewModel on 8/26/26.
//

import UIKit

/// The Management screen: a segmented, sectioned-by-building list of
/// Buildings/Floors/Meters, with an Add button that adjusts to the current
/// segment. Owns all UI presentation; `ManagementViewModel` owns the data
/// behind it.
class ManagementTableViewController: UIViewController {

    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var viewModel: ManagementViewModel!

    /// The currently selected segment, read from `segmentedControl`.
    private var selectedSegment: ManagementViewModel.Segment {
        ManagementViewModel.Segment(rawValue: segmentedControl.selectedSegmentIndex) ?? .buildings
    }
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BuildingTableViewCell.self, forCellReuseIdentifier: "BuildingCell")
        tableView.register(FloorTableViewCell.self, forCellReuseIdentifier: "FloorCell")
        tableView.register(MeterTableViewCell.self, forCellReuseIdentifier: "MeterCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "Management.tableView"
        return tableView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Buildings", "Floors", "Meters"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.accessibilityIdentifier = "Management.segmentedControl"
        return control
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
    }

    /// Reloads every segment's data each time this screen becomes visible,
    /// so changes made in Add/Edit or Floor Meters are reflected.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { @MainActor in
            await viewModel.loadData()
            tableView.reloadData()
        }
    }

    // MARK: - Setup

    /// Adds the segmented control and table view to the view hierarchy.
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(segmentedControl)
        view.addSubview(tableView)
    }

    /// Activates the segmented control / table view Auto Layout constraints.
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
    
    /// Adds the nav-bar "+" button that opens `addTapped()`'s action sheet.
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
        addButton.accessibilityIdentifier = "Management.addButton"
        navigationItem.rightBarButtonItem = addButton
    }
    
    // MARK: - Actions

    /// Presents an action sheet to add a Building or (if any floor exists)
    /// a Meter — or jumps straight to Add Building if none exist yet, since
    /// there'd be nothing else to add to.
    @objc private func addTapped() {
        if viewModel.buildings.isEmpty {
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
        if viewModel.hasFloors {
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
    
    /// Reloads the table to show the newly selected segment's rows.
    @objc private func segmentChanged() {
        print("Segment changed to index: \(self.segmentedControl.selectedSegmentIndex)")
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate
extension ManagementTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch selectedSegment {
        case .buildings:
            let building = viewModel.buildings[indexPath.row]
            coordinator?.showBuildingDetails(building: building)
            
        case .floors:
            // Floor rows now open the Floor Meters screen (view/add/delete
            // meters, see last-read date+value) rather than the floor's
            // own edit form (2026-08-28) — that form is still reachable
            // from there via its Edit button.
            let item = viewModel.floorSections[indexPath.section].items[indexPath.row]
            coordinator?.showFloorMeters(floor: item.floor, building: item.building)
            
        case .meters:
            let item = viewModel.meterSections[indexPath.section].items[indexPath.row]
            coordinator?.showMeterDetails(meter: item.meter, floor: item.floor, building: item.building)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // All three cells self-size now (2026-08-28) — each pins its text
        // stack to the contentView's top and bottom instead of centering
        // it, so UITableView.automaticDimension (already set as the table's
        // default rowHeight) can compute a real height per row instead of
        // a guessed fixed constant clipping/overlapping content.
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Buildings segment is already one row per building, so it doesn't
        // need a "grouped by building" header the way Floors/Meters do.
        switch selectedSegment {
        case .buildings: return nil
        case .floors: return viewModel.floorSections[section].building.name
        case .meters: return viewModel.meterSections[section].building.name
        }
    }
}

// MARK: - UITableViewDataSource
extension ManagementTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        switch selectedSegment {
        case .buildings: return 1
        case .floors: return viewModel.floorSections.count
        case .meters: return viewModel.meterSections.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedSegment {
        case .buildings: return viewModel.buildings.count
        case .floors: return viewModel.floorSections[section].items.count
        case .meters: return viewModel.meterSections[section].items.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedSegment {
        case .buildings:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BuildingCell", for: indexPath) as! BuildingTableViewCell
            cell.setup(withBuilding: viewModel.buildings[indexPath.row])
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .floors:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FloorCell", for: indexPath) as! FloorTableViewCell
            let item = viewModel.floorSections[indexPath.section].items[indexPath.row]
            cell.setup(floor: item.floor)
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .meters:
            // Just "Floor N", not "Building - Floor N" — the section
            // header above already names the building.
            let cell = tableView.dequeueReusableCell(withIdentifier: "MeterCell", for: indexPath) as! MeterTableViewCell
            let item = viewModel.meterSections[indexPath.section].items[indexPath.row]
            cell.setup(meter: item.meter, locationString: item.floor.displayName)
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
}
