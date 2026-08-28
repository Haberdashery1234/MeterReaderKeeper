//
//  AddEditReadingViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//  Converted to async/await + @MainActor on 8/27/26.
//

import Foundation

/// Business logic and repository access for the Add/Edit Reading screen.
///
/// The meter/floor/building context is always supplied by the coordinator
/// (see `AppCoordinator.showAddReading`/`showEditReading`), so unlike the
/// original view controller — which stored them as optionals and bailed
/// out with a logged error if they were missing — this type takes them as
/// required `init` parameters and that failure mode can't occur.
@MainActor
final class AddEditReadingViewModel {

    private let repository: MeterRepositoryProtocol

    let meter: MRKMeter
    let floor: MRKFloor
    let building: MRKBuilding
    let reading: MRKReading?

    init(repository: MeterRepositoryProtocol, meter: MRKMeter, floor: MRKFloor, building: MRKBuilding, reading: MRKReading?) {
        self.repository = repository
        self.meter = meter
        self.floor = floor
        self.building = building
        self.reading = reading
    }

    var isEditing: Bool { reading != nil }

    var screenTitle: String { isEditing ? "Edit Reading" : "Add Reading" }

    var initialReadingText: String? {
        guard let reading = reading else { return nil }
        return String(format: "%.2f", reading.kWh)
    }

    @discardableResult
    func save(readingText: String?) async throws -> MRKReading {
        guard let text = readingText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw FormValidationError(title: "Missing Reading", message: "Please enter a reading value.")
        }

        guard let value = Double(text) else {
            throw FormValidationError(title: "Invalid Reading", message: "Please enter a valid numeric value.")
        }

        guard value >= 0 else {
            throw FormValidationError(title: "Invalid Reading", message: "Reading value must be positive.")
        }

        let saved: MRKReading
        if let reading = reading {
            saved = try await repository.updateReading(id: reading.id, kWh: value)
        } else {
            let date = Calendar.current.startOfDay(for: Date())
            let input = MRKReadingInput(kWh: value, date: date, meterID: meter.id)
            saved = try await repository.addReading(input)
        }
        return saved
    }
}
