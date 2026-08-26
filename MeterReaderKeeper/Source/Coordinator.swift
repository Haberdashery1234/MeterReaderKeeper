//
//  Coordinator.swift
//  MeterReaderKeeper
//
//  Created by Code Modernization on 8/25/26.
//  Updated by Repository Refactor on 8/26/26.
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
        homeVC.repository = repository
        homeVC.title = "Meter Reader"
        navigationController.setViewControllers([homeVC], animated: false)
    }
    
    func showPreviousReadings() {
        let previousReadingsVC = PreviousReadingsViewController()
        previousReadingsVC.coordinator = self
        previousReadingsVC.repository = repository
        previousReadingsVC.title = "Previous Readings"
        navigationController.pushViewController(previousReadingsVC, animated: true)
    }
    
    func showManagement() {
        let managementVC = ManagementTableViewController()
        managementVC.coordinator = self
        managementVC.repository = repository
        managementVC.title = "Manage Buildings"
        navigationController.pushViewController(managementVC, animated: true)
    }
    
    func showReadings(for building: MRKBuilding) {
        let readingsVC = ReadingsMainViewController()
        readingsVC.coordinator = self
        readingsVC.repository = repository
        readingsVC.building = building
        readingsVC.title = building.name
        navigationController.pushViewController(readingsVC, animated: true)
    }
    
    func showBuildingDetails(building: MRKBuilding? = nil) {
        let buildingVC = AddEditBuildingViewController()
        buildingVC.coordinator = self
        buildingVC.repository = repository
        buildingVC.building = building
        buildingVC.title = building == nil ? "Add Building" : "Edit Building"
        navigationController.pushViewController(buildingVC, animated: true)
    }
    
    func showFloorDetails(floor: MRKFloor? = nil, building: MRKBuilding? = nil) {
        let floorVC = AddEditFloorViewController()
        floorVC.coordinator = self
        floorVC.repository = repository
        floorVC.floor = floor
        floorVC.building = building
        floorVC.title = floor == nil ? "Add Floor" : "Edit Floor"
        navigationController.pushViewController(floorVC, animated: true)
    }
    
    func showMeterDetails(meter: MRKMeter? = nil, floor: MRKFloor? = nil, building: MRKBuilding? = nil) {
        let meterVC = AddEditMeterViewController()
        meterVC.coordinator = self
        meterVC.repository = repository
        meterVC.meter = meter
        meterVC.floor = floor
        meterVC.building = building
        meterVC.title = meter == nil ? "Add Meter" : "Edit Meter"
        navigationController.pushViewController(meterVC, animated: true)
    }
    
    func showAddReading(for meter: MRKMeter, floor: MRKFloor, building: MRKBuilding) {
        let readingVC = AddEditReadingViewController()
        readingVC.coordinator = self
        readingVC.repository = repository
        readingVC.meter = meter
        readingVC.floor = floor
        readingVC.building = building
        readingVC.title = "Add Reading"
        navigationController.pushViewController(readingVC, animated: true)
    }
    
    func showEditReading(_ reading: MRKReading, for meter: MRKMeter, floor: MRKFloor, building: MRKBuilding) {
        let readingVC = AddEditReadingViewController()
        readingVC.coordinator = self
        readingVC.repository = repository
        readingVC.meter = meter
        readingVC.floor = floor
        readingVC.building = building
        readingVC.reading = reading
        readingVC.title = "Edit Reading"
        navigationController.pushViewController(readingVC, animated: true)
    }
}
