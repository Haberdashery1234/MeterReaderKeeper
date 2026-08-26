//
//  MeterRepositoryProtocol.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation

/// Abstraction over the app's persistence layer.
///
/// Views (and, in a later pass, view models) talk to this protocol only —
/// never to Core Data directly — so the persistence technology can change
/// without touching the presentation layer, and so a fake/in-memory
/// implementation can stand in for tests.
///
/// Every method is synchronous but internally hops onto Core Data's own
/// confinement queue (see `CoreDataMeterRepository`), so it's safe to call
/// from any thread. That matches how this app's UIKit call sites already
/// work today (a button tap runs the operation and updates UI immediately);
/// a background-queue call site (see `HomeViewController.exportDataTapped`)
/// still works correctly, it just blocks that background thread rather than
/// the main thread.
protocol MeterRepositoryProtocol: AnyObject {

    // MARK: - Buildings

    /// Fetches every building, with its floors, meters, and readings fully
    /// populated (nested), sorted by name.
    func getBuildings() throws -> [MRKBuilding]

    /// Creates a new building, optionally auto-creating its floors.
    func addBuilding(_ input: MRKBuildingInput) throws -> MRKBuilding

    /// Deletes a building and everything under it (floors, meters, readings).
    func deleteBuilding(id: UUID) throws

    // MARK: - Floors

    /// Adds a new floor to an existing building.
    func addFloor(_ input: MRKFloorInput) throws -> MRKFloor

    /// Updates an existing floor's building, number, and/or map image.
    func updateFloor(id: UUID, input: MRKFloorInput) throws -> MRKFloor

    // MARK: - Meters

    /// Creates a new meter on a floor.
    func addMeter(_ input: MRKMeterInput) throws -> MRKMeter

    /// Updates an existing meter's name, description, floor, and/or image.
    func updateMeter(id: UUID, input: MRKMeterInput) throws -> MRKMeter

    /// Deletes a meter and its reading history.
    func deleteMeter(id: UUID) throws

    // MARK: - Readings

    /// Records a new reading for a meter.
    func addReading(_ input: MRKReadingInput) throws -> MRKReading

    /// Updates an existing reading's value. Matches this app's existing
    /// convention that edited readings are re-dated to today.
    func updateReading(id: UUID, kWh: Double) throws -> MRKReading

    // MARK: - Export

    /// Serializes every building (with its floors/meters/readings) to the
    /// app's plist export format and returns the file's contents.
    func exportAllDataToPlist() throws -> Data

    /// Builds a CSV summary of today's readings for one building.
    func getCSVData(forBuilding buildingID: UUID) throws -> Data
}
