//
//  MRKBuildingTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/Model/Domain/MRKBuilding.swift`, which declares both
/// `MRKBuilding` and `MRKBuildingInput` — this file tests both, in two
/// separate suites below.
@Suite("MRKBuilding")
struct MRKBuildingTests {

    private func makeFloor(number: Int16, meterCount: Int) -> MRKFloor {
        let meters = (0..<meterCount).map { i in
            MRKMeter(
                id: UUID(), name: "M\(i)", meterDescription: "", qrString: "",
                imageData: Data(), latestReadingDate: .distantPast, floorID: UUID(), readings: []
            )
        }
        return MRKFloor(id: UUID(), number: number, mapImageData: Data(), buildingID: UUID(), meters: meters)
    }

    @Test("totalMeterCount sums across all floors")
    func totalMeterCountSumsAcrossAllFloors() {
        let building = MRKBuilding(id: UUID(), name: "Test", floors: [
            makeFloor(number: 1, meterCount: 3),
            makeFloor(number: 2, meterCount: 5)
        ])

        #expect(building.totalMeterCount == 8)
    }

    @Test("totalMeterCount is zero with no floors")
    func totalMeterCountIsZeroWithNoFloors() {
        let building = MRKBuilding(id: UUID(), name: "Test", floors: [])
        #expect(building.totalMeterCount == 0)
    }

    @Test("sortedFloors orders by number regardless of input order")
    func sortedFloorsOrdersByNumberRegardlessOfInputOrder() {
        let building = MRKBuilding(id: UUID(), name: "Test", floors: [
            makeFloor(number: 3, meterCount: 0),
            makeFloor(number: 1, meterCount: 0),
            makeFloor(number: 2, meterCount: 0)
        ])

        #expect(building.sortedFloors.map { $0.number } == [1, 2, 3])
    }

    @Test("validate rejects a blank name")
    func validateRejectsBlankName() {
        let building = MRKBuilding(id: UUID(), name: "   ", floors: [])
        #expect(throws: (any Error).self) {
            try building.validate()
        }
    }

    @Test("validate accepts a non-empty name")
    func validateAcceptsNonEmptyName() throws {
        let building = MRKBuilding(id: UUID(), name: "121 Seaport", floors: [])
        try building.validate()
    }
}

@Suite("MRKBuildingInput")
struct MRKBuildingInputTests {

    @Test("validate rejects a blank name")
    func validateRejectsBlankName() {
        let input = MRKBuildingInput(name: "  ", numberOfFloors: 5, autoCreateFloors: true)
        #expect(throws: (any Error).self) {
            try input.validate()
        }
    }

    @Test("validate rejects zero floors")
    func validateRejectsZeroFloors() {
        let input = MRKBuildingInput(name: "Test", numberOfFloors: 0, autoCreateFloors: true)
        #expect(throws: (any Error).self) {
            try input.validate()
        }
    }

    @Test("validate rejects more than 200 floors")
    func validateRejectsMoreThan200Floors() {
        let input = MRKBuildingInput(name: "Test", numberOfFloors: 201, autoCreateFloors: true)
        #expect(throws: (any Error).self) {
            try input.validate()
        }
    }

    @Test("validate accepts the boundary floor counts")
    func validateAcceptsBoundaryFloorCounts() throws {
        try MRKBuildingInput(name: "Test", numberOfFloors: 1, autoCreateFloors: true).validate()
        try MRKBuildingInput(name: "Test", numberOfFloors: 200, autoCreateFloors: true).validate()
    }
}
