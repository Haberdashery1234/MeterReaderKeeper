//
//  MRKBuildingTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/Domain/MRKBuilding.swift`, which declares both
/// `MRKBuilding` and `MRKBuildingInput` — this file tests both, in two
/// separate `XCTestCase`s below.
final class MRKBuildingTests: XCTestCase {

    private func makeFloor(number: Int16, meterCount: Int) -> MRKFloor {
        let meters = (0..<meterCount).map { i in
            MRKMeter(
                id: UUID(), name: "M\(i)", meterDescription: "", qrString: "",
                imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: []
            )
        }
        return MRKFloor(id: UUID(), number: number, mapImageData: Data(), buildingID: UUID(), meters: meters)
    }

    func testTotalMeterCountSumsAcrossAllFloors() {
        let building = MRKBuilding(id: UUID(), name: "Test", floors: [
            makeFloor(number: 1, meterCount: 3),
            makeFloor(number: 2, meterCount: 5)
        ])

        XCTAssertEqual(building.totalMeterCount, 8)
    }

    func testTotalMeterCountIsZeroWithNoFloors() {
        let building = MRKBuilding(id: UUID(), name: "Test", floors: [])
        XCTAssertEqual(building.totalMeterCount, 0)
    }

    func testSortedFloorsOrdersByNumberRegardlessOfInputOrder() {
        let building = MRKBuilding(id: UUID(), name: "Test", floors: [
            makeFloor(number: 3, meterCount: 0),
            makeFloor(number: 1, meterCount: 0),
            makeFloor(number: 2, meterCount: 0)
        ])

        XCTAssertEqual(building.sortedFloors.map { $0.number }, [1, 2, 3])
    }

    func testValidateRejectsBlankName() {
        let building = MRKBuilding(id: UUID(), name: "   ", floors: [])
        XCTAssertThrowsError(try building.validate())
    }

    func testValidateAcceptsNonEmptyName() {
        let building = MRKBuilding(id: UUID(), name: "121 Seaport", floors: [])
        XCTAssertNoThrow(try building.validate())
    }
}

final class MRKBuildingInputTests: XCTestCase {

    func testValidateRejectsBlankName() {
        let input = MRKBuildingInput(name: "  ", numberOfFloors: 5, autoCreateFloors: true)
        XCTAssertThrowsError(try input.validate())
    }

    func testValidateRejectsZeroFloors() {
        let input = MRKBuildingInput(name: "Test", numberOfFloors: 0, autoCreateFloors: true)
        XCTAssertThrowsError(try input.validate())
    }

    func testValidateRejectsMoreThan200Floors() {
        let input = MRKBuildingInput(name: "Test", numberOfFloors: 201, autoCreateFloors: true)
        XCTAssertThrowsError(try input.validate())
    }

    func testValidateAcceptsBoundaryFloorCounts() {
        XCTAssertNoThrow(try MRKBuildingInput(name: "Test", numberOfFloors: 1, autoCreateFloors: true).validate())
        XCTAssertNoThrow(try MRKBuildingInput(name: "Test", numberOfFloors: 200, autoCreateFloors: true).validate())
    }
}
