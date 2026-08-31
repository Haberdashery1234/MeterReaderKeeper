//
//  SwiftDataMeterRepository.swift
//  MeterReaderKeeper
//
//  Migrated to SwiftData on 8/26/26.
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
/// `Model/Domain`.
///
/// ## Threading design
///
/// This type is a real `ModelActor` (via the `@ModelActor` macro) — Apple's
/// documented pattern for SwiftData background access. The macro
/// synthesizes a `ModelContext` confined to this actor's own serial
/// executor, exposed as the `modelContext` property every method below
/// uses. Every method here is declared `async throws` explicitly, matching
/// `MeterRepositoryProtocol`'s requirements and Apple's own `ModelActor`
/// sample code — even though each method's body is internally synchronous,
/// spelling out `async` on the witness avoids a "crosses into actor-isolated
/// code and can cause data races" diagnostic that an isolated-but-implicitly-
/// async witness can trigger under stricter concurrency checking. The
/// conformance clause also opts the protocol in via `@preconcurrency`
/// (`actor SwiftDataMeterRepository: @preconcurrency MeterRepositoryProtocol`)
/// as a second safety net against the same diagnostic class.
///
/// This replaces an earlier version of this type that manually confined a
/// single `ModelContext` to a private serial `DispatchQueue` and ran every
/// operation via `queue.sync`, to preserve a synchronous protocol contract.
/// That queue-confinement trick worked in principle but wasn't the
/// officially blessed approach and was never verified against a real
/// SwiftData stack. Adopting `ModelActor` directly removes the need to
/// guess — at the cost of every call site (every ViewModel, and through
/// them every View) now being `async` too, a ripple the original migration
/// deliberately avoided and this one accepts in full.
@ModelActor
actor SwiftDataMeterRepository: @preconcurrency MeterRepositoryProtocol {

    /// - Parameter inMemory: pass `true` (e.g. from unit tests) to back the
    ///   store with an in-memory store instead of the real SQLite file on
    ///   disk.
    ///
    /// This does **not** delegate to the `init(modelContainer:)` the
    /// `@ModelActor` macro synthesizes. A synchronous, non-`async`
    /// *delegating* actor initializer (one that calls `self.init(...)`) is
    /// nonisolated for its entire body, including every statement after the
    /// delegating call — so touching the actor-isolated `modelContext`
    /// property anywhere in this initializer, even after
    /// `self.init(modelContainer:)` returns, fails to compile ("Actor-isolated
    /// property 'modelContext' can not be referenced from a nonisolated
    /// context"). That's true whether `modelContext` is accessed directly or
    /// through a local `let` copy of it — the isolation check is on the
    /// property access itself, not on what you do with the value afterward.
    ///
    /// Instead, this initializer directly assigns the two properties the
    /// macro's own synthesized `init(modelContainer:)` assigns —
    /// `modelContainer` and `modelExecutor` (`modelContext` itself is a
    /// *computed* property derived from `modelExecutor.modelContext`, never
    /// a stored one, so it's never assigned directly by either version of
    /// this initializer). Because this makes the initializer a genuine
    /// designated (non-delegating) init, disabling autosave on a plain local
    /// `ModelContext` *before* wrapping it into `modelExecutor` sidesteps
    /// actor isolation entirely — that local `context` variable isn't
    /// actor-isolated storage yet, so mutating it is legal from anywhere,
    /// including this nonisolated initializer. This still matches the
    /// original repository's philosophy of saving exactly when
    /// `Self.save(context)` is called, never implicitly. This stays a plain,
    /// non-`async` initializer, so constructing this actor
    /// (`SwiftDataMeterRepository()` / `SwiftDataMeterRepository(inMemory: true)`)
    /// remains a normal synchronous call from anywhere, same as before.
    init(inMemory: Bool = false) {
        let schema = Schema([SDBuilding.self, SDFloor.self, SDMeter.self, SDReading.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A failed store load leaves the app with nowhere to persist
            // data. This still can't be recovered from in-app, so it remains
            // fatal — but at least the failure reason is surfaced via the
            // crash log.
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }

        // Disable autosave on the context *before* it's actor-isolated —
        // see the doc comment above for why this can't be done after
        // delegating to the macro-synthesized init(modelContainer:).
        let context = ModelContext(container)
        context.autosaveEnabled = false

        self.modelContainer = container
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    // MARK: - Buildings

    func getBuildings() async throws -> [MRKBuilding] {
        let descriptor = FetchDescriptor<SDBuilding>(sortBy: [SortDescriptor(\.name, order: .forward)])
        let managedBuildings = try modelContext.fetch(descriptor)
        return managedBuildings.map(Self.mapBuilding)
    }

    func getBuilding(id: UUID) async throws -> MRKBuilding {
        let building = try Self.findBuilding(id: id, in: modelContext)
        return Self.mapBuilding(building)
    }

    func addBuilding(_ input: MRKBuildingInput) async throws -> MRKBuilding {
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

    func deleteBuilding(id: UUID) async throws {
        let building = try Self.findBuilding(id: id, in: modelContext)
        modelContext.delete(building)
        try Self.save(modelContext)
    }

    // MARK: - Floors

    func addFloor(_ input: MRKFloorInput) async throws -> MRKFloor {
        let building = try Self.findBuilding(id: input.buildingID, in: modelContext)

        let floor = SDFloor(number: input.number, mapImageData: input.mapImageData, building: building)
        modelContext.insert(floor)

        try Self.save(modelContext)
        return Self.mapFloor(floor)
    }

    func updateFloor(id: UUID, input: MRKFloorInput) async throws -> MRKFloor {
        let floor = try Self.findFloor(id: id, in: modelContext)
        let building = try Self.findBuilding(id: input.buildingID, in: modelContext)

        floor.building = building
        floor.number = input.number
        floor.mapImageData = input.mapImageData

        try Self.save(modelContext)
        return Self.mapFloor(floor)
    }

    func deleteFloor(id: UUID) async throws {
        let floor = try Self.findFloor(id: id, in: modelContext)
        modelContext.delete(floor)
        try Self.save(modelContext)
    }

    // MARK: - Meters

    func addMeter(_ input: MRKMeterInput) async throws -> MRKMeter {
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

    func updateMeter(id: UUID, input: MRKMeterInput) async throws -> MRKMeter {
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

    func deleteMeter(id: UUID) async throws {
        let meter = try Self.findMeter(id: id, in: modelContext)
        modelContext.delete(meter)
        try Self.save(modelContext)
    }

    // MARK: - Readings

    func addReading(_ input: MRKReadingInput) async throws -> MRKReading {
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

    func updateReading(id: UUID, kWh: Double) async throws -> MRKReading {
        let reading = try Self.findReading(id: id, in: modelContext)
        let date = Calendar.current.startOfDay(for: Date())

        reading.kWh = kWh
        reading.date = date
        reading.meter?.latestReading = date

        try Self.save(modelContext)
        return Self.mapReading(reading)
    }

    // MARK: - Export

    func exportAllDataToPlist() async throws -> Data {
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

    func getCSVData(forBuilding buildingID: UUID) async throws -> Data {
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
    // Each of these converts one `@Model` class into its persistence-agnostic
    // `MRKXxx` counterpart, recursively mapping (and sorting) its children.

    /// Converts a managed building into its domain struct, with its floors
    /// mapped and sorted by number.
    private static func mapBuilding(_ managed: SDBuilding) -> MRKBuilding {
        MRKBuilding(
            id: managed.id,
            name: managed.name,
            floors: managed.floors.sorted { $0.number < $1.number }.map(mapFloor)
        )
    }

    /// Converts a managed floor into its domain struct, with its meters
    /// mapped and sorted by name.
    private static func mapFloor(_ managed: SDFloor) -> MRKFloor {
        MRKFloor(
            id: managed.id,
            number: managed.number,
            mapImageData: managed.mapImageData,
            buildingID: managed.building?.id ?? UUID(),
            meters: managed.meters.sorted { $0.name < $1.name }.map(mapMeter)
        )
    }

    /// Converts a managed meter into its domain struct, with its readings
    /// mapped and sorted most-recent-first.
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

    /// Converts a managed reading into its domain struct.
    private static func mapReading(_ managed: SDReading) -> MRKReading {
        MRKReading(
            id: managed.id,
            date: managed.date,
            kWh: managed.kWh,
            meterID: managed.meter?.id ?? UUID()
        )
    }

    // MARK: - Lookup helpers

    // These are real indexed-by-id lookups (`#Predicate` fetches) rather
    // than a fetch-everything-and-scan — the payoff of giving each entity a
    // real persisted `id: UUID` instead of deriving one from an object
    // identifier.

    /// Looks up a building by id via an indexed `#Predicate` fetch.
    ///
    /// - Throws: `MeterKeeperError.notFound("Building")` if no match exists.
    private static func findBuilding(id: UUID, in context: ModelContext) throws -> SDBuilding {
        var descriptor = FetchDescriptor<SDBuilding>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let match = try context.fetch(descriptor).first else {
            throw MeterKeeperError.notFound("Building")
        }
        return match
    }

    /// Looks up a floor by id via an indexed `#Predicate` fetch.
    ///
    /// - Throws: `MeterKeeperError.notFound("Floor")` if no match exists.
    private static func findFloor(id: UUID, in context: ModelContext) throws -> SDFloor {
        var descriptor = FetchDescriptor<SDFloor>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let match = try context.fetch(descriptor).first else {
            throw MeterKeeperError.notFound("Floor")
        }
        return match
    }

    /// Looks up a meter by id via an indexed `#Predicate` fetch.
    ///
    /// - Throws: `MeterKeeperError.notFound("Meter")` if no match exists.
    private static func findMeter(id: UUID, in context: ModelContext) throws -> SDMeter {
        var descriptor = FetchDescriptor<SDMeter>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let match = try context.fetch(descriptor).first else {
            throw MeterKeeperError.notFound("Meter")
        }
        return match
    }

    /// Looks up a reading by id via an indexed `#Predicate` fetch.
    ///
    /// - Throws: `MeterKeeperError.notFound("Reading")` if no match exists.
    private static func findReading(id: UUID, in context: ModelContext) throws -> SDReading {
        var descriptor = FetchDescriptor<SDReading>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let match = try context.fetch(descriptor).first else {
            throw MeterKeeperError.notFound("Reading")
        }
        return match
    }

    // MARK: - Small helpers

    /// Builds a meter's QR-label string from its location, in the format
    /// consumed by the readings-flow QR scanner to look a meter back up.
    private static func qrString(buildingName: String, floorNumber: Int16, meterName: String) -> String {
        "\(buildingName)::\(floorNumber)::\(meterName)"
    }

    /// Saves `context` if (and only if) it has pending changes, wrapping any
    /// failure as `MeterKeeperError.persistenceError`.
    private static func save(_ context: ModelContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw MeterKeeperError.persistenceError(error)
        }
    }

    /// The on-disk URL the plist export is written to and re-read from.
    ///
    /// - Throws: `MeterKeeperError.fileSystemError` if the app's document
    ///   directory can't be located.
    private static func exportPlistURL() throws -> URL {
        guard let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw MeterKeeperError.fileSystemError(
                NSError(domain: "MeterReaderKeeper", code: -1, userInfo: [NSLocalizedDescriptionKey: "No document directory available"])
            )
        }
        return documentDirectoryURL.appendingPathComponent("exportData.plist", isDirectory: false)
    }
}
