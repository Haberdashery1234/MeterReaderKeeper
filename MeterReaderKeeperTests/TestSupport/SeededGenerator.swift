//
//  SeededGenerator.swift
//  MeterReaderKeeperTests
//

import Foundation

/// A deterministic `RandomNumberGenerator`: the same seed always produces
/// the same sequence of values, in the same order, on every run.
///
/// This exists so `DataSeeder` (which takes a `RandomNumberGenerator` via
/// its `rng:` init parameter) can be seeded with fully reproducible fixture
/// data in tests, instead of the real `SystemRandomNumberGenerator` it uses
/// in the app, where every run produces different floor counts, meter
/// names, and reading values.
///
/// This is SplitMix64 (Vigna, public domain) — a fast, well-known,
/// non-cryptographic generator chosen only for its determinism, not for
/// statistical quality beyond "good enough to look randomly-shaped."
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
