//
//  Constants.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//

import Foundation

public class Constants: NSObject {
    public static let UIStrings = _UIStrings()
    public static let UIValues = _UIValues()
    
    public class _UIStrings: NSObject {
        public let cancel = NSLocalizedString("Cancel", comment:"Cancel")
        public let done = NSLocalizedString("Done", comment:"Done")
    }
    
    public class _UIValues: NSObject {
        public let animationDuration: TimeInterval = 0.5
    }
}
