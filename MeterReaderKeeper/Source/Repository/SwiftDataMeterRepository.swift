//
//  SwiftDataMeterRepository.swift
//  MeterReaderKeeper
//
//  Created by Core Data -> SwiftData Migration on 8/26/26.
//  Converted from manual queue confinement to a real ModelActor on 8/27/26
//  (see "Proper concurrency" migration note in project history).
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
/// implementation this one replaced.
///
/// ## Threading design
///
/// This type is a real `ModelActor` (via the `@ModelActor` macro) — Apple's
/// documented pattern for SwiftData background access. The macro
/// synthesizes a `ModelContext` confined to this actor's own serial
/// executor, exposed as the `modelContext` property every method below
/// uses. Every method here is declared as a plain (non-`async`)
/// actor-isolated `throws` function; that's enough to satisfy
/// `MeterRepositoryProtocol`'s `async throws` requirements, because calling
/// *any* actor-isolated method from outside the actor requires `await`
/// regardless of whether the method itself is marked `async` — the `await`
/// is what crossing the actor boundary requires, not the function's own
/// keyword.
///
/// This replaces an earlier version of this type that manually confined a
/// single `ModelContext` to a private serial `DispatchQueue` and ran every
/// operation via `queue.sync`, to preserve a synchronous protocol contract
/// inherited from the Core Data implementation. That queue-confinement
/// trick worked in principle but wasn't the officially blessed approach and
/// was never verified against a real SwiftData stack. Adopting `ModelActor`
/// directly removes the need to guess — at the cost of every call site
/// (every ViewModel, and through them every View) now being `async` too, a
/// ripple the original migration deliberately avoided and this one accepts
/// in full.
@ModelActor
actor SwiftDataMeterRepository: MeterRepositoryProtocol {

    /// - Parameter inMemory: pass `true` (e.g. from unit tests) to back the
    ///   store with an in-memory store instead of the real SQLite file on
    ///   disk.
    ///
    /// This delegates to the `init(modelContainer:)` the `@ModelActor`
    /// macro synthesizes, then disables autosave on the context that
    /// initializer creates — matching the original repository's philosophy
    /// of saving exactly when `Self.save(context)` is called, never
    /// implicitly. This is a plain, non-`async` initializer, so constructing
    /// this actor (`SwiftDataMeterRepository()` / `SwiftDataMeterRepository(inMemory: true)`)
    /// stays a normal synchronous call from anywhere, same as before.
    init(inMemory: Bool = false) {
        let schema = Schema([SDBuilding.self, SDFloor.self, SDMeter.self, SDReading.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A failed store load leaves the app with nowhere to persist
            // data. This still can't be recovered from in-app, so it remains
            // fatal (as it was for the Core Data repository this replaces)
            // — but at least the failure reason is surfaced via the crash log.
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }

        self.init(modelContainer: container)
        modelContext.autosaveEnabled = false
    }

    // MARK: - Buildings

    func getBuildings() throws -> [MRKBuilding] {
        let descriptor = FetchDescriptor<SDBuilding>(sortBy: [SortDescriptor(\.name, order: .forward)])
        let managedBuildings = try modelContext.fetch(descriptor)
        return managedBuildings.map(Self.mapBuilding)
    }

    func getBuilding(id: UUID) throws -> MRKBuilding {
        let building = try Self.findBuilding(id: id, in: modelContext)
        return Self.mapBuilding(building)
    }

    func addBuilding(_ input: MRKBuildingInput) throws -> MRKBuilding {
        try input.validate()
        let building = SDBuilding(name: input.name)
        modelContext.insert(building)

        if input.autoCreateFloors {
            for i in 1...input.numberOfFloors {
                let floor = SDFloor(number: i, mapImageData: Data(), building: building)
                modelContext.insert(floor)
            }
        }

        try Self.save(modelContext)
        return Self.mapBuilding(building)
    }

    func deleteBuilding(id: UUID) throws {
        let building = try Self.findBuilding(id: id, in: modelContext)
        modelContext.delete(building)
        try Self.save(modelContext)
    }

    // MARK: - Floors

    func addFloor(_ input: MRKFloorInput) throws -> MRKFloor {
        let building = try Self.findBuilding(id: input.buildingID, in: modelContext)

        let floor = SDFloor(number: input.number, mapImageData: input.mapImageData, building: building)
        modelContext.insert(floor)

        try Self.save(modelContext)
        return Self.mapFloor(floor)
    }

    func updateFloor(id: UUID, input: MRKFloorInput) throws -> MRKFloor {
        let floor = try Self.findFloor(id: id, in: modelContext)
        let building = try Self.findBuilding(id: input.buildingID, in: modelContext)

        floor.building = building
        floor.number = input.number
        floor.mapImageData = input.mapImageData

        try Self.save(modelContext)
        return Self.mapFloor(floor)
    }

    // MARK: - Meters

    func addMeter(_ input: MRKMeterInput) throws -> MRKMeter {
        try input.validate()
        let floor = try Self.findFloor(id: input.floorID, in: modelContext)

        let meter = SDMeter(
            name: input.name,
            meterDescription: input.description,
            qrString: Self.qrString(buildingName: floor.building?.name ?? "", floorNumber: floor.number, meterName: input.name),
            imageData: input.imageData,
            latestReading: Date.distantPast,
            floor: floor
        )
        modelContext.insert(meter)

        try Self.save(modelContext)
        return Self.mapMeter(meter)
    }

    func updateMeter(id: UUID, input: MRKMeterInput) throws -> MRKMeter {
        try input.validate()
        let meter = try Self.findMeter(id: id, in: modelContext)
        let floor = try Self.findFloor(id: input.floorID, in: modelContext)

        meter.name = input.name
        meter.meterDescription = input.description
        meter.imageData = input.imageData
        meter.floor = floor
        meter.qrString = Self.qrString(buildingName: floor.building?.name ?? "", floorNumber: floor.number, meterName: input.name)

        try Self.save(modelContext)
        return Self.mapMeter(meter)
    }

    func deleteMeter(id: UUID) throws {
        let meter = try Self.findMeter(id: id, in: modelContext)
        modelContext.delete(meter)
        try Self.save(modelContext)
    }

    // MARK: - Readings

    func addReading(_ input: MRKReadingInput) throws -> MRKReading {
        try input.validate()
        let meter = try Self.findMeter(id: input.meterID, in: modelContext)

        if input.date > meter.latestReading {
            meter.latestReading = input.date
        }

        let reading = SDReading(date: input.date, kWh: input.kWh, meter: meter)
        modelContext.insert(reading)

        try Self.save(modelContext)
        return Self.mapReading(reading)
    }

    func updateReading(id: UUID, kWh: Double) throws -> MRKReading {
        let reading = try Self.findReading(id: id, in: modelContext)
        let date = Calendar.current.startOfDay(for: Date())

        reading.kWh = kWh
        reading.date = date
        reading.meter?.latestReading = date

        try Self.save(modelContext)
        return Self.mapReading(reading)
    }

    // MARK: - Export

    func exportAllDataToPlist() throws -> Data {
        let descriptor = FetchDescriptor<SDBuilding>(sortBy: [SortDescriptor(\.name, order: .forward)])
        let buildings = try modelContext.fetch(descriptor)

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

    func getCSVData(forBuilding buildingID: UUID) throws -> Data {
        let managedBuilding = try Self.findBuilding(id: buildingID, in: modelContext)
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
}
