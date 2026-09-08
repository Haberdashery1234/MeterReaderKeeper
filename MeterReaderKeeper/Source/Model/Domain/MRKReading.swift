//
//  MRKReading.swift
//  MeterReaderKeeper
//
//  Created by Repository Refactor on 8/26/26.
//

import Foundation

/// A single meter reading: a kWh value recorded on a given date.
struct MRKReading: Identifiable, Hashable {
    /// Stable identity for the reading, shared with its SwiftData record.
    let id: UUID

    /// The date this reading was recorded.
    let date: Date

    /// The raw meter value, in kilowatt-hours.
    let kWh: Double

    /// The `id` of the `MRKMeter` this reading belongs to.
    let meterID: UUID

    /// `kWh` formatted for display, e.g. "245.10 kWh".
    var formattedValue: String {
        String(format: "%.2f kWh", kWh)
    }

    /// `date` formatted for display as a medium-style date, e.g. "Aug 20, 2026".
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Checks that this reading's value is non-negative and its date isn't
    /// in the future.
    ///
    /// This only validates the reading in isolation — it does not enforce
    /// that `kWh` is monotonically increasing relative to the meter's prior
    /// readings. A lower-than-previous value is a legitimate meter rollover
    /// (see `usage(from:to:)` below), so monotonicity enforcement was
    /// deliberately left out here — a non-rollover decrease is currently
    /// accepted silently.
    ///
    /// - Throws: `MeterKeeperError.validationError` — `.negativeValue` if
    ///   `kWh` is negative, or `.readingInFuture` if `date` is after now.
    func validate() throws {
        if kWh < 0 {
            throw MeterKeeperError.validationError(.negativeValue)
        }

        if date > Date() {
            throw MeterKeeperError.validationError(.readingInFuture)
        }
    }
}

extension MRKReading {
    /// The kWh used going from `previous` to `current`, correcting for
    /// meter rollover.
    ///
    /// Electric meters are cumulative: a real reading should never be lower
    /// than the one before it, EXCEPT when the meter's dial has wrapped
    /// back to 0 after exceeding its digit capacity — a real, if uncommon,
    /// occurrence (2026-08-28). So when `current.kWh` is lower than
    /// `previous.kWh`, that drop is treated as a rollover rather than bad
    /// data, and the usage is the distance from `previous` up to the
    /// rollover point plus `current`'s value past it. For example: if a
    /// meter is at 9997 and the next reading is 0200, the difference is
    /// 203; if a meter is at 9999997 and the next reading is 200, the
    /// difference is still 203.
    ///
    /// Nothing about a meter's actual digit capacity is stored anywhere in
    /// this app, so the rollover point is inferred from `previous` itself —
    /// see `rolloverCap(after:)`. That inference matches both examples
    /// above exactly, but it's a guess, not a configured hardware value: if
    /// a meter's real display width doesn't match its previous reading's
    /// own digit count, this will be wrong. This is display-only — it
    /// doesn't feed back into `validate()`.
    ///
    /// - Parameters:
    ///   - previous: The earlier of the two readings.
    ///   - current: The later of the two readings.
    /// - Returns: The kWh used between the two readings, rollover-corrected.
    static func usage(from previous: MRKReading, to current: MRKReading) -> Double {
        if current.kWh >= previous.kWh {
            return current.kWh - previous.kWh
        }
        let cap = MRKReading.rolloverCap(after: previous.kWh)
        return (cap - previous.kWh) + current.kWh
    }

    /// The smallest power of ten strictly greater than `value`'s whole
    /// number part (e.g. 9997 -> 10,000; 9999997 -> 10,000,000) — the
    /// assumed number of digits the meter's dial can show before it wraps
    /// back to 0. Only the integer part matters: a reading's decimal
    /// portion doesn't change how many digits the meter's dial has.
    ///
    /// - Parameter value: The previous reading's kWh value.
    /// - Returns: The inferred rollover point for that meter.
    static func rolloverCap(after value: Double) -> Double {
        var remaining = Int(value.rounded(.down))
        guard remaining > 0 else { return 10 }
        var cap = 1
        while remaining > 0 {
            cap *= 10
            remaining /= 10
        }
        return Double(cap)
    }
}

/// The data needed to create a reading.
struct MRKReadingInput {
    /// The raw meter value, in kilowatt-hours.
    let kWh: Double

    /// The date this reading was recorded.
    let date: Date

    /// The `id` of the `MRKMeter` this reading belongs to.
    let meterID: UUID

    /// Checks that this input's value is non-negative and its date isn't
    /// in the future. See `MRKReading.validate()` for why a
    /// lower-than-previous value is not rejected here.
    ///
    /// - Throws: `MeterKeeperError.validationError` — `.negativeValue` if
    ///   `kWh` is negative, or `.readingInFuture` if `date` is after now.
    func validate() throws {
        if kWh < 0 {
            throw MeterKeeperError.validationError(.negativeValue)
        }

        if date > Date() {
            throw MeterKeeperError.validationError(.readingInFuture)
        }
    }
}
