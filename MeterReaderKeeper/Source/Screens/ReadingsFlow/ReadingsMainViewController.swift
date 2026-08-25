//
//  ReadingsMainViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class ReadingsMainViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var building: Building? {
        didSet {
            guard let building = building else { return }
            floors = building.buildingFloors
            
            // Collect all meters for QR scanning
            allBuildingMeters = []
            for floor in floors {
                allBuildingMeters.append(contentsOf: floor.floorMeters)
            }
            
            // Set initial floor
            if let firstFloor = floors.first {
                floor = firstFloor
            }
        }
    }
    
    private var floors = [Floor]()
    private var floor: Floor? {
        didSet {
            guard let floor = floor else { return }
            floorTextField.text = "Floor \(floor.number)"
            meters = MeterManager.shared.getMeters(forFloor: floor)
        }
    }
    
    private var allBuildingMeters = [Meter]()
    private var meters = [Meter]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ReadingMeterTableViewCell.self, forCellReuseIdentifier: "ReadingMeterCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let floorLabel: UILabel = {
        let label = UILabel()
        label.text = "Floor:"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var floorTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Select floor"
        textField.borderStyle = .roundedRect
        textField.inputView = floorPickerView
        textField.tintColor = .clear // Hide cursor
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var floorPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    private let floorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Map overlay
    private lazy var mapContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let mapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var closeMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(closeMapTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh data
        if let building = building {
            floors = building.buildingFloors
            tableView.reloadData()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(floorStackView)
        floorStackView.addArrangedSubview(floorLabel)
        floorStackView.addArrangedSubview(floorTextField)
        
        view.addSubview(tableView)
        
        // Map overlay
        view.addSubview(mapContainerView)
        mapContainerView.addSubview(mapImageView)
        mapContainerView.addSubview(closeMapButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Floor Stack
            floorStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            floorStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            floorStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            
            floorTextField.widthAnchor.constraint(equalToConstant: 150),
            floorTextField.heightAnchor.constraint(equalToConstant: 36),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: floorStackView.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Map Container
            mapContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            mapContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Map ImageView
            mapImageView.centerXAnchor.constraint(equalTo: mapContainerView.centerXAnchor),
            mapImageView.centerYAnchor.constraint(equalTo: mapContainerView.centerYAnchor),
            mapImageView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor, constant: 20),
            mapImageView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor, constant: -20),
            mapImageView.topAnchor.constraint(greaterThanOrEqualTo: mapContainerView.safeAreaLayoutGuide.topAnchor, constant: 60),
            mapImageView.bottomAnchor.constraint(lessThanOrEqualTo: closeMapButton.topAnchor, constant: -20),
            
            // Close Button
            closeMapButton.bottomAnchor.constraint(equalTo: mapContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            closeMapButton.centerXAnchor.constraint(equalTo: mapContainerView.centerXAnchor),
            closeMapButton.widthAnchor.constraint(equalToConstant: 120),
            closeMapButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    private func setupNavigationBar() {
        // QR Scan button
        let scanButton = UIBarButtonItem(
            image: UIImage(systemName: "qrcode.viewfinder"),
            style: .plain,
            target: self,
            action: #selector(scanQRCodeTapped)
        )
        
        // Map button
        let mapButton = UIBarButtonItem(
            image: UIImage(systemName: "map"),
            style: .plain,
            target: self,
            action: #selector(mapButtonTapped)
        )
        
        // Send button
        let sendButton = UIBarButtonItem(
            image: UIImage(systemName: "envelope"),
            style: .plain,
            target: self,
            action: #selector(sendButtonTapped)
        )
        
        navigationItem.rightBarButtonItems = [sendButton, scanButton, mapButton]
    }
    
    private func loadData() {
        guard let building = building else {
            print("No building set for ReadingsMainViewController")
            return
        }
        
        floors = building.buildingFloors
        if let firstFloor = floors.first {
            floor = firstFloor
        }
        
        print("Loaded \(self.floors.count) floors with \(self.meters.count) meters")
    }
    
    // MARK: - Actions
    @objc private func sendButtonTapped() {
        guard let building = building else {
            print("Building is nil when trying to send CSV")
            return
        }
        
        guard let csvData = MeterManager.shared.getCSVData(forBuilding: building) else {
            showAlert(title: "Export Failed", message: "Failed to generate CSV data.")
            return
        }
        
        EmailService.shared.sendCSV(
            from: self,
            csvData: csvData,
            buildingName: building.name
        ) { [weak self] result, error in
            if result == .failed {
                print("Email send failed: \(String(describing: error))")
            } else {
                print("CSV sent successfully")
            }
        }
    }
    
    @objc private func scanQRCodeTapped() {
        // TODO: Implement QR scanner with coordinator
        // For now, show alert
        showAlert(
            title: "QR Scanner", 
            message: "QR scanner will be available in a future update. Please select meters from the list below."
        )
    }
    
    @objc private func mapButtonTapped() {
        guard let floor = floor else { return }
        
        let floorMapData = floor.map
        
        if floorMapData.count > 0, let floorMapImage = UIImage(data: floorMapData) {
            mapImageView.image = floorMapImage
            
            UIView.animate(withDuration: Constants.UIValues.animationDuration) {
                self.mapContainerView.isHidden = false
            }
            
            print("Showing map for floor \(floor.number)")
        } else {
            showAlert(title: "No Map", message: "No map available for this floor")
        }
    }
    
    @objc private func closeMapTapped() {
        UIView.animate(withDuration: Constants.UIValues.animationDuration) {
            self.mapContainerView.isHidden = true
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ReadingsMainViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingMeterCell", for: indexPath) as! ReadingMeterTableViewCell
        let meter = meters[indexPath.row]
        cell.setup(withMeter: meter)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ReadingsMainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let meter = meters[indexPath.row]
        
        // Check if there's already a reading for today
        let meterReadings = meter.meterReadings
        let date = Calendar.current.startOfDay(for: Date())
        let todaysReadings = meterReadings.filter { $0.date == date }
        
        if let existingReading = todaysReadings.first {
            coordinator?.showEditReading(existingReading, for: meter)
        } else {
            coordinator?.showAddReading(for: meter)
        }
    }
}

// MARK: - UIPickerViewDelegate & DataSource
extension ReadingsMainViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return floors.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "Floor \(floors[row].number)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        floor = floors[row]
        view.endEditing(true)
        print("Selected floor: \(self.floors[row].number)")
    }
}
