//
//  SwiftDataMeterRepository.swift
//  MeterReaderKeeper
//
//  Created by Core Data -> SwiftData Migration on 8/26/26.
//

import Foundation
import SwiftData

/// SwiftData-backed implementation of `MeterRepositoryProtocol`.
///
/// This is the *only* place in the app (besides the `Model/SwiftData` files
/// themselves) that should import `SwiftData` or touch the `SDBuilding` /
/// `SDFloor` / `SDMeter` / `SDReading` classes directly. Everything above
/// this layer — view models, views — works exclusively with the plain
/// `MRKBuilding` / `MRKFloor` / `MRKMeter` / `MRKReading` domain structs in
/// `Model/Domain`. This mirrors `CoreDataMeterRepository`, the Core Data
/// implementation this one replaces.
///
/// ## Threading design
///
/// `MeterRepositoryProtocol`'s contract (see that file) is that every
/// method is synchronous and safe to call from *any* thread — a promise the
/// Core Data implementation kept via `NSManagedObjectContext.performAndWait`.
/// SwiftData's `ModelContext` has no equivalent built-in "confine to my own
/// queue and let any caller block on it" primitive; Apple's documented
/// pattern for background access is a custom `actor` conforming to
/// `ModelActor`, with `async` methods.
///
/// Adopting that would mean turning every `MeterRepositoryProtocol` method
/// `async`, which ripples into every ViewModel and every View's action
/// handlers — exactly the blast radius the repository/ViewModel split was
/// built to avoid when swapping persistence technology. Instead, this type
/// preserves the original synchronous contract by manually confining a
/// single long-lived `ModelContext` to a private serial `DispatchQueue` and
/// running every operation via `queue.sync` — the same "queue confinement"
/// idea Core Data uses internally, applied by hand. `ModelContext` itself
/// isn't `@MainActor`-isolated (only `ModelContainer.mainContext` is), so
/// this is legal; it just isn't the officially blessed `ModelActor` pattern,
/// and it hasn't been compiled or run anywhere with a real SwiftData stack.
/// If a future build hits Sendability/actor-isolation compiler errors here,
/// the fallback is adopting `ModelActor` and making the protocol `async`.
final class SwiftDataMeterRepository: MeterRepositoryProtocol {

    private let container: ModelContainer
    private let context: ModelContext
    private let queue = DispatchQueue(label: "com.meterreaderkeeper.swiftdatarepository", qos: .userInitiated)

