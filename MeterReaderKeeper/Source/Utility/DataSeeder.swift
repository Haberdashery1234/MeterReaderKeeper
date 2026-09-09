//
//  DataSeeder.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//  Streamlined + shared constants extracted for unit testing on 8/27/26.
//  Randomness made injectable for deterministic unit testing on 8/27/26.
//  seedData() switched to a bundled JSON fixture (SeedFixture.json), shared
//  verbatim with the unit test target, on 8/27/26.
//  Converted to async throws to match the repository's ModelActor-backed
//  MeterRepositoryProtocol on 8/27/26 — this also means the thousands of
//  individual repository calls seedData() makes now genuinely happen on the
//  repository's own actor, so the manual DispatchQueue.global backgrounding
//  that used to live in HomeViewModel.seedData(completion:) is gone too.
//  Batched under one SwiftData save via withBatchedSave on 9/8/26.
//  seedData() parameterized on fixture name (small/minimal test fixtures
//  added alongside the full one) on 9/9/26.
//

#if DEBUG || TESTING

import Foundation

/// Bundle resource names (no extension) for the fixture files `DataSeeder`
/// can load. `full` is what the "Seed Test Data" button seeds for manual
/// exploration; `small`/`minimal` are smaller fixtures UI and unit tests
/// seed instead to cut seeding cost — see
/// `MeterReaderKeeperUITests/TestSupport/UITestAppLauncher.swift`.
enum SeedFixtureName {
    static let full = "SeedFixture"
    static let small = "SeedFixtureSmall"
    static let minimal = "SeedFixtureMinimal"
}

class DataSeeder {

    /// kWh **increment** range for `seedMoreReadings()`'s additional
    /// readings. `seedData()` no longer draws from a range — its data comes
    /// from `SeedFixture.json` instead (see below) — but `seedMoreReadings()`
    /// is a "top up whatever already exists" operation with nothing sensible
    /// to source from a fixture, so it still generates a value each time
    /// it's called.
    ///
    /// This is an **increment added on top of the meter's current latest
    /// reading**, not an absolute value (renamed from
    /// `additionalReadingKWhRange` — it used to be an absolute
    /// 10_000...50_000 draw, independent of whatever the meter's existing
    /// readings were, which could easily produce a *lower* reading than one
    /// already on file). Electric meters are cumulative: a real meter's
    /// reading never goes down, so every new reading this generates must be
    /// strictly higher than the meter's previous one — fixed after the
    /// Meter Details chart was observed to dip (2026-08-28).
    static let additionalReadingIncrementRange: ClosedRange<Double> = 50...500

    private let repository: MeterRepositoryProtocol

    /// Every "random" value `seedMoreReadings()` produces is drawn through
    /// this generator, never through the bare `Double.random` static
    /// directly. That's what makes the output controllable: the app passes
    /// nothing (defaulting to `SystemRandomNumberGenerator`, so production
    /// behavior is unchanged), while tests can pass a seeded, deterministic
    /// generator — see `SeededGenerator` in the test target.
    private var rng: RandomNumberGenerator

    init(repository: MeterRepositoryProtocol, rng: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.repository = repository
        self.rng = rng
    }

    /// Seeds building, floor, meter, and reading data from a bundled
    /// fixture JSON file, checked into the repo and shared verbatim with
    /// the unit test target so both this button and the tests work from
    /// exactly the same known values.
    ///
    /// - Parameter fixtureName: bundle resource name (no extension) to
    ///   load — see `SeedFixtureName`. Defaults to the full fixture.
    ///
    /// Makes one repository call per building/floor/meter/reading,
    /// batched under a single SwiftData save via `withBatchedSave`.
    func seedData(fixtureName: String = SeedFixtureName.full) async throws {
        print("Starting data seeding...")

        let fixture = try Self.loadFixture(named: fixtureName)
        let today = Calendar.current.startOfDay(for: Date())

        try await repository.withBatchedSave {
            for building in fixture.buildings {
                let newBuilding = try await repository.addBuilding(
                    MRKBuildingInput(name: building.name, numberOfFloors: Int16(building.floors.count), autoCreateFloors: false)
                )

                for floorFixture in building.floors {
                    let floor = try await repository.addFloor(
                        MRKFloorInput(number: floorFixture.number, mapImageData: Data(), buildingID: newBuilding.id)
                    )

                    for meterFixture in floorFixture.meters {
                        let meter = try await repository.addMeter(
                            MRKMeterInput(name: meterFixture.name, description: meterFixture.description, imageData: Data(), floorID: floor.id)
                        )

                        for readingFixture in meterFixture.readings {
                            let date = Calendar.current.date(byAdding: .day, value: -readingFixture.daysAgo, to: today) ?? today
                            _ = try await repository.addReading(MRKReadingInput(kWh: readingFixture.kWh, date: date, meterID: meter.id))
                        }
                    }
                }
            }
        }

        print("Data seeding complete.")
    }

    /// Adds one additional reading, dated today, to every existing meter —
    /// always **higher** than that meter's current latest reading (an
    /// electric meter's cumulative total only ever goes up). Falls back to
    /// `0` as the baseline for a meter with no prior readings at all
    /// (shouldn't happen via `seedData()`, which always seeds 5 per meter,
    /// but keeps this correct standalone too). Batched under one SwiftData
    /// save via `withBatchedSave`.
    func seedMoreReadings() async throws {
        let date = Calendar.current.startOfDay(for: Date())
        let buildings = try await repository.getBuildings()

        try await repository.withBatchedSave {
            for building in buildings {
                for floor in building.floors {
                    for meter in floor.meters {
                        let increment = Double.random(in: Self.additionalReadingIncrementRange, using: &rng)
                        let baseline = meter.mostRecentReading?.kWh ?? 0
                        let kWh = baseline + increment
                        _ = try await repository.addReading(MRKReadingInput(kWh: kWh, date: date, meterID: meter.id))
                    }
                }
            }
        }
    }

    /// Locates and decodes `<name>.json` from this class's own bundle.
    /// `Bundle(for:)` rather than `Bundle.main` on purpose — this always
    /// resolves to the bundle `DataSeeder` itself was compiled into,
    /// regardless of how it's called.
    private static func loadFixture(named name: String) throws -> SeedFixture {
        guard let url = Bundle(for: DataSeeder.self).url(forResource: name, withExtension: "json") else {
            throw MeterKeeperError.fileSystemError(
                NSError(domain: "MeterReaderKeeper", code: -1, userInfo: [NSLocalizedDescriptionKey: "\(name).json not found in bundle"])
            )
        }
        let data = try Data(contentsOf: url)
        return try SeedFixture.decode(from: data)
    }
}
#endif // DEBUG || TESTING
