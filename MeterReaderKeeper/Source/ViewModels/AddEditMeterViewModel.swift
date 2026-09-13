//
//  AddEditMeterViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//  Converted to async/await + @MainActor on 8/27/26.
//

import Foundation
import os

/// Business logic and repository access for the Add/Edit Meter screen.
///
/// Owns the cascading building -> floor picker data (selecting a building
/// reloads the floor list and clears the floor selection, matching the
/// original screen), plus validation, save, and delete. Image encoding
/// stays in the view controller since `UIImage` is a UIKit type.
@MainActor
final class AddEditMeterViewModel {

    private let repository: MeterRepositoryProtocol

    /// The meter being edited, or `nil` when adding a new one.
    let meter: MRKMeter?

    private(set) var buildings: [MRKBuilding] = []
    private(set) var floors: [MRKFloor] = []
    private(set) var selectedBuilding: MRKBuilding?
    private(set) var selectedFloor: MRKFloor?

    /// Creates the Add/Edit Meter view model.
    ///
    /// - Parameters:
    ///   - repository: The repository to save to.
    ///   - building: The meter's building, if already known.
    ///   - floor: The meter's floor, if already known (pre-selects it, e.g.
    ///     when reached via `FloorMetersViewController`'s Add button).
    ///   - meter: The meter to edit, or `nil` to add a new one.
    init(repository: MeterRepositoryProtocol, building: MRKBuilding?, floor: MRKFloor?, meter: MRKMeter?) {
        self.repository = repository
        self.meter = meter
        self.selectedBuilding = building
        self.selectedFloor = floor
    }

    // MARK: - Display

    /// Whether this screen is editing an existing meter (vs. adding one).
    var isEditing: Bool { meter != nil }

    /// The navigation title to show.
    var screenTitle: String { isEditing ? "Edit Meter" : "Add Meter" }

    /// The name field's initial text, or `nil` when adding.
    var initialNameText: String? { meter?.name }

    /// The description field's initial text, or `nil` when adding.
    var initialDescriptionText: String? { meter?.meterDescription }

    /// The floor field's initial display text, or `nil` when no floor is selected.
    var initialFloorText: String? {
        guard let floor = selectedFloor else { return nil }
        return "Floor \(floor.number)"
    }

    /// The meter's existing image data, or `nil` if there is none (in
    /// which case the View shows its placeholder icon).
    var initialImageData: Data? {
        guard let meter = meter, meter.imageData != Data() else { return nil }
        return meter.imageData
    }

    // MARK: - Building / Floor selection

    /// Loads buildings (auto-selecting if there's only one, matching the
    /// original screen), then the floor list for whichever building ends
    /// up selected.
    func loadBuildingsAndFloors() async {
        buildings = (try? await repository.getBuildings()) ?? []

        if selectedBuilding == nil, buildings.count == 1 {
            selectedBuilding = buildings[0]
        }

        floors = selectedBuilding?.sortedFloors ?? []
    }

    /// Selects the building at `row` in `buildings`, reloading `floors` for
    /// it and clearing any previously selected floor.
    ///
    /// - Parameter row: The picker row that was selected.
    /// - Returns: The newly selected building, or `nil` if `row` is out of range.
    @discardableResult
    func selectBuilding(at row: Int) -> MRKBuilding? {
        guard buildings.indices.contains(row) else { return nil }
        let building = buildings[row]
        selectedBuilding = building
        floors = building.sortedFloors
        selectedFloor = nil
        AppLogger.viewModel.debug("Building selected: \(building.name, privacy: .public)")
        return building
    }

    /// Selects the floor at `row` in `floors` as the meter's new floor.
    ///
    /// - Parameter row: The picker row that was selected.
    /// - Returns: The newly selected floor, or `nil` if `row` is out of range.
    @discardableResult
    func selectFloor(at row: Int) -> MRKFloor? {
        guard floors.indices.contains(row) else { return nil }
        let floor = floors[row]
        selectedFloor = floor
        AppLogger.viewModel.debug("Floor selected: \(floor.number)")
        return floor
    }

