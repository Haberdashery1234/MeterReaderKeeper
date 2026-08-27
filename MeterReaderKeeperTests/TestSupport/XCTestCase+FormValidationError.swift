//
//  XCTestCase+FormValidationError.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//

import XCTest
@testable import MeterReaderKeeper

/// Shared by every ViewModel test file whose `save()`/similar methods
/// validate input by throwing `FormValidationError` — asserts an
/// expression throws one, with the expected `title`, in one line instead
/// of a repeated `guard let ... as? FormValidationError` in every test.
extension XCTestCase {
    func assertThrowsFormValidationError<T>(
        _ expression: @autoclosure () throws -> T,
        title: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard let validationError = error as? FormValidationError else {
                return XCTFail("Expected FormValidationError, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(validationError.title, title, file: file, line: line)
        }
    }
}
