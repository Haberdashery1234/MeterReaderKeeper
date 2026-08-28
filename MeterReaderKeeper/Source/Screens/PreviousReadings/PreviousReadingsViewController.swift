//
//  PreviousReadingsViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//  Thinned to use PreviousReadingsViewModel on 8/26/26.
//

import UIKit

class PreviousReadingsViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var viewModel: PreviousReadingsViewModel!
    
    private var selectedSegment: PreviousReadingsViewModel.FilterSegment {
        PreviousReadingsViewModel.FilterSegment(rawValue: segmentedControl.selectedSegmentIndex) ?? .date
    }
    
    // MARK: - UI Components
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Date", "Building", "Floor", "Meter"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.accessibilityIdentifier = "PreviousReadings.segmentedControl"
        return control
    }()
    
    // Filter TextFields
    private lazy var dateTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "All"
        AppStyle.stylePaddedTextField(textField)
        textField.inputView = datePickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "PreviousReadings.dateTextField"
        return textField
    }()
    
    private lazy var buildingTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "All"
        AppStyle.stylePaddedTextField(textField)
        textField.inputView = buildingPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "PreviousReadings.buildingTextField"
        return textField
    }()
    
    private lazy var floorTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "All"
        AppStyle.stylePaddedTextField(textField)
        textField.inputView = floorPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "PreviousReadings.floorTextField"
        return textField
    }()
    
    private lazy var meterTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "All"
        AppStyle.stylePaddedTextField(textField)
        textField.inputView = meterPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "PreviousReadings.meterTextField"
        return textField
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PreviousReadingTableViewCell.self, forCellReuseIdentifier: "ReadingCell")
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "PreviousReadings.tableView"
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
        Task { @MainActor in
            await viewModel.loadData()
            viewModel.applyFilters(segment: selectedSegment)
            tableView.reloadData()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
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
            
            // Filter TextFields — only one is ever visible at a time (see
            // updateVisibleFilters), so all four share the same position
            // instead of being chained top-to-bottom. Chaining them meant
            // the three hidden fields still reserved their layout space
            // (`isHidden` hides a view but doesn't remove it from Auto
            // Layout), leaving a large empty gap above the results.
            dateTextField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            dateTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dateTextField.heightAnchor.constraint(equalToConstant: 44),
            
            buildingTextField.topAnchor.constraint(equalTo: dateTextField.topAnchor),
            buildingTextField.leadingAnchor.constraint(equalTo: dateTextField.leadingAnchor),
            buildingTextField.trailingAnchor.constraint(equalTo: dateTextField.trailingAnchor),
            buildingTextField.heightAnchor.constraint(equalTo: dateTextField.heightAnchor),
            
            floorTextField.topAnchor.constraint(equalTo: dateTextField.topAnchor),
            floorTextField.leadingAnchor.constraint(equalTo: dateTextField.leadingAnchor),
            floorTextField.trailingAnchor.constraint(equalTo: dateTextField.trailingAnchor),
            floorTextField.heightAnchor.constraint(equalTo: dateTextField.heightAnchor),
            
            meterTextField.topAnchor.constraint(equalTo: dateTextField.topAnchor),
            meterTextField.leadingAnchor.constraint(equalTo: dateTextField.leadingAnchor),
            meterTextField.trailingAnchor.constraint(equalTo: dateTextField.trailingAnchor),
            meterTextField.heightAnchor.constraint(equalTo: dateTextField.heightAnchor),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: dateTextField.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func updateVisibleFilters() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        dateTextField.isHidden = selectedIndex != 0
        buildingTextField.isHidden = selectedIndex != 1
        floorTextField.isHidden = selectedIndex != 2
        meterTextField.isHidden = selectedIndex != 3
    }
    
    private func applyFilters() {
        viewModel.applyFilters(segment: selectedSegment)
        tableView.reloadData()
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
        return viewModel.meterSummaries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingCell", for: indexPath) as! PreviousReadingTableViewCell
        cell.setup(summary: viewModel.meterSummaries[indexPath.row])
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let summary = viewModel.meterSummaries[indexPath.row]
        coordinator?.showMeterHistory(for: summary.meter, floor: summary.floor, building: summary.building)
    }
}

// MARK: - UIPickerViewDataSource & Delegate
extension PreviousReadingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == datePickerView {
            return viewModel.dates.count + 1 // +1 for "All"
        } else if pickerView == buildingPickerView {
            return viewModel.buildings.count + 1
        } else if pickerView == floorPickerView {
            return viewModel.floors.count + 1
        } else if pickerView == meterPickerView {
            return viewModel.meters.count + 1
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
            return formatter.string(from: viewModel.dates[row - 1])
        } else if pickerView == buildingPickerView {
            return viewModel.buildings[row - 1].name
        } else if pickerView == floorPickerView {
            return "Floor \(viewModel.floors[row - 1].number)"
        } else if pickerView == meterPickerView {
            return viewModel.meters[row - 1].name
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == datePickerView {
            viewModel.selectDate(at: row)
            dateTextField.text = row == 0 ? "All" : self.pickerView(pickerView, titleForRow: row, forComponent: component)
        } else if pickerView == buildingPickerView {
            viewModel.selectBuilding(at: row)
            buildingTextField.text = row == 0 ? "All" : viewModel.selectedBuilding?.name
            floorTextField.text = "All"
            floorPickerView.reloadAllComponents()
            meterTextField.text = "All"
            meterPickerView.reloadAllComponents()
        } else if pickerView == floorPickerView {
            viewModel.selectFloor(at: row)
            floorTextField.text = row == 0 ? "All" : "Floor \(viewModel.selectedFloor?.number ?? 0)"
            meterTextField.text = "All"
            meterPickerView.reloadAllComponents()
        } else if pickerView == meterPickerView {
            viewModel.selectMeter(at: row)
            meterTextField.text = row == 0 ? "All" : viewModel.selectedMeter?.name
        }
        
        view.endEditing(true)
        applyFilters()
    }
}
