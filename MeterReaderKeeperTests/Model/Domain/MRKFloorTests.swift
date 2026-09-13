//
//  MRKFloorTests.swift
//  MeterReaderKeeperTests
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/Domain/MRKFloor.swift`, which declares both
/// `MRKFloor` and `MRKFloorInput` — this file tests both. Neither type
/// declares a `validate()` method (unlike Building/Meter/Reading), so
/// there's genuinely less to cover here.
@Suite("MRKFloor")
struct MRKFloorTests {

    private func makeMeter(name: String) -> MRKMeter {
        MRKMeter(
            id: UUID(), name: name, meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: []
        )
    }

    @Test("displayName includes the floor number")
    func displayNameIncludesFloorNumber() {
        let floor = MRKFloor(id: UUID(), number: 7, mapImageData: Data(), buildingID: UUID(), meters: [])
        #expect(floor.displayName == "Floor 7")
    }

    @Test("sortedMeters orders by name regardless of input order")
    func sortedMetersOrdersByNameRegardlessOfInputOrder() {
        let floor = MRKFloor(id: UUID(), number: 1, mapImageData: Data(), buildingID: UUID(), meters: [
            makeMeter(name: "Charlie"),
            makeMeter(name: "Alpha"),
            makeMeter(name: "Bravo")
        ])

        #expect(floor.sortedMeters.map { $0.name } == ["Alpha", "Bravo", "Charlie"])
    }
}

@Suite("MRKFloorInput")
struct MRKFloorInputTests {

    @Test("stores values verbatim")
    func storesValuesVerbatim() {
        let buildingID = UUID()
        let mapData = Data([0x01, 0x02])
        let input = MRKFloorInput(number: 3, mapImageData: mapData, buildingID: buildingID)

        #expect(input.number == 3)
        #expect(input.mapImageData == mapData)
        #expect(input.buildingID == buildingID)
    }
}
