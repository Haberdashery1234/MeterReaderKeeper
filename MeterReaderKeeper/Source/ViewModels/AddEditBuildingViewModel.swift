//
//  AddEditBuildingViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//  Converted to async/await + @MainActor on 8/27/26.
//

import Foundation

/// Business logic and repository access for the Add/Edit Building screen.
/// Validation, duplicate-name checking, and the save/delete calls into the
/// repository all live here; the view controller owns only layout and
/// presenting the alerts this type's thrown errors describe.
@MainActor
final class AddEditBuildingViewModel {

    private enum Validation {
        static let maxBuildingNameLength = 100
        static let minFloorCount: Int16 = 1
        static let maxFloorCount: Int16 = 200
    }

    private let repository: MeterRepositoryProtocol

    /// The building being edited, or `nil` when adding a new one.
    let building: MRKBuilding?

    /// Creates the Add/Edit Building view model.
    ///
    /// - Parameters:
    ///   - repository: The repository to save to.
    ///   - building: The building to edit, or `nil` to add a new one.
    init(repository: MeterRepositoryProtocol, building: MRKBuilding?) {
        self.repository = repository
        self.building = building
    }

    // MARK: - Display

    /// Whether this screen is editing an existing building (vs. adding one).
    var isEditing: Bool { building != nil }

    /// The navigation title to show.
    var screenTitle: String { isEditing ? "Edit Building" : "Add Building" }

    /// The name field's initial text, or `nil` when adding.
    var initialNameText: String? { building?.name }

    /// The floor-count field's initial text, or `nil` when adding.
    var initialFloorsText: String? {
        guard let building = building else { return nil }
        return "\(building.floors.count)"
    }

    /// Floor count is editable both when adding and editing a building —
    /// floors are added or removed by editing this count, rather than
    /// through separate add/remove actions (2026-08-28). Renaming an
    /// existing building is still not supported — see
    /// `save(nameText:floorsText:)`.
    var isFloorsFieldEnabled: Bool { true }

    // MARK: - Validation

    /// Parses and checks the form's raw text fields.
    ///
    /// - Throws: `FormValidationError` describing the first failing rule
    ///   (empty/too-long name, or an out-of-range floor count).
    /// - Returns: The trimmed name and parsed floor count.
    private func validate(nameText: String?, floorsText: String?) throws -> (name: String, floors: Int16) {
        guard let nameText = nameText?.trimmingCharacters(in: .whitespacesAndNewlines), !nameText.isEmpty else {
            throw FormValidationError(title: "Invalid Name", message: "Please enter a building name.")
        }

        guard nameText.count <= Validation.maxBuildingNameLength else {
            throw FormValidationError(
                title: "Name Too Long",
                message: "Building name must be \(Validation.maxBuildingNameLength) characters or less."
            )
        }

        guard let floorsText = floorsText, let floorsInt = Int16(floorsText) else {
            throw FormValidationError(title: "Invalid Floor Count", message: "Please enter a valid number of floors.")
        }

        guard floorsInt >= Validation.minFloorCount else {
            throw FormValidationError(
                title: "Invalid Floor Count",
                message: "Building must have at least \(Validation.minFloorCount) floor."
            )
        }

        guard floorsInt <= Validation.maxFloorCount else {
            throw FormValidationError(
                title: "Too Many Floors",
                message: "Building cannot have more than \(Validation.maxFloorCount) floors."
            )
        }

        return (nameText, floorsInt)
    }

    /// Whether another building already has `name` (case-insensitive).
    private func isDuplicateName(_ name: String) async -> Bool {
        let buildings = (try? await repository.getBuildings()) ?? []
        return buildings.contains { $0.name.lowercased() == name.lowercased() }
    }

    // MARK: - Actions

