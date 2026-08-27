//
//  HomeViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//  Converted to async/await + @MainActor on 8/27/26 (see "Proper
//  concurrency" migration note in project history).
//

import Foundation

/// Business logic and repository access for the Home screen.
///
/// The view controller keeps ownership of all UI presentation — alerts,
/// the building-picker action sheet, the export-progress spinner, and
/// handing off to `EmailService` (which itself presents `MFMailComposeViewController`,
/// a UIKit type) — since none of that is meaningfully testable business logic.
/// This type owns deciding *what* to do and talking to the repository.
///
/// `@MainActor`: every stored/computed property here is meant to be read
/// from UIKit, so the whole type is pinned to the main actor. `init` is
/// `nonisolated` so `AppCoordinator` (a plain, non-actor-isolated type) can
/// keep constructing this synchronously from its `showXxx` methods, exactly
/// as before.
@MainActor
final class HomeViewModel {

    /// What should happen when "Take Readings" is tapped.
    enum TakeReadingsOutcome {
        case noBuildings
        case singleBuilding(MRKBuilding)
        case chooseBuilding([MRKBuilding])
    }

    #if DEBUG || TESTING
    /// Which seeding operation actually ran, so the View can show the
    /// matching success message.
    enum SeedOutcome {
        case seededInitialData
        case addedMoreReadings
    }
    #endif

    private let repository: MeterRepositoryProtocol

    #if DEBUG || TESTING
    private let dataSeeder: DataSeeder
    #endif

    nonisolated init(repository: MeterRepositoryProtocol) {
        self.repository = repository
        #if DEBUG || TESTING
        self.dataSeeder = DataSeeder(repository: repository)
        #endif
    }

    func takeReadingsOutcome() async -> TakeReadingsOutcome {
        let buildings = (try? await repository.getBuildings()) ?? []

        if buildings.isEmpty {
            return .noBuildings
        } else if buildings.count == 1 {
            return .singleBuilding(buildings[0])
        } else {
            return .chooseBuilding(buildings)
        }
    }

    /// Exports all data to a plist. `repository` is a `ModelActor`, so this
    /// call already suspends onto the repository's own executor while the
    /// work happens and hops back to the main actor when it's done — no
    /// manual `DispatchQueue` wrapping needed here anymore (this used to be
    /// `exportData(completion:)`, backgrounded by hand).
    func exportData() async throws -> Data {
        try await repository.exportAllDataToPlist()
    }

    #if DEBUG || TESTING
    /// Seeds initial data if there are no buildings yet, otherwise adds
    /// more readings to what already exists. As with `exportData()`, the
    /// thousands of individual repository calls this can involve run on the
    /// repository's own actor, not here, so no manual backgrounding is
    /// needed (this used to be `seedData(completion:)`).
    func seedData() async throws -> SeedOutcome {
        let buildingCount = (try? await repository.getBuildings())?.count ?? 0

        if buildingCount == 0 {
            try await dataSeeder.seedData()
            print("Seeded initial test data")
            return .seededInitialData
        } else {
            try await dataSeeder.seedMoreReadings()
            print("Seeded additional readings")
            return .addedMoreReadings
        }
    }
    #endif
}
