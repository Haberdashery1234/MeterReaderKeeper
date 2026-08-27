//
//  AddEditFloorViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
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
final class AddEditFloorViewModel {

    private let repository: MeterRepositoryProtocol

    /// The floor being edited, or `nil` when adding a new one.
    let floor: MRKFloor?

    private(set) var buildings: [MRKBuilding] = []
    private(set) var selectedBuilding: MRKBuilding?

    init(repository: MeterRepositoryProtocol, building: MRKBuilding?, floor: MRKFloor?) {
        self.repository = repository
        self.floor = floor
        self.selectedBuilding = building
    }

    // MARK: - Display

    var isEditing: Bool { floor != nil }

    var screenTitle: String { isEditing ? "Edit Floor" : "Add Floor" }

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
    func loadBuildings() {
        buildings = (try? repository.getBuildings()) ?? []
        if selectedBuilding == nil, buildings.count == 1 {
            selectedBuilding = buildings[0]
        }
    }

    @discardableResult
    func selectBuilding(at row: Int) -> MRKBuilding? {
        guard buildings.indices.contains(row) else { return nil }
        let building = buildings[row]
        selectedBuilding = building
        return building
    }

    // MARK: - Save

    @discardableResult
    func save(floorNumberText: String?, mapImageData: Data) throws -> MRKFloor {
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
            saved = try repository.updateFloor(id: existingFloor.id, input: input)
        } else {
            saved = try repository.addFloor(input)
        }

        print("Saved floor \(floorNumber) for building \(building.name)")
        return saved
    }
}
