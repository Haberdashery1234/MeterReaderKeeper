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
    var navigationController: UINavigationController { get set }
    var childCoordinators: [Coordinator] { get set }
    
    func start()
}

extension Coordinator {
    /// Add a child coordinator
    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    /// Remove a child coordinator
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
    let repository: MeterRepositoryProtocol
    
    init(navigationController: UINavigationController, repository: MeterRepositoryProtocol) {
        self.navigationController = navigationController
        self.repository = repository
    }
    
    func start() {
        showHome()
    }
    
    // MARK: - Navigation
    
    func showHome() {
        let homeVC = HomeViewController()
        homeVC.coordinator = self
        homeVC.viewModel = HomeViewModel(repository: repository)
        homeVC.title = "Meter Reader"
        navigationController.setViewControllers([homeVC], animated: false)
    }
    
    func showPreviousReadings() {
        let previousReadingsVC = PreviousReadingsViewController()
        previousReadingsVC.coordinator = self
        previousReadingsVC.viewModel = PreviousReadingsViewModel(repository: repository)
        previousReadingsVC.title = "Previous Readings"
        navigationController.pushViewController(previousReadingsVC, animated: true)
    }
    
    func showManagement() {
        let managementVC = ManagementTableViewController()
        managementVC.coordinator = self
        managementVC.viewModel = ManagementViewModel(repository: repository)
        managementVC.title = "Manage Buildings"
        navigationController.pushViewController(managementVC, animated: true)
    }
    
    func showReadings(for building: MRKBuilding) {
        let readingsVC = ReadingsMainViewController()
        readingsVC.coordinator = self
        readingsVC.viewModel = ReadingsMainViewModel(repository: repository, building: building)
        readingsVC.title = building.name
        navigationController.pushViewController(readingsVC, animated: true)
    }
    
    func showBuildingDetails(building: MRKBuilding? = nil) {
        let buildingVC = AddEditBuildingViewController()
        buildingVC.coordinator = self
        buildingVC.viewModel = AddEditBuildingViewModel(repository: repository, building: building)
        buildingVC.title = building == nil ? "Add Building" : "Edit Building"
        navigationController.pushViewController(buildingVC, animated: true)
    }
    
    func showFloorDetails(floor: MRKFloor? = nil, building: MRKBuilding? = nil) {
        let floorVC = AddEditFloorViewController()
        floorVC.coordinator = self
        floorVC.viewModel = AddEditFloorViewModel(repository: repository, building: building, floor: floor)
        floorVC.title = floor == nil ? "Add Floor" : "Edit Floor"
        navigationController.pushViewController(floorVC, animated: true)
    }
    
    func showMeterDetails(meter: MRKMeter? = nil, floor: MRKFloor? = nil, building: MRKBuilding? = nil) {
        let meterVC = AddEditMeterViewController()
        meterVC.coordinator = self
        meterVC.viewModel = AddEditMeterViewModel(repository: repository, building: building, floor: floor, meter: meter)
        meterVC.title = meter == nil ? "Add Meter" : "Edit Meter"
        navigationController.pushViewController(meterVC, animated: true)
    }
    
    func showAddReading(for meter: MRKMeter, floor: MRKFloor, building: MRKBuilding) {
        let readingVC = AddEditReadingViewController()
        readingVC.coordinator = self
        readingVC.viewModel = AddEditReadingViewModel(repository: repository, meter: meter, floor: floor, building: building, reading: nil)
        readingVC.title = "Add Reading"
        navigationController.pushViewController(readingVC, animated: true)
    }
    
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
    /// the Add/Edit Meter form, not this screen — Christian asked for this
    /// as "a meter details screen" reached by tapping a row on Previous
    /// Readings (2026-08-28).
    func showMeterHistory(for meter: MRKMeter, floor: MRKFloor, building: MRKBuilding) {
        let meterHistoryVC = MeterHistoryViewController()
        meterHistoryVC.coordinator = self
        meterHistoryVC.viewModel = MeterHistoryViewModel(repository: repository, meter: meter, floor: floor, building: building)
        meterHistoryVC.title = meter.name
        navigationController.pushViewController(meterHistoryVC, animated: true)
    }
}
