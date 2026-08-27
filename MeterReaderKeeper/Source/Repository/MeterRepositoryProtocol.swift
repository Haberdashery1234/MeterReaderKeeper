//
//  MeterRepositoryProtocol.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//  Converted to an async protocol backed by a ModelActor on 8/27/26 (see
//  "Proper concurrency" migration note in project history).
//

import Foundation

/// Abstraction over the app's persistence layer.
///
/// View models talk to this protocol only — never to the underlying
/// persistence framework directly — so the persistence technology can
/// change without touching the ViewModel/View layers, and so a fake/in-memory
/// implementation can stand in for tests. This paid off directly: the app
/// originally shipped on Core Data and was later switched to SwiftData
/// (see `SwiftDataMeterRepository`) without any changes above this protocol.
///
/// Every method is `async throws`. `SwiftDataMeterRepository` is a real
/// `ModelActor`, so calling any of these methods from outside it (i.e. from
/// every ViewModel) requires `await` and genuinely suspends while the work
/// happens on the repository's own actor — no manual `DispatchQueue`
/// wrapping needed at call sites.
///
/// This replaces an earlier version of this protocol whose methods were
/// synchronous `throws`, with the promise that every implementation
/// internally confined its work to its own dedicated queue so it was safe
/// to call from any thread (matching how `NSManagedObjectContext.performAndWait`
/// worked for the Core Data implementation this one replaced). That design
/// was deliberately chosen to avoid rippling `async` into every ViewModel
/// and View action handler; this migration accepts that ripple in full in
/// exchange for using SwiftData's actually-documented concurrency pattern
/// (`ModelActor`) instead of a hand-rolled queue-confinement trick that was
/// never verified against a real SwiftData stack.
protocol MeterRepositoryProtocol: AnyObject {

    // MARK: - Buildings

    /// Fetches every building, with its floors, meters, and readings fully
    /// populated (nested), sorted by name.
    func getBuildings() async throws -> [MRKBuilding]

    /// Fetches a single building by ID, with its floors, meters, and readings
    /// fully populated (nested).
    func getBuilding(id: UUID) async throws -> MRKBuilding

    /// Creates a new building, optionally auto-creating its floors.
    func addBuilding(_ input: MRKBuildingInput) async throws -> MRKBuilding

    /// Deletes a building and everything under it (floors, meters, readings).
    func deleteBuilding(id: UUID) async throws

    // MARK: - Floors

    /// Adds a new floor to an existing building.
    func addFloor(_ input: MRKFloorInput) async throws -> MRKFloor

    /// Updates an existing floor's building, number, and/or map image.
    func updateFloor(id: UUID, input: MRKFloorInput) async throws -> MRKFloor

    // MARK: - Meters

    /// Creates a new meter on a floor.
    func addMeter(_ input: MRKMeterInput) async throws -> MRKMeter

    /// Updates an existing meter's name, description, floor, and/or image.
    func updateMeter(id: UUID, input: MRKMeterInput) async throws -> MRKMeter

    /// Deletes a meter and its reading history.
    func deleteMeter(id: UUID) async throws

    // MARK: - Readings

    /// Records a new reading for a meter.
    func addReading(_ input: MRKReadingInput) async throws -> MRKReading

    /// Updates an existing reading's value. Matches this app's existing
    /// convention that edited readings are re-dated to today.
    func updateReading(id: UUID, kWh: Double) async throws -> MRKReading

    // MARK: - Export

    /// Serializes every building (with its floors/meters/readings) to the
    /// app's plist export format and returns the file's contents.
    func exportAllDataToPlist() async throws -> Data

    /// Builds a CSV summary of today's readings for one building.
    func getCSVData(forBuilding buildingID: UUID) async throws -> Data
}
