//
//  CoreDataMeterRepository.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation
import CoreData

/// Core Data-backed implementation of `MeterRepositoryProtocol`.
///
/// This is the *only* place in the app (besides the `Model/CoreData` files
/// themselves) that should import `CoreData` or touch the generated
/// `CoreDataBuilding` / `CoreDataFloor` / `CoreDataMeter` / `CoreDataReading`
/// classes directly. Everything above this layer — view controllers, and
/// view models in a later pass — works exclusively with the plain
/// `Building` / `Floor` / `Meter` / `Reading` domain structs in
/// `Model/Domain`.
final class CoreDataMeterRepository: MeterRepositoryProtocol {

    private let persistentContainer: NSPersistentContainer

    /// - Parameter inMemory: pass `true` (e.g. from unit tests) to back the
    ///   store with an in-memory store instead of the real SQLite file on
    ///   disk.
    init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "MeterReader")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            persistentContainer.persistentStoreDescriptions = [description]
        }

        var loadError: Error?
        persistentContainer.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError = loadError {
            // A failed store load leaves the app with nowhere to persist
            // data. This still can't be recovered from in-app, so it remains
            // fatal (as it was before this refactor) — but at least the
            // failure reason is surfaced via the crash log.
            fatalError("Failed to load Core Data stack: \(loadError)")
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Buildings

    func getBuildings() throws -> [MRKBuilding] {
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let request = NSFetchRequest<CoreDataBuilding>(entityName: "CoreDataBuilding")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            let managedBuildings = try context.fetch(request)
            return managedBuildings.map(Self.mapBuilding)
        }
    }

    func addBuilding(_ input: MRKBuildingInput) throws -> MRKBuilding {
        try input.validate()
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let building = CoreDataBuilding(context: context)
            building.name = input.name

            if input.autoCreateFloors {
                for i in 1...input.numberOfFloors {
                    let floor = CoreDataFloor(context: context)
                    floor.building = building
                    floor.number = i
                    floor.map = Data()
                }
            }

            try Self.save(context)
            return Self.mapBuilding(building)
        }
    }

    func deleteBuilding(id: UUID) throws {
        let context = persistentContainer.viewContext
        try context.performAndWaitThrowing {
            let building = try Self.findBuilding(id: id, in: context)
            context.delete(building)
            try Self.save(context)
        }
    }

    // MARK: - Floors

    func addFloor(_ input: MRKFloorInput) throws -> MRKFloor {
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let building = try Self.findBuilding(id: input.buildingID, in: context)

            let floor = CoreDataFloor(context: context)
            floor.building = building
            floor.number = input.number
            floor.map = input.mapImageData

            try Self.save(context)
            return Self.mapFloor(floor)
        }
    }

    func updateFloor(id: UUID, input: MRKFloorInput) throws -> MRKFloor {
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let floor = try Self.findFloor(id: id, in: context)
            let building = try Self.findBuilding(id: input.buildingID, in: context)

            floor.building = building
            floor.number = input.number
            floor.map = input.mapImageData

            try Self.save(context)
            return Self.mapFloor(floor)
        }
    }

    // MARK: - Meters

    func addMeter(_ input: MRKMeterInput) throws -> MRKMeter {
        try input.validate()
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let floor = try Self.findFloor(id: input.floorID, in: context)

            let meter = CoreDataMeter(context: context)
            meter.name = input.name
            meter.meterDescription = input.description
            meter.image = input.imageData
            meter.floor = floor
            meter.qrString = Self.qrString(buildingName: floor.building.name, floorNumber: floor.number, meterName: input.name)
            meter.latestReading = Date.distantPast

            try Self.save(context)
            return Self.mapMeter(meter)
        }
    }

    func updateMeter(id: UUID, input: MRKMeterInput) throws -> MRKMeter {
        try input.validate()
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let meter = try Self.findMeter(id: id, in: context)
            let floor = try Self.findFloor(id: input.floorID, in: context)

            meter.name = input.name
            meter.meterDescription = input.description
            meter.image = input.imageData
            meter.floor = floor
            meter.qrString = Self.qrString(buildingName: floor.building.name, floorNumber: floor.number, meterName: input.name)

            try Self.save(context)
            return Self.mapMeter(meter)
        }
    }

    func deleteMeter(id: UUID) throws {
        let context = persistentContainer.viewContext
        try context.performAndWaitThrowing {
            let meter = try Self.findMeter(id: id, in: context)
            context.delete(meter)
            try Self.save(context)
        }
    }

    // MARK: - Readings

    func addReading(_ input: MRKReadingInput) throws -> MRKReading {
        try input.validate()
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let meter = try Self.findMeter(id: input.meterID, in: context)

            if input.date > meter.latestReading {
                meter.latestReading = input.date
            }

            let reading = CoreDataReading(context: context)
            reading.kWh = input.kWh
            reading.date = input.date
            reading.meter = meter

            try Self.save(context)
            return Self.mapReading(reading)
        }
    }

    func updateReading(id: UUID, kWh: Double) throws -> MRKReading {
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let reading = try Self.findReading(id: id, in: context)
            let date = Calendar.current.startOfDay(for: Date())

            reading.kWh = kWh
            reading.date = date
            reading.meter.latestReading = date

            try Self.save(context)
            return Self.mapReading(reading)
        }
    }

    // MARK: - Export

    func exportAllDataToPlist() throws -> Data {
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let request = NSFetchRequest<CoreDataBuilding>(entityName: "CoreDataBuilding")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            let buildings = try context.fetch(request)

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
        let context = persistentContainer.viewContext
        return try context.performAndWaitThrowing {
            let building = try Self.findBuilding(id: buildingID, in: context)

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

    // MARK: - Mapping: Core Data -> Domain

    private static func mapBuilding(_ managed: CoreDataBuilding) -> MRKBuilding {
        MRKBuilding(
            id: managed.objectID.stableUUID,
            name: managed.name,
            floors: managed.sortedFloors.map(mapFloor)
        )
    }

    private static func mapFloor(_ managed: CoreDataFloor) -> MRKFloor {
        MRKFloor(
            id: managed.objectID.stableUUID,
            number: managed.number,
            mapImageData: managed.map,
            buildingID: managed.building.objectID.stableUUID,
            meters: managed.sortedMeters.map(mapMeter)
        )
    }

    private static func mapMeter(_ managed: CoreDataMeter) -> MRKMeter {
        MRKMeter(
            id: managed.objectID.stableUUID,
            name: managed.name,
            meterDescription: managed.meterDescription,
            qrString: managed.qrString,
            imageData: managed.image,
            latestReadingDate: managed.latestReading,
            floorID: managed.floor.objectID.stableUUID,
            readings: managed.sortedReadings.map(mapReading)
        )
    }

    private static func mapReading(_ managed: CoreDataReading) -> MRKReading {
        MRKReading(
            id: managed.objectID.stableUUID,
            date: managed.date,
            kWh: managed.kWh,
            meterID: managed.meter.objectID.stableUUID
        )
    }

    // MARK: - Lookup helpers

    // Core Data entities don't carry a persisted UUID; identity for the
    // public repository API is derived from each object's stable
    // `NSManagedObjectID` (see `NSManagedObjectID+StableUUID.swift`). These
    // helpers resolve a domain UUID back to its managed object by fetching
    // every instance of that entity and comparing derived UUIDs. That's an
    // O(n) fetch-and-scan per lookup — acceptable for this app's realistic
    // data volumes, but a good reason to add a real persisted `id` attribute
    // to the Core Data model (an additive, lightweight-migratable change) if
    // the data set ever grows large enough for it to matter.

    private static func findBuilding(id: UUID, in context: NSManagedObjectContext) throws -> CoreDataBuilding {
        let request = NSFetchRequest<CoreDataBuilding>(entityName: "CoreDataBuilding")
        let all = try context.fetch(request)
        guard let match = all.first(where: { $0.objectID.stableUUID == id }) else {
            throw MeterKeeperError.notFound("Building")
        }
        return match
    }

    private static func findFloor(id: UUID, in context: NSManagedObjectContext) throws -> CoreDataFloor {
        let request = NSFetchRequest<CoreDataFloor>(entityName: "CoreDataFloor")
        let all = try context.fetch(request)
        guard let match = all.first(where: { $0.objectID.stableUUID == id }) else {
            throw MeterKeeperError.notFound("Floor")
        }
        return match
    }

    private static func findMeter(id: UUID, in context: NSManagedObjectContext) throws -> CoreDataMeter {
        let request = NSFetchRequest<CoreDataMeter>(entityName: "CoreDataMeter")
        let all = try context.fetch(request)
        guard let match = all.first(where: { $0.objectID.stableUUID == id }) else {
            throw MeterKeeperError.notFound("Meter")
        }
        return match
    }

    private static func findReading(id: UUID, in context: NSManagedObjectContext) throws -> CoreDataReading {
        let request = NSFetchRequest<CoreDataReading>(entityName: "CoreDataReading")
        let all = try context.fetch(request)
        guard let match = all.first(where: { $0.objectID.stableUUID == id }) else {
            throw MeterKeeperError.notFound("Reading")
        }
        return match
    }

    // MARK: - Small helpers

    private static func qrString(buildingName: String, floorNumber: Int16, meterName: String) -> String {
        "\(buildingName)::\(floorNumber)::\(meterName)"
    }

    private static func save(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw MeterKeeperError.coreDataError(error)
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

// MARK: - Bridging performAndWait to throwing/return-value calls

private extension NSManagedObjectContext {
    /// `NSManagedObjectContext.performAndWait` is synchronous but (on our
    /// iOS 14.1 deployment target) only offers a non-throwing, no-return-value
    /// signature. This bridges that to a throwing call that returns a value,
    /// without depending on the newer generic `performAndWait<T>` overload
    /// Apple added alongside Core Data's async/await support (which may not
    /// be available at our deployment target).
    func performAndWaitThrowing<T>(_ block: () throws -> T) throws -> T {
        var result: Result<T, Error>!
        performAndWait {
            result = Result { try block() }
        }
        return try result.get()
    }
}
