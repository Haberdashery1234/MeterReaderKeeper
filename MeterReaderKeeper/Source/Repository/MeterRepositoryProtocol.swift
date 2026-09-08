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
/// implementation can stand in for tests. This paid off directly when the
/// app's persistence layer was migrated to SwiftData (see
/// `SwiftDataMeterRepository`) without any changes above this protocol.
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
/// to call from any thread. That design was deliberately chosen to avoid
/// rippling `async` into every ViewModel and View action handler; this
/// migration accepts that ripple in full in exchange for using SwiftData's
/// actually-documented concurrency pattern (`ModelActor`) instead of a
/// hand-rolled queue-confinement trick that was never verified against a
/// real SwiftData stack.
protocol MeterRepositoryProtocol: AnyObject {

    // MARK: - Buildings

    /// Fetches every building, with its floors, meters, and readings fully
    /// populated (nested), sorted by name.
    ///
    /// - Returns: Every building in the store, name-ascending.
    /// - Throws: `MeterKeeperError.persistenceError` if the underlying fetch fails.
    func getBuildings() async throws -> [MRKBuilding]

    /// Fetches a single building by ID, with its floors, meters, and readings
    /// fully populated (nested).
    ///
    /// - Parameter id: The building's identifier.
    /// - Returns: The matching building.
    /// - Throws: `MeterKeeperError.notFound` if no building has that `id`.
    func getBuilding(id: UUID) async throws -> MRKBuilding

    /// Creates a new building, optionally auto-creating its floors.
    ///
    /// - Parameter input: The new building's name, floor count, and whether
    ///   to auto-create that many floors.
    /// - Returns: The newly created building.
    /// - Throws: `MeterKeeperError.validationError` if `input` fails
    ///   `MRKBuildingInput.validate()`.
    func addBuilding(_ input: MRKBuildingInput) async throws -> MRKBuilding

    /// Deletes a building and everything under it (floors, meters, readings).
    ///
    /// - Parameter id: The building's identifier.
    /// - Throws: `MeterKeeperError.notFound` if no building has that `id`.
    func deleteBuilding(id: UUID) async throws

    // MARK: - Floors

    /// Adds a new floor to an existing building.
    ///
    /// - Parameter input: The new floor's number, map image, and building.
    /// - Returns: The newly created floor.
    /// - Throws: `MeterKeeperError.notFound` if `input.buildingID` doesn't
    ///   match an existing building.
    func addFloor(_ input: MRKFloorInput) async throws -> MRKFloor

    /// Updates an existing floor's building, number, and/or map image.
    ///
    /// - Parameters:
    ///   - id: The floor's identifier.
    ///   - input: The floor's new number, map image, and building.
    /// - Returns: The updated floor.
    /// - Throws: `MeterKeeperError.notFound` if `id` or `input.buildingID`
    ///   doesn't match an existing record.
    func updateFloor(id: UUID, input: MRKFloorInput) async throws -> MRKFloor

    /// Deletes a floor and everything under it (meters, readings).
    ///
    /// - Parameter id: The floor's identifier.
    /// - Throws: `MeterKeeperError.notFound` if no floor has that `id`.
    func deleteFloor(id: UUID) async throws

    // MARK: - Meters

    /// Creates a new meter on a floor.
    ///
    /// - Parameter input: The new meter's name, description, image, and floor.
    /// - Returns: The newly created meter.
    /// - Throws: `MeterKeeperError.validationError` if `input` fails
    ///   `MRKMeterInput.validate()`, or `.notFound` if `input.floorID`
    ///   doesn't match an existing floor.
    func addMeter(_ input: MRKMeterInput) async throws -> MRKMeter

    /// Updates an existing meter's name, description, floor, and/or image.
    ///
    /// - Parameters:
    ///   - id: The meter's identifier.
    ///   - input: The meter's new name, description, image, and floor.
    /// - Returns: The updated meter.
    /// - Throws: `MeterKeeperError.validationError` if `input` fails
    ///   `MRKMeterInput.validate()`, or `.notFound` if `id` or
    ///   `input.floorID` doesn't match an existing record.
    func updateMeter(id: UUID, input: MRKMeterInput) async throws -> MRKMeter

    /// Deletes a meter and its reading history.
    ///
    /// - Parameter id: The meter's identifier.
    /// - Throws: `MeterKeeperError.notFound` if no meter has that `id`.
    func deleteMeter(id: UUID) async throws

    // MARK: - Readings

    /// Records a new reading for a meter.
    ///
    /// - Parameter input: The reading's value, date, and meter.
    /// - Returns: The newly created reading.
    /// - Throws: `MeterKeeperError.validationError` if `input` fails
    ///   `MRKReadingInput.validate()`, or `.notFound` if `input.meterID`
    ///   doesn't match an existing meter.
    func addReading(_ input: MRKReadingInput) async throws -> MRKReading

    /// Updates an existing reading's value. Matches this app's existing
    /// convention that edited readings are re-dated to today.
    ///
    /// - Parameters:
    ///   - id: The reading's identifier.
    ///   - kWh: The reading's new value.
    /// - Returns: The updated reading.
    /// - Throws: `MeterKeeperError.notFound` if no reading has that `id`.
    func updateReading(id: UUID, kWh: Double) async throws -> MRKReading

    // MARK: - Batching

#if DEBUG || TESTING
    /// Runs `body` with per-call saves suppressed, then saves once.
    ///
    /// - Parameter body: Work that makes one or more add/update/delete calls on this repository.
    /// - Returns: `body`'s result.
    /// - Throws: Whatever `body` throws.
    func withBatchedSave<T>(_ body: () async throws -> T) async throws -> T
#endif

    // MARK: - Export

    /// Serializes every building (with its floors/meters/readings) to the
    /// app's plist export format and returns the file's contents.
    ///
    /// - Returns: The exported plist file's raw bytes.
    /// - Throws: `MeterKeeperError.fileSystemError` if writing or re-reading
    ///   the plist fails.
    func exportAllDataToPlist() async throws -> Data

    /// Builds a CSV summary of today's readings for one building.
    ///
    /// - Parameter buildingID: The building's identifier.
    /// - Returns: The CSV file's raw UTF-8 bytes.
    /// - Throws: `MeterKeeperError.notFound` if no building has that `id`,
    ///   or `.fileSystemError` if the CSV text can't be UTF-8 encoded.
    func getCSVData(forBuilding buildingID: UUID) async throws -> Data
}
