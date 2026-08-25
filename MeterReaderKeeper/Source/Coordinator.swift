//
//  Coordinator.swift
//  MeterReaderKeeper
//
//  Created by Code Modernization on 8/25/26.
//

import UIKit

/// Base protocol for all coordinators
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

/// Main app coordinator
class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        showHome()
    }
    
    // MARK: - Navigation
    
    func showHome() {
        let homeVC = HomeViewController()
        homeVC.coordinator = self
        homeVC.title = "Meter Reader"
        navigationController.setViewControllers([homeVC], animated: false)
    }
    
    func showPreviousReadings() {
        let previousReadingsVC = PreviousReadingsViewController()
        previousReadingsVC.coordinator = self
        previousReadingsVC.title = "Previous Readings"
        navigationController.pushViewController(previousReadingsVC, animated: true)
    }
    
    func showManagement() {
        let managementVC = ManagementTableViewController()
        managementVC.coordinator = self
        managementVC.title = "Manage Buildings"
        navigationController.pushViewController(managementVC, animated: true)
    }
    
    func showReadings(for building: Building) {
        let readingsVC = ReadingsMainViewController()
        readingsVC.coordinator = self
        readingsVC.building = building
        readingsVC.title = building.name
        navigationController.pushViewController(readingsVC, animated: true)
    }
    
    func showBuildingDetails(building: Building? = nil) {
        let buildingVC = AddEditBuildingViewController()
        buildingVC.coordinator = self
        buildingVC.building = building
        buildingVC.title = building == nil ? "Add Building" : "Edit Building"
        navigationController.pushViewController(buildingVC, animated: true)
    }
    
    func showFloorDetails(floor: Floor? = nil) {
        let floorVC = AddEditFloorViewController()
        floorVC.coordinator = self
        floorVC.floor = floor
        floorVC.title = floor == nil ? "Add Floor" : "Edit Floor"
        navigationController.pushViewController(floorVC, animated: true)
    }
    
    func showMeterDetails(meter: Meter? = nil) {
        let meterVC = AddEditMeterViewController()
        meterVC.coordinator = self
        meterVC.meter = meter
        meterVC.title = meter == nil ? "Add Meter" : "Edit Meter"
        navigationController.pushViewController(meterVC, animated: true)
    }
    
    func showAddReading(for meter: Meter) {
        let readingVC = AddEditReadingViewController()
        readingVC.coordinator = self
        readingVC.meter = meter
        readingVC.title = "Add Reading"
        navigationController.pushViewController(readingVC, animated: true)
    }
    
    func showEditReading(_ reading: Reading, for meter: Meter) {
        let readingVC = AddEditReadingViewController()
        readingVC.coordinator = self
        readingVC.meter = meter
        readingVC.reading = reading
        readingVC.title = "Edit Reading"
        navigationController.pushViewController(readingVC, animated: true)
    }
}
