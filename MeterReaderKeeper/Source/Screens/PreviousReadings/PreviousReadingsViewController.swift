//
//  PreviousReadingsViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//

import UIKit

class PreviousReadingsViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    
    private var buildings = [Building]()
    private var building: Building?
    private var floors = [Floor]()
    private var floor: Floor?
    private var meters = [Meter]()
    private var meter: Meter?
    private var dates = [Date]()
    private var date: Date?
    private var readings = [Reading]()
    
    // MARK: - UI Components
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Date", "Building", "Floor", "Meter"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    // Filter TextFields
    private lazy var dateTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "All"
        textField.borderStyle = .roundedRect
        textField.inputView = datePickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var buildingTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "All"
        textField.borderStyle = .roundedRect
        textField.inputView = buildingPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var floorTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "All"
        textField.borderStyle = .roundedRect
        textField.inputView = floorPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var meterTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "All"
        textField.borderStyle = .roundedRect
        textField.inputView = meterPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReadingCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // Pickers
    private lazy var datePickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    private lazy var buildingPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    private lazy var floorPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    private lazy var meterPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadData()
        applyFilters()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(segmentedControl)
        view.addSubview(dateTextField)
        view.addSubview(buildingTextField)
        view.addSubview(floorTextField)
        view.addSubview(meterTextField)
        view.addSubview(tableView)
        
        updateVisibleFilters()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Date TextField
            dateTextField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            dateTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dateTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Building TextField
            buildingTextField.topAnchor.constraint(equalTo: dateTextField.bottomAnchor, constant: 12),
            buildingTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buildingTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buildingTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Floor TextField
            floorTextField.topAnchor.constraint(equalTo: buildingTextField.bottomAnchor, constant: 12),
            floorTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            floorTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            floorTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Meter TextField
            meterTextField.topAnchor.constraint(equalTo: floorTextField.bottomAnchor, constant: 12),
            meterTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            meterTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            meterTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: meterTextField.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func loadData() {
        // Load all data for filtering
        MeterManager.shared.loadAllReadings()
        buildings = MeterManager.shared.buildings
        dates = Array(MeterManager.shared.allReadingsDates.keys).sorted(by: >)
        
        print("Loaded \(self.buildings.count) buildings and \(self.dates.count) dates")
    }
    
    private func updateVisibleFilters() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        dateTextField.isHidden = selectedIndex != 0
        buildingTextField.isHidden = selectedIndex != 1
        floorTextField.isHidden = selectedIndex != 2
        meterTextField.isHidden = selectedIndex != 3
    }
    
    private func applyFilters() {
        readings.removeAll()
        
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Date
            if let date = date {
                readings = MeterManager.shared.getReadings(forDate: date)
            } else {
                readings = MeterManager.shared.allReadings
            }
        case 1: // Building
            if let building = building {
                readings = MeterManager.shared.getReadings(forBuilding: building)
            } else {
                readings = MeterManager.shared.allReadings
            }
        case 2: // Floor
            if let floor = floor {
                readings = MeterManager.shared.getReadings(forFloor: floor)
            } else {
                readings = MeterManager.shared.allReadings
            }
        case 3: // Meter
            if let meter = meter {
                readings = MeterManager.shared.getReadings(forMeter: meter)
            } else {
                readings = MeterManager.shared.allReadings
            }
        default:
            break
        }
        
        tableView.reloadData()
        print("Applied filters, showing \(self.readings.count) readings")
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        updateVisibleFilters()
        applyFilters()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension PreviousReadingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return readings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingCell", for: indexPath)
        let reading = readings[indexPath.row]
        
        cell.textLabel?.text = "\(reading.meter.name): \(reading.formattedValue) on \(reading.formattedDate)"
        
        return cell
    }
}

// MARK: - UIPickerViewDataSource & Delegate
extension PreviousReadingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == datePickerView {
            return dates.count + 1 // +1 for "All"
        } else if pickerView == buildingPickerView {
            return buildings.count + 1
        } else if pickerView == floorPickerView {
            return floors.count + 1
        } else if pickerView == meterPickerView {
            return meters.count + 1
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "All"
        }
        
        if pickerView == datePickerView {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: dates[row - 1])
        } else if pickerView == buildingPickerView {
            return buildings[row - 1].name
        } else if pickerView == floorPickerView {
            return "Floor \(floors[row - 1].number)"
        } else if pickerView == meterPickerView {
            return meters[row - 1].name
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == datePickerView {
            date = row == 0 ? nil : dates[row - 1]
            dateTextField.text = row == 0 ? "All" : self.pickerView(pickerView, titleForRow: row, forComponent: component)
        } else if pickerView == buildingPickerView {
            building = row == 0 ? nil : buildings[row - 1]
            buildingTextField.text = row == 0 ? "All" : building?.name
            floors = building?.buildingFloors ?? []
            floor = nil
        } else if pickerView == floorPickerView {
            floor = row == 0 ? nil : floors[row - 1]
            floorTextField.text = row == 0 ? "All" : "Floor \(floor?.number ?? 0)"
            meters = floor?.floorMeters ?? []
            meter = nil
        } else if pickerView == meterPickerView {
            meter = row == 0 ? nil : meters[row - 1]
            meterTextField.text = row == 0 ? "All" : meter?.name
        }
        
        view.endEditing(true)
        applyFilters()
    }
}
