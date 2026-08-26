//
//  MeterReaderKeeperError.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 8/25/26.
//

import Foundation

/// Custom errors for the MeterReaderKeeper app
enum MeterKeeperError: LocalizedError {
    case validationError(ValidationError)
    case coreDataError(Error)
    case fileSystemError(Error)
    case notFound(String)
    case unknown(Error)
    
    enum ValidationError {
        case missingRequiredField(String)
        case negativeValue
        case readingInFuture
        case invalidInput(String)
        case duplicateName(String)
    }
    
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
        case .coreDataError(let error):
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
