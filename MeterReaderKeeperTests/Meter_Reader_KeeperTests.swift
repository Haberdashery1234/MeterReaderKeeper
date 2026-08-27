//
//  Meter_Reader_KeeperTests.swift
//  MeterReaderKeeperTests
//
//  Created by Christian Grise on 4/30/21.
//  Fixed stale module import + replaced Xcode boilerplate on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

final class Meter_Reader_KeeperTests: XCTestCase {

    func testInMemoryRepositoryStartsEmpty() throws {
        let repository = SwiftDataMeterRepository(inMemory: true)
        XCTAssertEqual(try repository.getBuildings().count, 0)
    }
}
