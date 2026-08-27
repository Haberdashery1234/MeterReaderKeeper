//
//  AddEditMeterViewModel.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//

import Foundation

/// Business logic and repository access for the Add/Edit Meter screen.
///
/// Owns the cascading building -> floor picker data (selecting a building
/// reloads the floor list and clears the floor selection, matching the
/// original screen), plus validation, save, and delete. Image encoding
/// stays in the view controller since `UIImage` is a UIKit type.
final class AddEditMeterViewModel {

    private let repository: MeterRepositoryProtocol

    /// The meter being edited, or `nil` when adding a new one.
    let meter: MRKMeter?

    private(set) var buildings: [MRKBuilding] = []
    private(set) var floors: [MRKFloor] = []
    private(set) var selectedBuilding: MRKBuilding?
    private(set) var selectedFloor: MRKFloor?

    init(repository: MeterRepositoryProtocol, building: MRKBuilding?, floor: MRKFloor?, meter: MRKMeter?) {
        self.repository = repository
        self.meter = meter
        self.selectedBuilding = building
        self.selectedFloor = floor
    }

    // MARK: - Display

    var isEditing: Bool { meter != nil }

    var screenTitle: String { isEditing ? "Edit Meter" : "Add Meter" }

    var initialNameText: String? { meter?.name }

    var initialDescriptionText: String? { meter?.meterDescription }

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
    func loadBuildingsAndFloors() {
        buildings = (try? repository.getBuildings()) ?? []

        if selectedBuilding == nil, buildings.count == 1 {
            selectedBuilding = buildings[0]
        }

        floors = selectedBuilding?.sortedFloors ?? []
    }

    @discardableResult
    func selectBuilding(at row: Int) -> MRKBuilding? {
        guard buildings.indices.contains(row) else { return nil }
        let building = buildings[row]
        selectedBuilding = building
        floors = building.sortedFloors
        selectedFloor = nil
        print("Building selected: \(building.name)")
        return building
    }

    @discardableResult
    func selectFloor(at row: Int) -> MRKFloor? {
        guard floors.indices.contains(row) else { return nil }
        let floor = floors[row]
        selectedFloor = floor
        print("Floor selected: \(floor.number)")
        return floor
    }

    // MARK: - Validation

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

    @discardableResult
    func save(nameText: String?, descriptionText: String?, imageData: Data) throws -> MRKMeter {
        let (floor, name, description) = try validate(nameText: nameText, descriptionText: descriptionText)

        let input = MRKMeterInput(name: name, description: description, imageData: imageData, floorID: floor.id)

        let saved: MRKMeter
        if let existingMeter = meter {
            saved = try repository.updateMeter(id: existingMeter.id, input: input)
            print("Updated meter: \(name)")
        } else {
            saved = try repository.addMeter(input)
            print("Created meter: \(name)")
        }
        return saved
    }

    func delete() throws {
        guard let meter = meter else {
            print("Delete requested but no meter to delete")
            return
        }
        try repository.deleteMeter(id: meter.id)
        print("Deleted meter: \(meter.name)")
    }
}
