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
        /// No buildings exist yet — nothing to take readings for.
        case noBuildings
        /// Exactly one building exists, so its readings flow can open directly.
        case singleBuilding(MRKBuilding)
        /// More than one building exists — the user must pick one first.
        case chooseBuilding([MRKBuilding])
    }

    /// The data behind the Home screen's "At a Glance" stats row and
    /// "Needs Attention" list.
    struct HomeSummary {
        /// Total number of buildings.
        let buildingCount: Int
        /// Total number of meters across every building.
        let meterCount: Int
        /// Human-readable relative time of the most recent reading across
        /// every meter (e.g. "Today", "Yesterday", "6d ago"), or "\u{2014}" if
        /// no reading has ever been recorded.
        let lastReadingText: String
        /// Meters that haven't been read in at least `staleMeterThresholdDays`
        /// days, most-overdue first, capped to the top 3.
        let overdueMeters: [OverdueMeterSummary]

        /// A summary with nothing loaded yet — used as the initial/failure state.
        static let empty = HomeSummary(buildingCount: 0, meterCount: 0, lastReadingText: "\u{2014}", overdueMeters: [])
    }

    /// One row in the Home screen's "Needs Attention" list.
    struct OverdueMeterSummary: Identifiable {
        let id: UUID
        /// e.g. "141 Franklin \u{B7} Floor 9 \u{B7} Meter 3"
        let label: String
        /// `nil` means the meter has never had a reading recorded at all.
        let daysSinceReading: Int?
        /// Carried along so tapping this row can jump straight to adding a
        /// reading for this exact meter.
        let meter: MRKMeter
        /// The meter's floor, carried along for the same reason as `meter`.
        let floor: MRKFloor
        /// The meter's building, carried along for the same reason as `meter`.
        let building: MRKBuilding
    }

    /// Meters with no reading in at least this many days are surfaced in
    /// the "Needs Attention" list. This is the threshold from the Home
    /// redesign mockup -- a starting guess, not a value you've confirmed,
    /// so treat it as easy to change here if it doesn't feel right. Sourced
    /// from `MRKMeter.staleThresholdDays` (2026-08-28) so this list and the
    /// Manage screen's meter rows can't drift apart.
    static let staleMeterThresholdDays = MRKMeter.staleThresholdDays

    #if DEBUG || TESTING
    /// Which seeding operation actually ran, so the View can show the
    /// matching success message.
    enum SeedOutcome {
        /// The store was empty, so the full seed fixture was loaded.
        case seededInitialData
        /// The store already had buildings, so one new reading per meter
        /// was added instead.
        case addedMoreReadings
    }
    #endif

    private let repository: MeterRepositoryProtocol

    #if DEBUG || TESTING
    private let dataSeeder: DataSeeder
    #endif

    /// Creates the Home view model.
    ///
    /// - Parameter repository: The repository to load buildings/meters from.
    init(repository: MeterRepositoryProtocol) {
        self.repository = repository
        #if DEBUG || TESTING
        self.dataSeeder = DataSeeder(repository: repository)
        #endif
    }

    /// Decides what tapping "Take Readings" should do, based on how many
    /// buildings currently exist.
    ///
    /// - Returns: `.noBuildings`, `.singleBuilding`, or `.chooseBuilding`
    ///   depending on the current building count. A repository failure is
    ///   treated the same as zero buildings.
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

    /// Loads the data behind the Home screen's "At a Glance" stats and
    /// "Needs Attention" list. Best-effort: a repository failure resolves
    /// to an empty summary rather than throwing, since Home should never
    /// fail to render because this secondary content couldn't load.
    func loadSummary() async -> HomeSummary {
        let buildings = (try? await repository.getBuildings()) ?? []

        let meterCount = buildings.reduce(0) { $0 + $1.totalMeterCount }

        var mostRecentReadingDate: Date?
        var overdue: [OverdueMeterSummary] = []
        let now = Date()

        for building in buildings {
            for floor in building.floors {
                for meter in floor.meters {
                    if meter.latestReadingDate > (mostRecentReadingDate ?? .distantPast) {
                        mostRecentReadingDate = meter.latestReadingDate
                    }

                    // `latestReadingDate` defaults to `.distantPast` for a
                    // meter that has never had a reading recorded.
                    if meter.latestReadingDate == .distantPast {
                        overdue.append(OverdueMeterSummary(
                            id: meter.id,
                            label: "\(building.name) \u{B7} Floor \(floor.number) \u{B7} \(meter.name)",
                            daysSinceReading: nil,
                            meter: meter,
                            floor: floor,
                            building: building
                        ))
                        continue
                    }

                    let days = Calendar.current.dateComponents(
                        [.day], from: meter.latestReadingDate, to: now
                    ).day ?? 0

                    if days >= Self.staleMeterThresholdDays {
                        overdue.append(OverdueMeterSummary(
                            id: meter.id,
                            label: "\(building.name) \u{B7} Floor \(floor.number) \u{B7} \(meter.name)",
                            daysSinceReading: days,
                            meter: meter,
                            floor: floor,
                            building: building
                        ))
                    }
                }
            }
        }

        // Never-read meters are the most overdue by definition; among the
        // rest, longest-overdue first.
        overdue.sort { lhs, rhs in
            switch (lhs.daysSinceReading, rhs.daysSinceReading) {
            case (nil, nil): return false
            case (nil, _): return true
            case (_, nil): return false
            case let (l?, r?): return l > r
            }
        }

        return HomeSummary(
            buildingCount: buildings.count,
            meterCount: meterCount,
            lastReadingText: Self.formatLastReading(mostRecentReadingDate),
            overdueMeters: Array(overdue.prefix(3))
        )
    }

    /// Formats a "most recent reading" date as a short relative string.
    ///
    /// - Parameter date: The most recent reading date, or `nil` if none.
    /// - Returns: "\u{2014}" for `nil`, "Today"/"Yesterday" for the last two
    ///   days, or "`N`d ago" otherwise.
    private static func formatLastReading(_ date: Date?) -> String {
        guard let date else { return "\u{2014}" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        switch days {
        case ..<0: return "\u{2014}" // clock skew guard; shouldn't happen
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return "\(days)d ago"
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
    ///
    /// - Parameter fixtureNameOverride: for unit tests that call this
    ///   directly and don't want the full fixture's cost — production and
    ///   the real "Seed Test Data" button both leave this `nil`.
    /// - Returns: Which seeding operation actually ran.
    /// - Throws: Whatever error the repository throws while seeding.
    func seedData(fixtureNameOverride: String? = nil) async throws -> SeedOutcome {
        let buildingCount = (try? await repository.getBuildings())?.count ?? 0

        if buildingCount == 0 {
            // UITestAppLauncher sets this env var (its own matching
            // "UITEST_FIXTURE_NAME" constant) to point UI test runs at a
            // smaller fixture than a person exploring the app manually.
            let fixtureName = fixtureNameOverride
                ?? ProcessInfo.processInfo.environment["UITEST_FIXTURE_NAME"]
                ?? SeedFixtureName.full
            try await dataSeeder.seedData(fixtureName: fixtureName)
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
