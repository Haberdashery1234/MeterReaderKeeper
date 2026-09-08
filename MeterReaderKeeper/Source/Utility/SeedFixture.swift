//
//  SeedFixture.swift
//  MeterReaderKeeper
//
//  Created on 8/27/26.
//

#if DEBUG || TESTING

import Foundation

/// Decodes `SeedFixture.json` (bundled at `Source/Resources/SeedFixture.json`)
/// — the single source of fixture data used both by `DataSeeder` (the
/// app's "Seed Test Data" button) and by the unit test target, so both
/// work from exactly the same data instead of two independently
/// maintained copies that could drift apart.
///
/// This type only decodes the JSON; it doesn't know where the file lives.
/// `DataSeeder` locates it via a bundle resource lookup (works on-device);
/// the test target locates the same physical file by a path relative to
/// its own source location instead, since bundle-resource lookups from a
/// unit test target depend on whether it's a hosted or standalone test
/// bundle — see `FixtureLoader` in `MeterReaderKeeperTests`.
struct SeedFixture: Decodable {

    struct Building: Decodable {
        let name: String
        let floors: [Floor]
    }

    struct Floor: Decodable {
        let number: Int16
        let meters: [Meter]
    }

    struct Meter: Decodable {
        let name: String
        let description: String
        let readings: [Reading]
    }

    struct Reading: Decodable {
        /// How many days before "now" this reading's date should be —
        /// relative rather than an absolute date, so the fixture stays
        /// valid (no reading ever lands in the future, which
        /// `MRKReadingInput.validate()` would reject) no matter when it's
        /// loaded.
        let daysAgo: Int
        let kWh: Double
    }

    let buildings: [Building]

    static func decode(from data: Data) throws -> SeedFixture {
        try JSONDecoder().decode(SeedFixture.self, from: data)
    }
}
#endif // DEBUG || TESTING

