//
//  FormValidationErrorAssertion.swift
//  MeterReaderKeeperTests
//
//  Created on 8/27/26.
//  Replaces XCTestCase+FormValidationError.swift (deleted) as part of the
//  XCTest -> Swift Testing migration, 8/27/26.
//  Became async on 8/27/26 when every ViewModel's save()/delete() became
//  async throws (see "Proper concurrency" migration note).
//

import Testing
@testable import MeterReaderKeeper

/// Shared by every ViewModel test file whose `save()`/similar methods
/// validate input by throwing `FormValidationError` — asserts an
/// expression throws one, with the expected `title`, in one line instead
/// of a repeated `catch`/`guard let ... as? FormValidationError` in every
/// test.
///
/// A free function rather than an `XCTestCase` extension: Swift Testing
/// suite types don't need to inherit from anything, so there's no shared
/// base type to attach this to the way the XCTest version attached to
/// `XCTestCase`. `sourceLocation` mirrors the old `file`/`line` forwarding
/// — its default (`#_sourceLocation`) captures the caller's location, so a
/// failure reported here still points at the test that called this, not
/// at this function itself.
///
/// The autoclosure is `async throws` (not just `throws`) so callers can
/// pass an `await`-ing expression, e.g.
/// `await assertThrowsFormValidationError(try await viewModel.save(...), title: "...")`.
func assertThrowsFormValidationError<T>(
    _ expression: @autoclosure () async throws -> T,
    title: String,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    do {
        _ = try await expression()
        Issue.record(
            "Expected FormValidationError to be thrown, but no error was thrown",
            sourceLocation: sourceLocation
        )
    } catch let validationError as FormValidationError {
        #expect(validationError.title == title, sourceLocation: sourceLocation)
    } catch {
        Issue.record("Expected FormValidationError, got \(error)", sourceLocation: sourceLocation)
    }
}
