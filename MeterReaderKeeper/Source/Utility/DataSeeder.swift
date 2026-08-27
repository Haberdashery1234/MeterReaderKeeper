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
//

#if DEBUG || TESTING

import Foundation

class DataSeeder {

    /// kWh range for `seedMoreReadings()`'s additional readings. `seedData()`
    /// no longer draws from a range — its data comes from `SeedFixture.json`
    /// instead (see below) — but `seedMoreReadings()` is a "top up whatever
    /// already exists" operation with nothing sensible to source from a
    /// fixture, so it still generates a value each time it's called.
    static let additionalReadingKWhRange: ClosedRange<Double> = 10_000...50_000

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

    /// Seeds building, floor, meter, and reading data from the bundled
    /// `SeedFixture.json` — a large, fixed dataset (buildings/floors/
    /// meters/readings) checked into the repo and shared verbatim with the
    /// unit test target, so both this button and the tests work from
    /// exactly the same known values.
    ///
    /// This makes one repository call per building/floor/meter/reading —
    /// several thousand calls for the full fixture — each of which now
    /// genuinely suspends onto the repository's own `ModelActor`, so callers
    /// don't need to background this themselves (see
    /// `HomeViewModel.seedData()`).
    func seedData() async throws {
        print("Starting data seeding...")

        let fixture = try Self.loadFixture()
        let today = Calendar.current.startOfDay(for: Date())

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

        print("Data seeding complete.")
    }

    /// Adds one additional reading, dated today, to every existing meter.
    func seedMoreReadings() async throws {
        let date = Calendar.current.startOfDay(for: Date())

        var readingCount = 0

        for building in try await repository.getBuildings() {
            for floor in building.floors {
                for meter in floor.meters {
                    let kWh = Double.random(in: Self.additionalReadingKWhRange, using: &rng)
                    _ = try await repository.addReading(MRKReadingInput(kWh: kWh, date: date, meterID: meter.id))
                    readingCount += 1
                }
            }
        }
    }

    /// Locates and decodes `SeedFixture.json` from this class's own bundle.
    /// `Bundle(for:)` rather than `Bundle.main` on purpose — this always
    /// resolves to the bundle `DataSeeder` itself was compiled into,
    /// regardless of how it's called.
    private static func loadFixture() throws -> SeedFixture {
        guard let url = Bundle(for: DataSeeder.self).url(forResource: "SeedFixture", withExtension: "json") else {
            throw MeterKeeperError.fileSystemError(
                NSError(domain: "MeterReaderKeeper", code: -1, userInfo: [NSLocalizedDescriptionKey: "SeedFixture.json not found in bundle"])
            )
        }
        let data = try Data(contentsOf: url)
        return try SeedFixture.decode(from: data)
    }
}
#endif // DEBUG || TESTING
