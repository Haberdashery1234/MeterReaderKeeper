//
//  AddEditBuildingViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//

import Foundation
import os.log

/// Business logic and repository access for the Add/Edit Building screen.
/// Validation, duplicate-name checking, and the save/delete calls into the
/// repository all live here; the view controller owns only layout and
/// presenting the alerts this type's thrown errors describe.
final class AddEditBuildingViewModel {

    private enum Validation {
        static let maxBuildingNameLength = 100
        static let minFloorCount: Int16 = 1
        static let maxFloorCount: Int16 = 200
    }

    private let repository: MeterRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "AddEditBuildingViewModel")

    /// The building being edited, or `nil` when adding a new one.
    let building: MRKBuilding?

    init(repository: MeterRepositoryProtocol, building: MRKBuilding?) {
        self.repository = repository
        self.building = building
    }

    // MARK: - Display

    var isEditing: Bool { building != nil }

    var screenTitle: String { isEditing ? "Edit Building" : "Add Building" }

    var initialNameText: String? { building?.name }

    var initialFloorsText: String? {
        guard let building = building else { return nil }
        return "\(building.floors.count)"
    }

    /// Floor count can't be changed on an existing building.
    var isFloorsFieldEnabled: Bool { !isEditing }

    // MARK: - Validation

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

    private func isDuplicateName(_ name: String) -> Bool {
        let buildings = (try? repository.getBuildings()) ?? []
        return buildings.contains { $0.name.lowercased() == name.lowercased() }
    }

    // MARK: - Actions

    /// Validates the form, checks for a duplicate name, and creates the
    /// building. Editing an existing building isn't supported yet — that
    /// case throws a `FormValidationError` describing the limitation,
    /// matching the original screen's behavior exactly.
    @discardableResult
    func save(nameText: String?, floorsText: String?) throws -> MRKBuilding {
        let (name, floors) = try validate(nameText: nameText, floorsText: floorsText)

        if building == nil || building?.name != name {
            if isDuplicateName(name) {
                throw FormValidationError(
                    title: "Duplicate Name",
                    message: "A building with the name '\(name)' already exists. Please choose a different name."
                )
            }
        }

        if building != nil {
            logger.warning("Editing buildings not yet implemented - creating new building instead")
            throw FormValidationError(
                title: "Not Implemented",
                message: "Editing existing buildings is not yet supported. Please delete and recreate the building."
            )
        }

        let input = MRKBuildingInput(name: name, numberOfFloors: floors, autoCreateFloors: true)
        let newBuilding = try repository.addBuilding(input)
        logger.info("Successfully created building: \(newBuilding.name)")
        return newBuilding
    }

    func delete() throws {
        guard let building = building else {
            logger.warning("Delete requested but no building to delete")
            return
        }
        try repository.deleteBuilding(id: building.id)
        logger.info("Deleted building: \(building.name)")
    }
}
