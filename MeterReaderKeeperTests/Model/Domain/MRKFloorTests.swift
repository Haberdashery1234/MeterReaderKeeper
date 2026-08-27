//
//  MRKFloorTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/Domain/MRKFloor.swift`, which declares both
/// `MRKFloor` and `MRKFloorInput` — this file tests both. Neither type
/// declares a `validate()` method (unlike Building/Meter/Reading), so
/// there's genuinely less to cover here.
final class MRKFloorTests: XCTestCase {

    private func makeMeter(name: String) -> MRKMeter {
        MRKMeter(
            id: UUID(), name: name, meterDescription: "", qrString: "",
            imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: []
        )
    }

    func testDisplayNameIncludesFloorNumber() {
        let floor = MRKFloor(id: UUID(), number: 7, mapImageData: Data(), buildingID: UUID(), meters: [])
        XCTAssertEqual(floor.displayName, "Floor 7")
    }

    func testSortedMetersOrdersByNameRegardlessOfInputOrder() {
        let floor = MRKFloor(id: UUID(), number: 1, mapImageData: Data(), buildingID: UUID(), meters: [
            makeMeter(name: "Charlie"),
            makeMeter(name: "Alpha"),
            makeMeter(name: "Bravo")
        ])

        XCTAssertEqual(floor.sortedMeters.map { $0.name }, ["Alpha", "Bravo", "Charlie"])
    }
}

final class MRKFloorInputTests: XCTestCase {

    func testStoresValuesVerbatim() {
        let buildingID = UUID()
        let mapData = Data([0x01, 0x02])
        let input = MRKFloorInput(number: 3, mapImageData: mapData, buildingID: buildingID)

        XCTAssertEqual(input.number, 3)
        XCTAssertEqual(input.mapImageData, mapData)
        XCTAssertEqual(input.buildingID, buildingID)
    }
}
