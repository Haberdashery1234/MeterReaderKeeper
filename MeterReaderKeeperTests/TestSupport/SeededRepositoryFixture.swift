//
//  SeededRepositoryFixture.swift
//  MeterReaderKeeperTests
//

import Foundation
@testable import MeterReaderKeeper

/// Seeds an in-memory repository with fixture data for use by a test
/// suite.
///
/// A suite type holds `let fixture: SeededRepositoryFixture`, created in
/// its own `init() async throws { fixture = try await SeededRepositoryFixture() }`,
/// and reads `fixture.repository` / `fixture.dataSeeder` /
/// `fixture.seededBuildings`. Each suite instance gets its own fully
/// independent in-memory store.
struct SeededRepositoryFixture {

    /// Arbitrary but fixed — what matters is that it never changes, so
    /// the fixture data it produces stays stable across test runs.
    static let fixedSeed: UInt64 = 42

    let repository: SwiftDataMeterRepository
    let dataSeeder: DataSeeder
    let seededBuildings: [MRKBuilding]

    init() async throws {
        let repository = SwiftDataMeterRepository(inMemory: true)
        let dataSeeder = DataSeeder(repository: repository, rng: SeededGenerator(seed: Self.fixedSeed))
        try await dataSeeder.seedData(fixtureName: SeedFixtureName.small)

        self.repository = repository
        self.dataSeeder = dataSeeder
        self.seededBuildings = try await repository.getBuildings()
    }
}
