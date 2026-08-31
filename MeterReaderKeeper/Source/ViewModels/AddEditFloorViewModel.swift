//
//  AddEditFloorViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//  Converted to async/await + @MainActor on 8/27/26.
//

import Foundation

/// Business logic and repository access for the Add/Edit Floor screen.
///
/// Owns the building picker's data and the currently selected building
/// (mirroring how the original view controller mutated its own `building`
/// property from the picker delegate), plus validation and the save call.
/// Map image *encoding* (UIImage -> JPEG data) stays in the view controller
/// since `UIImage` is a UIKit type; this type only accepts and hands back
/// raw `Data`.
@MainActor
final class AddEditFloorViewModel {

    private let repository: MeterRepositoryProtocol

    /// The floor being edited, or `nil` when adding a new one.
    let floor: MRKFloor?

    private(set) var buildings: [MRKBuilding] = []
    private(set) var selectedBuilding: MRKBuilding?

    /// Creates the Add/Edit Floor view model.
    ///
    /// - Parameters:
    ///   - repository: The repository to save to.
    ///   - building: The floor's building, if already known (e.g. reached
    ///     via a specific building's Management section). May also end up
    ///     auto-selected by `loadBuildings()` if there's only one building.
    ///   - floor: The floor to edit, or `nil` to add a new one.
    init(repository: MeterRepositoryProtocol, building: MRKBuilding?, floor: MRKFloor?) {
        self.repository = repository
        self.floor = floor
        self.selectedBuilding = building
    }

    // MARK: - Display

    /// Whether this screen is editing an existing floor (vs. adding one).
    var isEditing: Bool { floor != nil }

    /// The navigation title to show.
    var screenTitle: String { isEditing ? "Edit Floor" : "Add Floor" }

    /// The floor-number field's initial text, or `nil` when adding.
    var initialFloorNumberText: String? {
        guard let floor = floor else { return nil }
        return "\(floor.number)"
    }

    /// The floor's existing map image data, or `nil` if there is none (in
    /// which case the View shows its placeholder icon). Covers both the
    /// add case and an edit of a floor that never got a map.
    var initialMapImageData: Data? {
        guard let floor = floor, floor.mapImageData != Data() else { return nil }
        return floor.mapImageData
    }

    // MARK: - Building selection

    /// Loads every building for the picker. If the screen wasn't handed a
    /// building by the coordinator and there's exactly one building in the
    /// app, it's auto-selected — matching the original screen's behavior.
    func loadBuildings() async {
        buildings = (try? await repository.getBuildings()) ?? []
        if selectedBuilding == nil, buildings.count == 1 {
            selectedBuilding = buildings[0]
        }
    }

    /// Selects the building at `row` in `buildings` as the floor's new building.
    ///
    /// - Parameter row: The picker row that was selected.
    /// - Returns: The newly selected building, or `nil` if `row` is out of range.
    @discardableResult
    func selectBuilding(at row: Int) -> MRKBuilding? {
        guard buildings.indices.contains(row) else { return nil }
        let building = buildings[row]
        selectedBuilding = building
        return building
    }

    // MARK: - Save

    /// Validates the form and creates or updates the floor.
    ///
    /// - Parameters:
    ///   - floorNumberText: The floor-number field's raw text.
    ///   - mapImageData: The floor's map image data (already JPEG-encoded
    ///     by the view controller), or empty `Data()` for none.
    /// - Returns: The saved floor.
    /// - Throws: `FormValidationError` if no building is selected or the
    ///   floor number is missing/invalid.
    @discardableResult
    func save(floorNumberText: String?, mapImageData: Data) async throws -> MRKFloor {
        guard let building = selectedBuilding else {
            throw FormValidationError(title: "Missing Building", message: "Please select a building")
        }

        guard let floorText = floorNumberText, let floorNumber = Int16(floorText) else {
            throw FormValidationError(title: "Invalid Floor", message: "Please enter a valid floor number")
        }

        guard floorNumber > 0 else {
            throw FormValidationError(title: "Invalid Floor", message: "Floor number must be greater than 0")
        }

        let input = MRKFloorInput(number: floorNumber, mapImageData: mapImageData, buildingID: building.id)

        let saved: MRKFloor
        if let existingFloor = floor {
            saved = try await repository.updateFloor(id: existingFloor.id, input: input)
        } else {
            saved = try await repository.addFloor(input)
        }

        print("Saved floor \(floorNumber) for building \(building.name)")
        return saved
    }
}
