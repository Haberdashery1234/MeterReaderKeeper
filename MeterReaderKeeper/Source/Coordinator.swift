//
//  Coordinator.swift
//  MeterReaderKeeper
//
//  Created by Code Modernization on 8/25/26.
//  Updated by Repository Refactor on 8/26/26.
//  Updated to construct and inject ViewModels on 8/26/26.
//

import UIKit

/// Base protocol for all coordinators.
///
/// Marked `@MainActor`: every conformer owns a `UINavigationController` and
/// pushes/sets view controllers on it, which is inherently main-thread-only
/// UIKit work — there's no legitimate background-work case for a
/// coordinator the way there is for, say, `MeterRepositoryProtocol`. Since
/// `AppCoordinator` (the only conformer) is already `@MainActor` itself,
/// declaring that isolation on the protocol directly means the conformance
/// no longer "crosses into actor-isolated code" — it matches it exactly, so
/// no `@preconcurrency` escape hatch is needed here the way one was for
/// `SwiftDataMeterRepository`'s conformance to `MeterRepositoryProtocol`.
@MainActor
protocol Coordinator: AnyObject {
    /// The navigation controller this coordinator pushes/sets view
    /// controllers on.
    var navigationController: UINavigationController { get set }
    /// Coordinators started by this one, retained so they aren't
    /// deallocated mid-flow.
    var childCoordinators: [Coordinator] { get set }

    /// Begins this coordinator's flow — typically by setting or pushing its
    /// first view controller.
    func start()
}

extension Coordinator {
    /// Retains `coordinator` in `childCoordinators` so it stays alive for
    /// the duration of the flow it's driving.
    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    /// Removes `coordinator` from `childCoordinators`, allowing it to be
    /// deallocated once its flow has finished.
    func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
}

