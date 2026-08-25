//
//  MeterReaderKeeperError.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 8/25/26.
//

import Foundation

enum MeterKeeperError: LocalizedError {
    case persistenceError(underlying: Error)
    case validationError(ValidationError)
    case exportError(ExportError)
    case importError(ImportError)
    case notFound(EntityType)
    case unauthorized
    
    enum ValidationError {
        case invalidReadingValue(String)
        case missingRequiredField(String)
        case readingInFuture
        case duplicateReading
        case negativeValue
    }
    
    enum ExportError {
        case noData
        case fileCreationFailed
        case compressionFailed
        case invalidFormat
    }
    
    enum ImportError {
        case invalidFileFormat
        case corruptedData
        case incompatibleVersion
    }
    
    enum EntityType: String {
        case building = "Building"
        case floor = "Floor"
        case meter = "Meter"
        case reading = "Reading"
    }
    
    var errorDescription: String? {
        switch self {
        case .persistenceError(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .validationError(let validation):
            return validation.message
        case .exportError(let export):
            return export.message
        case .importError(let importError):
            return importError.message
        case .notFound(let entity):
            return "\(entity.rawValue) not found"
        case .unauthorized:
            return "You don't have permission to perform this action"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .persistenceError:
            return "Please try again. If the problem persists, restart the app."
        case .validationError(.invalidReadingValue):
            return "Please enter a valid number for the meter reading."
        case .validationError(.missingRequiredField(let field)):
            return "Please fill in the \(field) field."
        case .validationError(.readingInFuture):
            return "Cannot add readings for future dates."
        case .validationError(.negativeValue):
            return "Reading value must be positive."
        case .validationError(.duplicateReading):
            return "A reading already exists for this date. Please edit the existing reading."
        case .exportError(.noData):
            return "There is no data to export."
        case .exportError:
            return "Please try exporting again."
        case .importError:
            return "Please check the file and try again."
        case .notFound:
            return "The item may have been deleted."
        case .unauthorized:
            return "Please check your permissions."
        }
    }
}

extension MeterKeeperError.ValidationError {
    var message: String {
        switch self {
        case .invalidReadingValue(let value):
            return "Invalid reading value: \(value)"
        case .missingRequiredField(let field):
            return "Required field missing: \(field)"
        case .readingInFuture:
            return "Cannot add readings for future dates"
        case .duplicateReading:
            return "A reading already exists for this date"
        case .negativeValue:
            return "Reading value cannot be negative"
        }
    }
}

extension MeterKeeperError.ExportError {
    var message: String {
        switch self {
        case .noData:
            return "No data available to export"
        case .fileCreationFailed:
            return "Failed to create export file"
        case .compressionFailed:
            return "Failed to compress images"
        case .invalidFormat:
            return "Invalid export format"
        }
    }
}

extension MeterKeeperError.ImportError {
    var message: String {
        switch self {
        case .invalidFileFormat:
            return "The file format is not supported"
        case .corruptedData:
            return "The file data is corrupted"
        case .incompatibleVersion:
            return "This file was created with an incompatible version"
        }
    }
}