    /// - Parameter inMemory: pass `true` (e.g. from unit tests) to back the
    ///   store with an in-memory store instead of the real SQLite file on
    ///   disk.
    init(inMemory: Bool = false) {
        let schema = Schema([SDBuilding.self, SDFloor.self, SDMeter.self, SDReading.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A failed store load leaves the app with nowhere to persist
            // data. This still can't be recovered from in-app, so it remains
            // fatal (as it was for the Core Data repository this replaces)
            // — but at least the failure reason is surfaced via the crash log.
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }

        context = ModelContext(container)
        // Explicit save control only, matching the original repository's
        // philosophy of saving exactly when `Self.save(context)` is called.
        context.autosaveEnabled = false
    }

    // MARK: - Buildings

    func getBuildings() throws -> [MRKBuilding] {
        try performAndWaitThrowing {
            let descriptor = FetchDescriptor<SDBuilding>(sortBy: [SortDescriptor(\.name, order: .forward)])
            let managedBuildings = try context.fetch(descriptor)
            return managedBuildings.map(Self.mapBuilding)
        }
    }

    func getBuilding(id: UUID) throws -> MRKBuilding {
        try performAndWaitThrowing {
            let building = try Self.findBuilding(id: id, in: context)
            return Self.mapBuilding(building)
        }
    }

    func addBuilding(_ input: MRKBuildingInput) throws -> MRKBuilding {
        try input.validate()
        return try performAndWaitThrowing {
            let building = SDBuilding(name: input.name)
            context.insert(building)

            if input.autoCreateFloors {
                for i in 1...input.numberOfFloors {
                    let floor = SDFloor(number: i, mapImageData: Data(), building: building)
                    context.insert(floor)
                }
            }

            try Self.save(context)
            return Self.mapBuilding(building)
        }
    }

    func deleteBuilding(id: UUID) throws {
        try performAndWaitThrowing {
            let building = try Self.findBuilding(id: id, in: context)
            context.delete(building)
            try Self.save(context)
        }
    }

    // MARK: - Floors

    func addFloor(_ input: MRKFloorInput) throws -> MRKFloor {
        try performAndWaitThrowing {
            let building = try Self.findBuilding(id: input.buildingID, in: context)

            let floor = SDFloor(number: input.number, mapImageData: input.mapImageData, building: building)
            context.insert(floor)

            try Self.save(context)
            return Self.mapFloor(floor)
        }
    }

    func updateFloor(id: UUID, input: MRKFloorInput) throws -> MRKFloor {
        try performAndWaitThrowing {
            let floor = try Self.findFloor(id: id, in: context)
            let building = try Self.findBuilding(id: input.buildingID, in: context)

            floor.building = building
            floor.number = input.number
            floor.mapImageData = input.mapImageData

            try Self.save(context)
            return Self.mapFloor(floor)
        }
    }

    // MARK: - Meters

    func addMeter(_ input: MRKMeterInput) throws -> MRKMeter {
        try input.validate()
        return try performAndWaitThrowing {
            let floor = try Self.findFloor(id: input.floorID, in: context)

            let meter = SDMeter(
                name: input.name,
                meterDescription: input.description,
                qrString: Self.qrString(buildingName: floor.building?.name ?? "", floorNumber: floor.number, meterName: input.name),
                imageData: input.imageData,
                latestReading: Date.distantPast,
                floor: floor
            )
            context.insert(meter)

            try Self.save(context)
            return Self.mapMeter(meter)
        }
    }

    func updateMeter(id: UUID, input: MRKMeterInput) throws -> MRKMeter {
        try input.validate()
        return try performAndWaitThrowing {
            let meter = try Self.findMeter(id: id, in: context)
            let floor = try Self.findFloor(id: input.floorID, in: context)

            meter.name = input.name
            meter.meterDescription = input.description
            meter.imageData = input.imageData
            meter.floor = floor
            meter.qrString = Self.qrString(buildingName: floor.building?.name ?? "", floorNumber: floor.number, meterName: input.name)

            try Self.save(context)
            return Self.mapMeter(meter)
        }
    }

    func deleteMeter(id: UUID) throws {
        try performAndWaitThrowing {
            let meter = try Self.findMeter(id: id, in: context)
            context.delete(meter)
            try Self.save(context)
        }
    }

    // MARK: - Readings

    func addReading(_ input: MRKReadingInput) throws -> MRKReading {
        try input.validate()
        return try performAndWaitThrowing {
            let meter = try Self.findMeter(id: input.meterID, in: context)

            if input.date > meter.latestReading {
                meter.latestReading = input.date
            }

            let reading = SDReading(date: input.date, kWh: input.kWh, meter: meter)
            context.insert(reading)

            try Self.save(context)
            return Self.mapReading(reading)
        }
    }

    func updateReading(id: UUID, kWh: Double) throws -> MRKReading {
        try performAndWaitThrowing {
            let reading = try Self.findReading(id: id, in: context)
            let date = Calendar.current.startOfDay(for: Date())

            reading.kWh = kWh
            reading.date = date
            reading.meter?.latestReading = date

            try Self.save(context)
            return Self.mapReading(reading)
        }
    }

    // MARK: - Export

    func exportAllDataToPlist() throws -> Data {
        try performAndWaitThrowing {
            let descriptor = FetchDescriptor<SDBuilding>(sortBy: [SortDescriptor(\.name, order: .forward)])
            let buildings = try context.fetch(descriptor)

            let exportArray = NSMutableArray()
            for building in buildings {
                exportArray.add(building.getExportDictionary())
            }

            let exportURL = try Self.exportPlistURL()
            do {
                try exportArray.write(to: exportURL)
                return try Data(contentsOf: exportURL)
            } catch {
                throw MeterKeeperError.fileSystemError(error)
            }
        }
    }

    func getCSVData(forBuilding buildingID: UUID) throws -> Data {
        try performAndWaitThrowing {
            let managedBuilding = try Self.findBuilding(id: buildingID, in: context)
            let building = Self.mapBuilding(managedBuilding)

            var csvString = "\(building.name)"
            for floor in building.sortedFloors {
                csvString.append("\nFloor \(floor.number)\n")
                for meter in floor.sortedMeters {
                    guard let latestReading = meter.sortedReadings.first else { continue }
                    guard latestReading.date == Calendar.current.startOfDay(for: Date()) else { continue }

                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .none

                    let meterId = Self.qrString(buildingName: building.name, floorNumber: floor.number, meterName: meter.name)
                    let latestReadingKWH = String(format: "%.2f kWh", latestReading.kWh)
                    let latestReadingString = formatter.string(from: latestReading.date)
                    csvString.append(",\(meterId),\(latestReadingKWH),\(latestReadingString)\n")
                }
            }

            guard let csvData = csvString.data(using: .utf8) else {
                throw MeterKeeperError.fileSystemError(
                    NSError(domain: "MeterReaderKeeper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not encode CSV data"])
                )
            }
            return csvData
        }
    }

