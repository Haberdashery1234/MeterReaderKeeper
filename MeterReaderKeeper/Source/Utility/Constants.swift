//
//  Constants.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//

import Foundation

/// App-wide shared constants, namespaced under `UIStrings` (localized
/// button titles) and `UIValues` (layout/animation constants).
public class Constants: NSObject {
    /// Shared localized strings, e.g. `Constants.UIStrings.done`.
    public static let UIStrings = _UIStrings()
    /// Shared UI value constants, e.g. `Constants.UIValues.animationDuration`.
    public static let UIValues = _UIValues()

    public class _UIStrings: NSObject {
        /// Localized "Cancel" button title.
        public let cancel = NSLocalizedString("Cancel", comment:"Cancel")
        /// Localized "Done" button title.
        public let done = NSLocalizedString("Done", comment:"Done")
    }

    public class _UIValues: NSObject {
        /// Standard duration for this app's `UIView.animate` calls (e.g.
        /// the Readings map overlay's show/hide).
        public let animationDuration: TimeInterval = 0.5
    }
}
