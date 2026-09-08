//
//  MRKBuilding.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation

// MARK: - Domain Models
// Persistence-agnostic model types used throughout the app (view models,
// view controllers, and cells only ever see these `MRKXxx` types, never
// the `SDXxx` SwiftData models in `Source/Model/SwiftData`).

/// A building made up of one or more floors, each of which may contain meters.
struct MRKBuilding: Identifiable, Hashable {
    /// Stable identity for the building, shared with its SwiftData record.
    let id: UUID

    /// The building's display name.
    let name: String

    /// The building's floors, in no particular order. Use `sortedFloors`
    /// for a floor-number-ordered list.
    let floors: [MRKFloor]

    /// The total number of meters across every floor in this building.
    var totalMeterCount: Int {
        floors.reduce(0) { $0 + $1.meters.count }
    }

    /// `floors` sorted ascending by floor number.
    var sortedFloors: [MRKFloor] {
        floors.sorted { $0.number < $1.number }
    }

    /// Checks that this building has a non-empty name.
    ///
    /// - Throws: `MeterKeeperError.validationError(.missingRequiredField)`
    ///   if `name` is empty or all whitespace.
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Building name"))
        }
    }
}

/// The data needed to create a new building, or to reconcile an existing
/// one's floor count. See `AddEditBuildingViewModel` for how a floor-count
/// change is applied to an existing building.
struct MRKBuildingInput {
    /// The building's display name.
    let name: String

    /// How many floors the building should have.
    let numberOfFloors: Int16

    /// Whether the repository should create `numberOfFloors` empty floors
    /// automatically right after creating the building.
    let autoCreateFloors: Bool

    /// Checks that `name` is non-empty and `numberOfFloors` is within the
    /// supported range.
    ///
    /// - Throws: `MeterKeeperError.validationError` — `.missingRequiredField`
    ///   if `name` is empty, or `.invalidInput` if `numberOfFloors` falls
    ///   outside 1...200.
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Building name"))
        }
        guard numberOfFloors > 0 && numberOfFloors <= 200 else {
            throw MeterKeeperError.validationError(.invalidInput("Floor count must be between 1 and 200"))
        }
    }
}