    // MARK: - Mapping: SwiftData -> Domain

    private static func mapBuilding(_ managed: SDBuilding) -> MRKBuilding {
        MRKBuilding(
            id: managed.id,
            name: managed.name,
            floors: managed.floors.sorted { $0.number < $1.number }.map(mapFloor)
        )
    }

    private static func mapFloor(_ managed: SDFloor) -> MRKFloor {
        MRKFloor(
            id: managed.id,
            number: managed.number,
            mapImageData: managed.mapImageData,
            buildingID: managed.building?.id ?? UUID(),
            meters: managed.meters.sorted { $0.name < $1.name }.map(mapMeter)
        )
    }

    private static func mapMeter(_ managed: SDMeter) -> MRKMeter {
        MRKMeter(
            id: managed.id,
            name: managed.name,
            meterDescription: managed.meterDescription,
            qrString: managed.qrString,
            imageData: managed.imageData,
            latestReadingDate: managed.latestReading,
            floorID: managed.floor?.id ?? UUID(),
            readings: managed.readings.sorted { $0.date > $1.date }.map(mapReading)
        )
    }

    private static func mapReading(_ managed: SDReading) -> MRKReading {
        MRKReading(
            id: managed.id,
            date: managed.date,
            kWh: managed.kWh,
            meterID: managed.meter?.id ?? UUID()
        )
    }

    // MARK: - Lookup helpers

    // Unlike the Core Data repository this replaces, these are real
    // indexed-by-id lookups (`#Predicate` fetches) rather than a
    // fetch-everything-and-scan — the payoff of giving each entity a real
    // persisted `id: UUID` instead of deriving one from an object identifier.

    private static func findBuilding(id: UUID, in context: ModelContext) throws -> SDBuilding {
        var descriptor = FetchDescriptor<SDBuilding>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let match = try context.fetch(descriptor).first else {
            throw MeterKeeperError.notFound("Building")
        }
        return match
    }

    private static func findFloor(id: UUID, in context: ModelContext) throws -> SDFloor {
        var descriptor = FetchDescriptor<SDFloor>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let match = try context.fetch(descriptor).first else {
            throw MeterKeeperError.notFound("Floor")
        }
        return match
    }

    private static func findMeter(id: UUID, in context: ModelContext) throws -> SDMeter {
        var descriptor = FetchDescriptor<SDMeter>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let match = try context.fetch(descriptor).first else {
            throw MeterKeeperError.notFound("Meter")
        }
        return match
    }

    private static func findReading(id: UUID, in context: ModelContext) throws -> SDReading {
        var descriptor = FetchDescriptor<SDReading>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let match = try context.fetch(descriptor).first else {
            throw MeterKeeperError.notFound("Reading")
        }
        return match
    }

    // MARK: - Small helpers

    private static func qrString(buildingName: String, floorNumber: Int16, meterName: String) -> String {
        "\(buildingName)::\(floorNumber)::\(meterName)"
    }

    private static func save(_ context: ModelContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw MeterKeeperError.persistenceError(error)
        }
    }

    private static func exportPlistURL() throws -> URL {
        guard let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw MeterKeeperError.fileSystemError(
                NSError(domain: "MeterReaderKeeper", code: -1, userInfo: [NSLocalizedDescriptionKey: "No document directory available"])
            )
        }
        return documentDirectoryURL.appendingPathComponent("exportData.plist", isDirectory: false)
    }

    // MARK: - Queue confinement

    /// Runs `block` synchronously on this repository's dedicated serial
    /// queue, the only place `context` is ever touched. See the type-level
    /// doc comment above for why this exists instead of `ModelActor`.
    private func performAndWaitThrowing<T>(_ block: () throws -> T) throws -> T {
        try queue.sync { try block() }
    }
}