    /// If the floors text represents a *reduction* in floor count, and any
    /// of the floors that would be removed (always the top/highest-numbered
    /// ones — see `reconcileFloors`) currently have meters on them, returns
    /// a confirmation message describing what would be lost so the view
    /// controller can ask before calling `save`. Returns `nil` when no
    /// confirmation is needed: not editing, not reducing the count, or the
    /// floors being removed are already empty. Doesn't validate
    /// `floorsText` itself — an invalid value just yields `nil` here and
    /// gets caught by `save`'s own validation instead.
    func floorRemovalWarning(floorsText: String?) -> String? {
        guard let building = building,
              let floorsText = floorsText,
              let desiredCount = Int16(floorsText),
              desiredCount >= 0
        else { return nil }

        let currentFloors = building.sortedFloors
        guard desiredCount < currentFloors.count else { return nil }

        let removedFloors = currentFloors.suffix(currentFloors.count - Int(desiredCount))
        let removedMeterCount = removedFloors.reduce(0) { $0 + $1.meters.count }
        guard removedMeterCount > 0 else { return nil }

        let floorWord = removedFloors.count == 1 ? "floor" : "floors"
        let meterWord = removedMeterCount == 1 ? "meter" : "meters"
        return "Reducing the floor count will delete the top \(removedFloors.count) \(floorWord), which will also delete \(removedMeterCount) \(meterWord) and their reading history. This can't be undone."
    }

    /// Validates the form, checks for a duplicate name, and either creates
    /// a new building or (when editing) reconciles the existing building's
    /// floor count to match `floorsText`. Renaming an existing building is
    /// still not supported — that specific case throws a
    /// `FormValidationError`, matching the original screen's behavior for
    /// name changes, but a floor-count-only edit now goes through.
    @discardableResult
    func save(nameText: String?, floorsText: String?) async throws -> MRKBuilding {
        let (name, floors) = try validate(nameText: nameText, floorsText: floorsText)

        if building == nil || building?.name != name {
            if await isDuplicateName(name) {
                throw FormValidationError(
                    title: "Duplicate Name",
                    message: "A building with the name '\(name)' already exists. Please choose a different name."
                )
            }
        }

        guard let building = building else {
            let input = MRKBuildingInput(name: name, numberOfFloors: floors, autoCreateFloors: true)
            return try await repository.addBuilding(input)
        }

        guard building.name == name else {
            throw FormValidationError(
                title: "Renaming Not Supported",
                message: "Renaming an existing building isn't supported yet. You can still change its floor count."
            )
        }

        try await reconcileFloors(building: building, desiredCount: floors)
        return try await repository.getBuilding(id: building.id)
    }

    /// Adds or removes floors so `building` ends up with exactly
    /// `desiredCount` of them. New floors are appended with the next
    /// sequential floor numbers (matching how `addBuilding(autoCreateFloors:)`
    /// numbers them at creation — 1-based, contiguous). Removed floors are
    /// always the top/highest-numbered ones first — any meters and readings
    /// on a removed floor are deleted with it via the repository's existing
    /// cascade-delete rule; `floorRemovalWarning` is how the view
    /// controller warns about that before calling `save` at all.
    private func reconcileFloors(building: MRKBuilding, desiredCount: Int16) async throws {
        let currentFloors = building.sortedFloors
        let currentCount = Int16(currentFloors.count)

        if desiredCount > currentCount {
            for number in (currentCount + 1)...desiredCount {
                _ = try await repository.addFloor(MRKFloorInput(number: number, mapImageData: Data(), buildingID: building.id))
            }
        } else if desiredCount < currentCount {
            let floorsToRemove = currentFloors.suffix(Int(currentCount - desiredCount))
            for floor in floorsToRemove {
                try await repository.deleteFloor(id: floor.id)
            }
        }
    }

    /// Deletes `building` (and everything under it) via the repository.
    /// A no-op when adding a new building (`building == nil`).
    func delete() async throws {
        guard let building = building else {
            print("Delete requested but no building to delete")
            return
        }
        try await repository.deleteBuilding(id: building.id)
        print("Deleted building: \(building.name)")
    }
}
