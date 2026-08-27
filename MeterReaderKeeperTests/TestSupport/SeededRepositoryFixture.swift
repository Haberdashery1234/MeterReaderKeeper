//
//  SeededRepositoryFixture.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26 (Swift Testing migration pilot; became the
//  permanent replacement for SeededRepositoryTestCase once the XCTest ->
//  Swift Testing migration finished the same day).
//

import Foundation
@testable import MeterReaderKeeper

/// Swift-Testing-idiomatic replacement for the now-deleted
/// `SeededRepositoryTestCase` (an XCTest base class that both
/// `SwiftDataMeterRepositoryTests` and `DataSeederTests` used to
/// subclass).
///
/// Swift Testing suites don't use XCTest's `setUp()`/`tearDown()`-via-
/// subclassing convention — a suite type's own `init()` runs before each
/// `@Test` in it (Swift Testing creates a fresh instance per test, the
/// same per-test isolation `XCTestCase` gives via a fresh instance per
/// test method), so shared "seed a store and hand back its contents"
/// logic is expressed as a plain composed value instead of something to
/// inherit from.
///
/// Usage: a suite type holds `let fixture: SeededRepositoryFixture`,
/// created in its own `init() throws { fixture = try SeededRepositoryFixture() }`,
/// and reads `fixture.repository` / `fixture.dataSeeder` / `fixture.seededBuildings`.
/// Every suite that does this still gets its own fully independent
/// in-memory store — nothing here is shared across tests, same as the
/// XCTest version.
struct SeededRepositoryFixture {

    /// Arbitrary but fixed — mirrors the old `SeededRepositoryTestCase.fixedSeed`
    /// exactly; what matters is that it never changes, so the fixture data
    /// it produces stays stable across test runs.
    static let fixedSeed: UInt64 = 42

    let repository: SwiftDataMeterRepository
    let dataSeeder: DataSeeder
    let seededBuildings: [MRKBuilding]

    init() throws {
        let repository = SwiftDataMeterRepository(inMemory: true)
        let dataSeeder = DataSeeder(repository: repository, rng: SeededGenerator(seed: Self.fixedSeed))
        try dataSeeder.seedData()

        self.repository = repository
        self.dataSeeder = dataSeeder
        self.seededBuildings = try repository.getBuildings()
    }
}