/// Main app coordinator.
///
/// Views no longer hold the repository directly (see the `MeterRepositoryProtocol`
/// docs) — each `showXxx` method here constructs the screen's ViewModel,
/// handing it the repository and whatever navigation context (a building,
/// floor, meter, or reading) the coordinator already has, and injects it
/// into the view controller.
@MainActor
class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    /// The app's single repository instance, handed to every ViewModel this
    /// coordinator constructs.
    let repository: MeterRepositoryProtocol

    /// Creates the app coordinator.
    ///
    /// - Parameters:
    ///   - navigationController: The navigation controller to drive.
    ///   - repository: The repository instance to inject into every ViewModel.
    init(navigationController: UINavigationController, repository: MeterRepositoryProtocol) {
        self.navigationController = navigationController
        self.repository = repository
    }

    /// Starts the app on the Home screen.
    func start() {
        showHome()
    }

    // MARK: - Navigation

    /// Sets Home as the navigation stack's sole root screen.
    func showHome() {
        let homeVC = HomeViewController()
        homeVC.coordinator = self
        homeVC.viewModel = HomeViewModel(repository: repository)
        navigationController.setViewControllers([homeVC], animated: false)
    }

    /// Pushes the Previous Readings screen.
    func showPreviousReadings() {
        let previousReadingsVC = PreviousReadingsViewController()
        previousReadingsVC.coordinator = self
        previousReadingsVC.viewModel = PreviousReadingsViewModel(repository: repository)
        previousReadingsVC.title = "Previous Readings"
        navigationController.pushViewController(previousReadingsVC, animated: true)
    }

    /// Pushes the Management screen (Buildings/Floors/Meters, sectioned by building).
    func showManagement() {
        let managementVC = ManagementTableViewController()
        managementVC.coordinator = self
        managementVC.viewModel = ManagementViewModel(repository: repository)
        managementVC.title = "Manage Buildings"
        navigationController.pushViewController(managementVC, animated: true)
    }

    /// Pushes the readings-entry flow for one building.
    func showReadings(for building: MRKBuilding) {
        let readingsVC = ReadingsMainViewController()
        readingsVC.coordinator = self
        readingsVC.viewModel = ReadingsMainViewModel(repository: repository, building: building)
        readingsVC.title = building.name
        navigationController.pushViewController(readingsVC, animated: true)
    }

    /// Pushes the Add/Edit Building form.
    ///
    /// - Parameter building: The building to edit, or `nil` to add a new one.
    func showBuildingDetails(building: MRKBuilding? = nil) {
        let buildingVC = AddEditBuildingViewController()
        buildingVC.coordinator = self
        buildingVC.viewModel = AddEditBuildingViewModel(repository: repository, building: building)
        buildingVC.title = building == nil ? "Add Building" : "Edit Building"
        navigationController.pushViewController(buildingVC, animated: true)
    }

    /// Pushes the Add/Edit Floor form (floor number and map image) — not to
    /// be confused with `showFloorMeters(floor:building:)` below, which
    /// lists a floor's meters. Reachable from Management (adding a floor
    /// isn't currently exposed here; only editing an existing one) and from
    /// `FloorMetersViewController`'s own Edit button.
    ///
    /// - Parameters:
    ///   - floor: The floor to edit, or `nil` to add a new one.
    ///   - building: The floor's building. Required when adding.
    func showFloorDetails(floor: MRKFloor? = nil, building: MRKBuilding? = nil) {
        let floorVC = AddEditFloorViewController()
        floorVC.coordinator = self
        floorVC.viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: floor)
        floorVC.title = floor == nil ? "Add Floor" : "Edit Floor"
        navigationController.pushViewController(floorVC, animated: true)
    }

    /// Lists one floor's meters — add/delete a meter, see each one's last
    /// reading date + value. Reached by tapping a Floor row in Management
    /// (2026-08-28). Named distinctly from `showFloorDetails`
    /// above, which is actually the Add/Edit Floor form (number + map
    /// image) — same naming split as `showMeterDetails` vs.
    /// `showMeterHistory`. `showFloorDetails` is still reachable from
    /// this screen via its Edit button.
    ///
    /// - Parameters:
    ///   - floor: The floor whose meters to list.
    ///   - building: The floor's building.
    func showFloorMeters(floor: MRKFloor, building: MRKBuilding) {
        let floorMetersVC = FloorMetersViewController()
        floorMetersVC.coordinator = self
        floorMetersVC.viewModel = FloorMetersViewModel(repository: repository, floor: floor, building: building)
        floorMetersVC.title = floor.displayName
        navigationController.pushViewController(floorMetersVC, animated: true)
    }
    
    /// Pushes the Add/Edit Meter form.
    ///
    /// - Parameters:
    ///   - meter: The meter to edit, or `nil` to add a new one.
    ///   - floor: The meter's floor. Required when adding; when provided,
    ///     also pre-selects the floor (used by `FloorMetersViewController`'s
    ///     Add button).
    ///   - building: The meter's building. Required when adding.
    func showMeterDetails(meter: MRKMeter? = nil, floor: MRKFloor? = nil, building: MRKBuilding? = nil) {
        let meterVC = AddEditMeterViewController()
        meterVC.coordinator = self
        meterVC.viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: meter)
        meterVC.title = meter == nil ? "Add Meter" : "Edit Meter"
        navigationController.pushViewController(meterVC, animated: true)
    }

    /// Pushes the Add Reading form for a meter.
    func showAddReading(for meter: MRKMeter, floor: MRKFloor, building: MRKBuilding) {
        let readingVC = AddEditReadingViewController()
        readingVC.coordinator = self
        readingVC.viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)
        readingVC.title = "Add Reading"
        navigationController.pushViewController(readingVC, animated: true)
    }

    /// Pushes the Edit Reading form for an existing reading.
    func showEditReading(_ reading: MRKReading, for meter: MRKMeter, floor: MRKFloor, building: MRKBuilding) {
        let readingVC = AddEditReadingViewController()
        readingVC.coordinator = self
        readingVC.viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: reading)
        readingVC.title = "Edit Reading"
        navigationController.pushViewController(readingVC, animated: true)
    }

    /// Read-only meter detail screen: Building, Floor, most recent reading,
    /// and a chart of every reading over time. Named `showMeterHistory`
    /// rather than `showMeterDetails` to avoid colliding with the existing
    /// `showMeterDetails(meter:floor:building:)` above, which is actually
    /// the Add/Edit Meter form, not this screen. Reached by tapping a row
    /// on Previous Readings (2026-08-28).
    func showMeterHistory(for meter: MRKMeter, floor: MRKFloor, building: MRKBuilding) {
        let meterHistoryVC = MeterHistoryViewController()
        meterHistoryVC.coordinator = self
        meterHistoryVC.viewModel = MeterHistoryViewModel(repository: repository, meter: meter, floor: floor, building: building)
        meterHistoryVC.title = meter.name
        navigationController.pushViewController(meterHistoryVC, animated: true)
    }

    /// Pushes the QR scanner screen. `delegate` (typically the screen that
    /// triggered the scan) is handed the scanned code and resolves it to a
    /// meter — this coordinator only knows how to present the screen, not
    /// what to do with a scan result.
    func showQrScanner(delegate: QRScannerDelegate) {
        let scannerVC = QrScannerViewController()
        scannerVC.scannerDelegate = delegate
        scannerVC.title = "Scan QR Code"
        navigationController.pushViewController(scannerVC, animated: true)
    }
}
