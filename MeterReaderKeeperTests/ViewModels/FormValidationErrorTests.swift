//
//  FormValidationErrorTests.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Converted from XCTest to Swift Testing on 8/27/26.
//

import Testing
@testable import MeterReaderKeeper

/// Mirrors `Source/ViewModels/FormValidationError.swift`.
@Suite("FormValidationError")
struct FormValidationErrorTests {

    @Test("errorDescription returns the message, not the title")
    func errorDescriptionReturnsMessageNotTitle() {
        let error = FormValidationError(title: "Invalid Name", message: "Please enter a building name.")
        #expect(error.errorDescription == "Please enter a building name.")
    }

    @Test("title and message are stored verbatim")
    func titleAndMessageAreStoredVerbatim() {
        let error = FormValidationError(title: "Some Title", message: "Some message.")
        #expect(error.title == "Some Title")
        #expect(error.message == "Some message.")
    }
}
