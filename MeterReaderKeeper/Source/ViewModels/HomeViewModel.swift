//
//  HomeViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//

import Foundation
import os.log

/// Business logic and repository access for the Home screen.
///
/// The view controller keeps ownership of all UI presentation — alerts,
/// the building-picker action sheet, the export-progress spinner, and
/// handing off to `EmailService` (which itself presents `MFMailComposeViewController`,
/// a UIKit type) — since none of that is meaningfully testable business logic.
/// This type owns deciding *what* to do and talking to the repository.
final class HomeViewModel {

    /// What should happen when "Take Readings" is tapped.
    enum TakeReadingsOutcome {
        case noBuildings
        case singleBuilding(MRKBuilding)
        case chooseBuilding([MRKBuilding])
    }

    /// Which seeding operation actually ran, so the View can show the
    /// matching success message.
    enum SeedOutcome {
        case seededInitialData
        case addedMoreReadings
    }

    private let repository: MeterRepositoryProtocol
    private let dataSeeder: DataSeeder
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "HomeViewModel")

    init(repository: MeterRepositoryProtocol) {
        self.repository = repository
        self.dataSeeder = DataSeeder(repository: repository)
    }

    func takeReadingsOutcome() -> TakeReadingsOutcome {
        let buildings = (try? repository.getBuildings()) ?? []

        if buildings.isEmpty {
            return .noBuildings
        } else if buildings.count == 1 {
            return .singleBuilding(buildings[0])
        } else {
            return .chooseBuilding(buildings)
        }
    }

    /// Exports all data to a plist. Runs on a background queue and calls
    /// back on the main queue — matching the original view controller's
    /// threading — so the caller can drive a loading indicator and safely
    /// touch UIKit from the completion handler.
    func exportData(completion: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [repository] in
            do {
                let plistData = try repository.exportAllDataToPlist()
                DispatchQueue.main.async { completion(.success(plistData)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    /// Seeds initial data if there are no buildings yet, otherwise adds
    /// more readings to what already exists. Runs on a background queue and
    /// calls back on the main queue — matching `exportData(completion:)` —
    /// since seeding can mean thousands of individual repository calls,
    /// which would otherwise block the UI for a noticeable stretch of time.
    func seedData(completion: @escaping (Result<SeedOutcome, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [repository, dataSeeder, logger] in
            do {
                let buildingCount = (try? repository.getBuildings())?.count ?? 0

                if buildingCount == 0 {
                    try dataSeeder.seedData()
                    logger.info("Seeded initial test data")
                    DispatchQueue.main.async { completion(.success(.seededInitialData)) }
                } else {
                    try dataSeeder.seedMoreReadings()
                    logger.info("Seeded additional readings")
                    DispatchQueue.main.async { completion(.success(.addedMoreReadings)) }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}
