//
//  ReadingsMainViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//  Thinned to use ReadingsMainViewModel on 8/26/26.
//

import UIKit

private enum ReadingsMainSection {
    case main
}

/// The "take readings" screen for one building: a floor picker, the
/// meter list for the selected floor (tapping a row adds or edits today's
/// reading), a floor-map overlay, and a CSV-export button. Owns all UI
/// presentation; `ReadingsMainViewModel` owns the data behind it.
class ReadingsMainViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var viewModel: ReadingsMainViewModel!

    /// Whether `viewWillAppear` has already run once. The first appearance
    /// renders straight from the ViewModel's own just-loaded init data, so
    /// the refetch below is redundant there — and, since it's unawaited,
    /// racing it against that first render risks a `reloadData()` landing
    /// under a not-yet-registered tap. Only appearances after this one
    /// (returning from Add/Edit Reading, say) need the refetch.
    private var hasAppearedBefore = false
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.register(ReadingMeterTableViewCell.self, forCellReuseIdentifier: "ReadingMeterCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "ReadingsMain.tableView"
        return tableView
    }()

    private lazy var dataSource: UITableViewDiffableDataSource<ReadingsMainSection, MRKMeter> = {
        let dataSource = UITableViewDiffableDataSource<ReadingsMainSection, MRKMeter>(tableView: tableView) { [weak self] tableView, indexPath, meter in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingMeterCell", for: indexPath) as! ReadingMeterTableViewCell
            cell.setup(meter: meter, floorNumber: self?.viewModel.floor?.number ?? 0)
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        return dataSource
    }()

    private let floorLabel: UILabel = {
        let label = UILabel()
        label.text = "Floor:"
        AppStyle.applyScaledFont(to: label, size: 14, weight: .medium, relativeTo: .footnote)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var floorTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Select floor"
        AppStyle.stylePaddedTextField(textField, horizontalInset: 12)
        textField.inputView = floorPickerView
        textField.tintColor = .clear // Hide cursor
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "ReadingsMain.floorTextField"
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
        AppStyle.styleAsPrimaryButton(button)
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
        refreshFloorDisplay()
    }
    
    /// Re-fetches the building on every appearance after the first, so a
    /// reading or meter changed elsewhere is reflected. Skipped on the
    /// first appearance — see `hasAppearedBefore`.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard hasAppearedBefore else {
            hasAppearedBefore = true
            return
        }
        Task { @MainActor in
            await viewModel.refreshBuilding()
            refreshFloorDisplay()
        }
    }

    // MARK: - Setup

    /// Adds the floor picker, table view, and map overlay to the view hierarchy.
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(floorStackView)
        floorStackView.addArrangedSubview(floorLabel)
        floorStackView.addArrangedSubview(floorTextField)
        
        view.addSubview(tableView)
        // Forces `dataSource` to initialize now (assigning itself as the
        // table's data source) rather than whenever it's first touched.
        _ = dataSource

        // Map overlay
        view.addSubview(mapContainerView)
        mapContainerView.addSubview(mapImageView)
        mapContainerView.addSubview(closeMapButton)
    }
    
    /// Activates the floor picker / table view / map overlay Auto Layout constraints.
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
    
    /// Adds the nav-bar Send/Scan/Map buttons.
    private func setupNavigationBar() {
        let scanButton = UIBarButtonItem(
            image: UIImage(systemName: "qrcode.viewfinder"),
            style: .plain,
            target: self,
            action: #selector(scanQRCodeTapped)
        )
        scanButton.accessibilityIdentifier = "ReadingsMain.scanButton"

        let mapButton = UIBarButtonItem(
            image: UIImage(systemName: "map"),
            style: .plain,
            target: self,
            action: #selector(mapButtonTapped)
        )
        mapButton.accessibilityIdentifier = "ReadingsMain.mapButton"

        let sendButton = UIBarButtonItem(
            image: UIImage(systemName: "envelope"),
            style: .plain,
            target: self,
            action: #selector(sendButtonTapped)
        )
        sendButton.accessibilityIdentifier = "ReadingsMain.sendButton"

        navigationItem.rightBarButtonItems = [sendButton, scanButton, mapButton]
    }

    /// Updates the floor text field and reloads the meter list for the
    /// currently selected floor.
    private func refreshFloorDisplay() {
        floorTextField.text = viewModel.floor.map { "Floor \($0.number)" }
        var snapshot = NSDiffableDataSourceSnapshot<ReadingsMainSection, MRKMeter>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.meters, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Actions

    /// Emails a CSV of today's readings for this building via `EmailService`.
    @objc private func sendButtonTapped() {
        Task { @MainActor in
            do {
                let csvData = try await viewModel.getCSVData()
                EmailService.shared.sendCSV(
                    from: self,
                    csvData: csvData,
                    buildingName: viewModel.building.name
                ) { result, error in
                    if result == .failed {
                        print("Email send failed: \(String(describing: error))")
                    } else {
                        print("CSV sent successfully")
                    }
                }
            } catch {
                showAlert(title: "Export Failed", message: error.localizedDescription)
            }
        }
    }
    
    /// Pushes the QR scanner, with this view controller as its delegate —
    /// see the `QRScannerDelegate` conformance below for what happens with
    /// a scanned code.
    @objc private func scanQRCodeTapped() {
        coordinator?.showQrScanner(delegate: self)
    }

    /// Shows the selected floor's map image as a full-screen overlay, if one
    /// has been set.
    @objc private func mapButtonTapped() {
        guard let floor = viewModel.floor else { return }
        
        let floorMapData = floor.mapImageData
        
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
    
    /// Dismisses the map overlay.
    @objc private func closeMapTapped() {
        UIView.animate(withDuration: Constants.UIValues.animationDuration) {
            self.mapContainerView.isHidden = true
        }
    }

    /// Presents a simple single-button ("OK") alert.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate
extension ReadingsMainViewController: UITableViewDelegate {
    /// Opens Add or Edit Reading for the tapped meter, per
    /// `ReadingsMainViewModel.readingRoute(forMeterAt:)`. Uses `indexPath.row`
    /// (rather than `dataSource.itemIdentifier(for:)`) because
    /// `readingRoute(forMeterAt:)` looks the meter up by position in
    /// `viewModel.meters`, which the snapshot always mirrors exactly.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let route = viewModel.readingRoute(forMeterAt: indexPath.row) else { return }


        switch route {
        case .add(let meter, let floor, let building):
            coordinator?.showAddReading(for: meter, floor: floor, building: building)
        case .edit(let reading, let meter, let floor, let building):
            coordinator?.showEditReading(reading, for: meter, floor: floor, building: building)
        }
    }
}

// MARK: - QRScannerDelegate
extension ReadingsMainViewController: QRScannerDelegate {
    /// Resolves the scanned code against `viewModel`'s meters. On a single
    /// match, pops the scanner and navigates straight to Add/Edit Reading
    /// for it, updating the floor selector to match. On no match (or an
    /// ambiguous one), reports back through `errorCompletion` so the
    /// scanner can show an alert and keep scanning.
    func scannedCode(_ codeString: String, errorCompletion: @escaping (NSError?) -> ()) {
        switch viewModel.resolveScannedCode(codeString) {
        case .matched(let route, let floor):
            errorCompletion(nil)
            viewModel.selectFloor(matching: floor)
            refreshFloorDisplay()
            navigationController?.popViewController(animated: false)
            switch route {
            case .add(let meter, let floor, let building):
                coordinator?.showAddReading(for: meter, floor: floor, building: building)
            case .edit(let reading, let meter, let floor, let building):
                coordinator?.showEditReading(reading, for: meter, floor: floor, building: building)
            }
        case .unmatched(let count):
            let message = count == 0
                ? "No meter in this building matches that code."
                : "Multiple meters in this building match that code. Please select one from the list instead."
            errorCompletion(NSError(
                domain: "MeterReaderKeeper.QRScan",
                code: count,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        }
    }
}

// MARK: - UIPickerViewDelegate & DataSource
extension ReadingsMainViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.floors.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "Floor \(viewModel.floors[row].number)"
    }
    
    /// Selects the picked floor and refreshes the meter list for it.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.selectFloor(at: row)
        refreshFloorDisplay()
        view.endEditing(true)
    }
}