    /// Clears the building selection, and cascades to clear the floor
    /// list/selection too (matching `selectBuilding(at:)`'s own
    /// behavior when a *real* building is picked) — used by the
    /// Add/Edit Meter picker's "Select Building" placeholder row.
    /// Added 2026-09-02, see "UI test flakiness, root cause: picker
    /// default row never fires didSelectRow (2026-09-02)" in project
    /// memory.
    func clearBuildingSelection() {
        selectedBuilding = nil
        floors = []
        selectedFloor = nil
    }

    /// Clears the floor selection — used by the Add/Edit Meter picker's
    /// "Select Floor" placeholder row. Added 2026-09-02, see
    /// "UI test flakiness, root cause: picker default row never fires
    /// didSelectRow (2026-09-02)" in project memory.
    func clearFloorSelection() {
        selectedFloor = nil
    }

    // MARK: - Validation

    /// Parses and checks the form's raw text fields and current selection.
    ///
    /// - Throws: `FormValidationError` if no building/floor is selected or
    ///   the name is empty.
    /// - Returns: The selected floor, the trimmed name, and the trimmed
    ///   description (empty string if none entered).
    private func validate(nameText: String?, descriptionText: String?) throws -> (floor: MRKFloor, name: String, description: String) {
        guard selectedBuilding != nil else {
            throw FormValidationError(title: "Missing Building", message: "Please select a building")
        }

        guard let floor = selectedFloor else {
            throw FormValidationError(title: "Missing Floor", message: "Please select a floor")
        }

        guard let name = nameText?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            throw FormValidationError(title: "Missing Name", message: "Please enter a meter name")
        }

        let description = descriptionText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return (floor, name, description)
    }

    // MARK: - Actions

    /// Validates the form and creates or updates the meter.
    ///
    /// - Parameters:
    ///   - nameText: The name field's raw text.
    ///   - descriptionText: The description field's raw text.
    ///   - imageData: The meter's photo data (already JPEG-encoded by the
    ///     view controller), or empty `Data()` for none.
    /// - Returns: The saved meter.
    /// - Throws: `FormValidationError` per `validate(nameText:descriptionText:)`.
    @discardableResult
    func save(nameText: String?, descriptionText: String?, imageData: Data) async throws -> MRKMeter {
        let (floor, name, description) = try validate(nameText: nameText, descriptionText: descriptionText)

        if await isDuplicateName(name, on: floor) {
            throw FormValidationError(
                title: "Duplicate Name",
                message: "A meter named '\(name)' already exists on this floor. Please choose a different name."
            )
        }

        let input = MRKMeterInput(name: name, description: description, imageData: imageData, floorID: floor.id)

        let saved: MRKMeter
        if let existingMeter = meter {
            saved = try await repository.updateMeter(id: existingMeter.id, input: input)
            AppLogger.viewModel.debug("Updated meter: \(name, privacy: .public)")
        } else {
            saved = try await repository.addMeter(input)
            AppLogger.viewModel.debug("Created meter: \(name, privacy: .public)")
        }
        return saved
    }

    /// Whether another meter on `floor` already has `name`
    /// (case-insensitive). Excludes the meter being edited (if any).
    /// Re-fetches the floor's meters from the repository rather than
    /// trusting the (possibly stale) `floor` instance handed to `save`,
    /// matching `AddEditBuildingViewModel.isDuplicateName`'s freshness
    /// approach.
    private func isDuplicateName(_ name: String, on floor: MRKFloor) async -> Bool {
        let currentMeters = (try? await repository.getBuilding(id: floor.buildingID))?
            .floors.first { $0.id == floor.id }?.meters ?? floor.meters
        return currentMeters.contains { $0.name.lowercased() == name.lowercased() && $0.id != meter?.id }
    }

    /// Deletes `meter` (and its reading history) via the repository. A
    /// no-op when adding a new meter (`meter == nil`).
    func delete() async throws {
        guard let meter = meter else {
            AppLogger.viewModel.warning("Delete requested but no meter to delete")
            return
        }
        try await repository.deleteMeter(id: meter.id)
        AppLogger.viewModel.debug("Deleted meter: \(meter.name, privacy: .public)")
    }
}
