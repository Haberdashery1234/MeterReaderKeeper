//
//  FixtureLoader.swift
//  MeterReaderKeeperTests
//

import Foundation
@testable import MeterReaderKeeper

/// Loads `SeedFixture.json` directly off disk, relative to this source
/// file's own location on disk, instead of through a bundle-resource
/// lookup.
///
/// The app side (`DataSeeder`) loads the same physical file via
/// `Bundle(for: DataSeeder.self)`, which works because the file is a
/// Copy-Bundle-Resources member of the app target. Whether that resource
/// is *also* reachable from this test target's own bundle depends on
/// whether `MeterReaderKeeperTests` is a hosted unit test target (sharing
/// the app's bundle at runtime) or a standalone logic-test bundle — not
/// something this environment has a compiler/Xcode available to confirm.
/// Reading the file directly by path sidesteps that question entirely:
/// `#filePath` always expands to this file's real absolute path on
/// whatever machine compiled it, so walking up from it to
/// `MeterReaderKeeper/Source/Resources/SeedFixture.json` finds the exact
/// same checked-in file either way.
enum FixtureLoader {

    struct LoadError: Error, CustomStringConvertible {
        let description: String
    }

    /// - Parameter name: bundle resource base name (no extension), e.g.
    ///   `SeedFixtureName.full`/`.small`/`.minimal` from `DataSeeder`.
    static func loadSeedFixtureData(named name: String = SeedFixtureName.full) throws -> Data {
        // This file lives at "<repo root>/MeterReaderKeeperTests/TestSupport/FixtureLoader.swift".
        let thisFile = URL(fileURLWithPath: #filePath)
        let repoRoot = thisFile
            .deletingLastPathComponent() // .../MeterReaderKeeperTests/TestSupport
            .deletingLastPathComponent() // .../MeterReaderKeeperTests
            .deletingLastPathComponent() // .../<repo root>
        let fixtureURL = repoRoot.appendingPathComponent("MeterReaderKeeper/Source/Resources/\(name).json")

        guard FileManager.default.fileExists(atPath: fixtureURL.path) else {
            throw LoadError(description: "\(name).json not found at expected path: \(fixtureURL.path)")
        }
        return try Data(contentsOf: fixtureURL)
    }

    static func loadSeedFixture(named name: String = SeedFixtureName.full) throws -> SeedFixture {
        try SeedFixture.decode(from: try loadSeedFixtureData(named: name))
    }
}
