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

    /// The meter this reading belongs to.
    let meter: MRKMeter
    /// The meter's floor.
    let floor: MRKFloor
    /// The meter's building.
    let building: MRKBuilding
    /// The reading being edited, or `nil` when adding a new one.
    let reading: MRKReading?

    /// Creates the Add/Edit Reading view model.
    ///
    /// - Parameters:
    ///   - repository: The repository to save to.
    ///   - meter: The meter this reading belongs to.
    ///   - floor: The meter's floor.
    ///   - building: The meter's building.
    ///   - reading: The reading to edit, or `nil` to add a new one.
    init(repository: MeterRepositoryProtocol, meter: MRKMeter, floor: MRKFloor, building: MRKBuilding, reading: MRKReading?) {
        self.repository = repository
        self.meter = meter
        self.floor = floor
        self.building = building
        self.reading = reading
    }

    /// Whether this screen is editing an existing reading (vs. adding one).
    var isEditing: Bool { reading != nil }

    /// The navigation title to show.
    var screenTitle: String { isEditing ? "Edit Reading" : "Add Reading" }

    /// The reading field's initial text, or `nil` when adding.
    var initialReadingText: String? {
        guard let reading = reading else { return nil }
        return String(format: "%.2f", reading.kWh)
    }

    /// Validates the form and creates or updates the reading. Editing an
    /// existing reading re-dates it to today, matching this app's existing
    /// convention (see `MeterRepositoryProtocol.updateReading(id:kWh:)`).
    ///
    /// - Parameter readingText: The reading field's raw text.
    /// - Returns: The saved reading.
    /// - Throws: `FormValidationError` if the text is empty, non-numeric,
    ///   or negative.
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
