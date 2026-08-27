//
//  FormValidationErrorTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/FormValidationError.swift`.
final class FormValidationErrorTests: XCTestCase {

    func testErrorDescriptionReturnsMessageNotTitle() {
        let error = FormValidationError(title: "Invalid Name", message: "Please enter a building name.")
        XCTAssertEqual(error.errorDescription, "Please enter a building name.")
    }

    func testTitleAndMessageAreStoredVerbatim() {
        let error = FormValidationError(title: "Some Title", message: "Some message.")
        XCTAssertEqual(error.title, "Some Title")
        XCTAssertEqual(error.message, "Some message.")
    }
}
