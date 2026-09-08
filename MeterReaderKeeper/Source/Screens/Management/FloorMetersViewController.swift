//
//  FloorMetersViewController.swift
//  MeterReaderKeeper
//
//  Created for the Floor Meters screen on 2026-08-28. Reached by tapping a
//  Floor row in Management.
//

import UIKit

/// Lists one floor's meters. Supports adding a meter to this floor
/// (reusing the existing Add Meter form, pre-selecting this floor) and
/// deleting one (swipe-to-delete with a confirmation, matching
/// AddEditMeterViewController's own "Delete Meter" alert wording). Each
/// row shows the meter's last reading date and value via the shared
/// `MeterTableViewCell`.
class FloorMetersViewController: UIViewController {

    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var viewModel: FloorMetersViewModel!

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MeterTableViewCell.self, forCellReuseIdentifier: "MeterCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "FloorMeters.tableView"
        return tableView
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No meters on this floor yet. Tap + to add one."
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.accessibilityIdentifier = "FloorMeters.emptyStateLabel"
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
    }

    /// Reloads this floor's meters each time the screen becomes visible,
    /// so an add/delete made elsewhere (or on a previous visit) is reflected.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { @MainActor in
            await viewModel.loadData()
            refreshUI()
        }
    }

    // MARK: - Setup

    /// Sets the nav title and adds the table view / empty-state label to
    /// the view hierarchy.
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = viewModel.floorDisplayName

        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
    }

    /// Activates the table view / empty-state label Auto Layout constraints.
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    /// Adds the nav-bar Add and Edit-floor buttons.
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addMeterTapped)
        )
        addButton.accessibilityIdentifier = "FloorMeters.addButton"

        // The floor's own fields (number, map image) still only live on
        // the Add/Edit Floor form — this screen replaced it as the
        // destination for tapping a Floor row in Management, so that
        // form needs a way back in or it'd be unreachable.
        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(editFloorTapped)
        )
        editButton.accessibilityIdentifier = "FloorMeters.editFloorButton"

        navigationItem.rightBarButtonItems = [addButton, editButton]
    }

    /// Reflects `viewModel`'s current meter list: reloads the table and
    /// toggles the empty-state label.
    private func refreshUI() {
        title = viewModel.floorDisplayName
        tableView.reloadData()
        emptyStateLabel.isHidden = viewModel.hasMeters
        tableView.isHidden = !viewModel.hasMeters
    }

    // MARK: - Actions

    /// Opens Add Meter with this floor pre-selected.
    @objc private func addMeterTapped() {
        coordinator?.showMeterDetails(meter: nil, floor: viewModel.floor, building: viewModel.building)
    }

    /// Opens the floor's own edit form (number, map image).
    @objc private func editFloorTapped() {
        coordinator?.showFloorDetails(floor: viewModel.floor, building: viewModel.building)
    }

    /// Presents a confirmation alert before deleting a meter (and its
    /// reading history), matching `AddEditMeterViewController`'s own
    /// "Delete Meter" alert wording.
    private func confirmDelete(of meter: MRKMeter) {
        let alert = UIAlertController(
            title: "Delete Meter",
            message: "Are you sure you want to delete '\(meter.name)'? This will also delete all readings for this meter.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                do {
                    try await self.viewModel.deleteMeter(meter)
                    self.refreshUI()
                } catch {
                    self.showAlert(title: "Delete Failed", message: error.localizedDescription)
                }
            }
        })
        present(alert, animated: true)
    }

    /// Presents a simple single-button ("OK") alert.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FloorMetersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.meters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MeterCell", for: indexPath) as! MeterTableViewCell
        let meter = viewModel.meters[indexPath.row]
        // Every row is already on this same floor (it's this screen's
        // title), so repeating "Floor N" on every row the way
        // Management's own (multi-floor) Meters segment does would be
        // redundant — show the meter's own description there instead,
        // when it has one, since that's more useful for telling meters
        // on the same floor apart.
        let subtitle = meter.meterDescription.isEmpty ? viewModel.floorDisplayName : meter.meterDescription
        cell.setup(meter: meter, locationString: subtitle)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        confirmDelete(of: viewModel.meters[indexPath.row])
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "Delete"
    }
}

// MARK: - UITableViewDelegate
extension FloorMetersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let meter = viewModel.meters[indexPath.row]
        coordinator?.showMeterDetails(meter: meter, floor: viewModel.floor, building: viewModel.building)
    }
}
