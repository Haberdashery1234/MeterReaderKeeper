//
//  MRKMeter.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation

/// A single meter on a `MRKFloor`, with its full reading history.
struct MRKMeter: Identifiable, Hashable {
    /// Stable identity for the meter, shared with its SwiftData record.
    let id: UUID

    /// The meter's display name.
    let name: String

    /// A free-form description of the meter (e.g. what it serves), shown
    /// as secondary text in list rows.
    let meterDescription: String

    /// The string encoded in this meter's QR label, used to look the meter
    /// up when scanning during a reading.
    let qrString: String

    /// Raw image data for a photo of the meter, or empty `Data()` if none
    /// has been set (seed data never populates this).
    let imageData: Data

    /// The date of this meter's most recent reading, or `.distantPast` if
    /// it has never been read.
    let latestReadingDate: Date

    /// The `id` of the `MRKFloor` this meter is located on.
    let floorID: UUID

    /// This meter's full reading history, in no particular order. Use
    /// `sortedReadings` for a most-recent-first list.
    let readings: [MRKReading]

    /// The most recent reading, or `nil` if this meter has never been read.
    var mostRecentReading: MRKReading? {
        sortedReadings.first
    }

    /// `readings` sorted by date, most recent first.
    var sortedReadings: [MRKReading] {
        readings.sorted { $0.date > $1.date }
    }

    /// Checks that this meter has a non-empty name.
    ///
    /// - Throws: `MeterKeeperError.validationError(.missingRequiredField)`
    ///   if `name` is empty or all whitespace.
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Meter name"))
        }
    }
}

extension MRKMeter {
    /// Days after which a meter with no new reading is considered overdue.
    /// This is the threshold from the Home redesign mockup — a starting
    /// guess, not yet a confirmed value (see `HomeViewModel`), kept here so
    /// `HomeViewModel`'s "Needs Attention" list and the Manage screen's
    /// meter rows share one source of truth instead of drifting.
    static let staleThresholdDays = 14

    /// Days since `latestReadingDate`, or `nil` if this meter has never had
    /// a reading recorded (`latestReadingDate == .distantPast`).
    ///
    /// - Parameter now: The reference date to measure from. Defaults to the
    ///   current date; overridable for testing.
    /// - Returns: The whole number of days elapsed, or `nil` if unread.
    func daysSinceLastReading(asOf now: Date = Date()) -> Int? {
        guard latestReadingDate != .distantPast else { return nil }
        return Calendar.current.dateComponents([.day], from: latestReadingDate, to: now).day
    }

    /// Whether this meter is overdue for a reading — never read, or not
    /// read in at least `staleThresholdDays` days. Mirrors the check
    /// `HomeViewModel` uses for its "Needs Attention" list.
    ///
    /// - Parameter now: The reference date to measure from. Defaults to the
    ///   current date; overridable for testing.
    func isStale(asOf now: Date = Date()) -> Bool {
        guard let days = daysSinceLastReading(asOf: now) else { return true }
        return days >= Self.staleThresholdDays
    }

    /// A short display string for the meter's last reading, including its
    /// value, e.g. "Last read Aug 20, 2026 — 245.10 kWh", or "Never read"
    /// if `mostRecentReading` is `nil` / `latestReadingDate` is still
    /// `.distantPast`. Widened 2026-08-28 to include the value — was
    /// date-only when first added earlier the same day; only ever used by
    /// `MeterTableViewCell`, so safe to widen in place.
    var lastReadingSummary: String {
        guard let reading = mostRecentReading, latestReadingDate != .distantPast else {
            return "Never read"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Last read \(formatter.string(from: latestReadingDate)) \u{2014} \(reading.formattedValue)"
    }
}

/// The data needed to create or update a meter.
struct MRKMeterInput {
    /// The meter's display name.
    let name: String

    /// A free-form description of the meter (e.g. what it serves).
    let description: String

    /// Raw image data for a photo of the meter; pass empty `Data()` if none.
    let imageData: Data

    /// The `id` of the `MRKFloor` this meter is located on.
    let floorID: UUID

    /// Checks that this input has a non-empty name.
    ///
    /// - Throws: `MeterKeeperError.validationError(.missingRequiredField)`
    ///   if `name` is empty or all whitespace.
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeterKeeperError.validationError(.missingRequiredField("Meter name"))
        }
    }
}
