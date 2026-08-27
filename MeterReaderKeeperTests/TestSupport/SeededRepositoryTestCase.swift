//
//  SeededRepositoryTestCase.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Base class for tests that need a populated store to work against,
/// instead of each test file building its own bespoke fixture data.
///
/// `setUpWithError()` runs the *same* `DataSeeder` the app's "Seed Test
/// Data" button uses, against a fresh in-memory `SwiftDataMeterRepository`.
/// `seedData()` itself is fully deterministic now — it loads
/// `SeedFixture.json`, a fixed, checked-in dataset, rather than generating
/// random values — so every test run produces byte-for-byte identical
/// fixture data with no seeding needed for that part. The `SeededGenerator`
/// passed in below only matters for `seedMoreReadings()`, which still
/// generates a value per call; passing a fixed seed keeps that
/// reproducible too, for any test that exercises it. Subclasses get
/// `repository`, `dataSeeder`, and `seededBuildings` ready to use — see
/// `FixtureLoader` for how to load `SeedFixture.json` itself and assert
/// against its exact values instead of a second, hand-copied set of
/// expectations that could drift out of sync.
class SeededRepositoryTestCase: XCTestCase {

    /// Arbitrary but fixed — any constant value works equally well here;
    /// what matters is that it never changes, so the fixture data it
    /// produces stays stable across test runs.
    static let fixedSeed: UInt64 = 42

    private(set) var repository: SwiftDataMeterRepository!
    private(set) var dataSeeder: DataSeeder!
    private(set) var seededBuildings: [MRKBuilding] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        let repository = SwiftDataMeterRepository(inMemory: true)
        let dataSeeder = DataSeeder(repository: repository, rng: SeededGenerator(seed: Self.fixedSeed))
        try dataSeeder.seedData()

        self.repository = repository
        self.dataSeeder = dataSeeder
        self.seededBuildings = try repository.getBuildings()
    }

    override func tearDownWithError() throws {
        repository = nil
        dataSeeder = nil
        seededBuildings = []
        try super.tearDownWithError()
    }
}
