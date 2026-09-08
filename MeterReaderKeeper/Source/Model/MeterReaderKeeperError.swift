//
//  MeterReaderKeeperError.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 8/25/26.
//

import Foundation

/// The error type surfaced by domain-model validation, the repository
/// layer, and view models throughout the app. Conforms to
/// `LocalizedError` so `errorDescription` can be shown directly in an
/// alert.
enum MeterKeeperError: LocalizedError {
    /// A domain model or input struct failed its own `validate()` check.
    case validationError(ValidationError)
    /// The SwiftData store threw while reading or writing.
    case persistenceError(Error)
    /// A file-system operation (e.g. loading seed/image data) failed.
    case fileSystemError(Error)
    /// A lookup by identifier found no matching record; the associated
    /// string names what wasn't found (e.g. "Meter").
    case notFound(String)
    /// A catch-all for errors that don't fit the other cases.
    case unknown(Error)

    /// The specific reason a `.validationError` was thrown.
    enum ValidationError {
        /// A required field was empty; the associated string names the field.
        case missingRequiredField(String)
        /// A numeric value that must be non-negative was negative.
        case negativeValue
        /// A reading's date was after the current date.
        case readingInFuture
        /// A catch-all for validation failures with a custom message.
        case invalidInput(String)
        /// A name that must be unique already exists; the associated
        /// string is the conflicting name.
        case duplicateName(String)
    }

    /// A user-facing message describing this error, suitable for display
    /// in an alert.
    var errorDescription: String? {
        switch self {
        case .validationError(let validationError):
            switch validationError {
            case .missingRequiredField(let field):
                return "Required field is missing: \(field)"
            case .negativeValue:
                return "Value cannot be negative"
            case .readingInFuture:
                return "Reading date cannot be in the future"
            case .invalidInput(let message):
                return "Invalid input: \(message)"
            case .duplicateName(let name):
                return "An item with the name '\(name)' already exists"
            }
        case .persistenceError(let error):
            return "Database error: \(error.localizedDescription)"
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        case .notFound(let item):
            return "\(item) not found"
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}
