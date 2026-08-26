//
//  NSManagedObjectID+StableUUID.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import CoreData
import CryptoKit

extension NSManagedObjectID {

    /// A UUID deterministically derived from this object's permanent URI
    /// representation.
    ///
    /// The Core Data model does not (yet) store a persisted `id` attribute on
    /// any entity, so `CoreDataMeterRepository` derives a stable identifier
    /// from each managed object's `NSManagedObjectID` instead, and uses that
    /// UUID as the public identity for the `Building` / `Floor` / `Meter` /
    /// `Reading` domain structs.
    ///
    /// This UUID is stable for the lifetime of a saved record — it will not
    /// change across app launches once the object has a *permanent* object ID
    /// (i.e. after its managed object context has been saved at least once).
    /// It is NOT guaranteed stable if the underlying store file is copied or
    /// restored elsewhere, so it should not be treated as a long-lived
    /// external identifier (e.g. for a future sync feature). If that's ever
    /// needed, the correct fix is a real persisted `id: UUID` attribute added
    /// to the Core Data model — the repository protocol already only exposes
    /// `UUID`, so that change would stay entirely internal to
    /// `CoreDataMeterRepository`.
    var stableUUID: UUID {
        let uriString = uriRepresentation().absoluteString
        let digest = SHA256.hash(data: Data(uriString.utf8))
        let bytes = Array(digest.prefix(16))
        return bytes.withUnsafeBufferPointer { buffer in
            NSUUID(uuidBytes: buffer.baseAddress!) as UUID
        }
    }
}
