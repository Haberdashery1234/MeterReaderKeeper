//
//  XCUIElement+ClearText.swift
//  MeterReaderKeeperUITests
//
//  Created on 8/28/26.
//

import XCTest

extension XCUIElement {
    /// Clears an existing `UITextField`'s text by sending one backspace
    /// keystroke per character currently in it, then optionally types a
    /// replacement. XCUITest has no built-in "select all and replace" for
    /// a plain `UITextField` — this backspace-the-existing-value approach
    /// is the standard, widely used workaround. Call this with the field
    /// already focused (e.g. after `.tap()`).
    func clearAndTypeText(_ text: String) {
        if let existingValue = self.value as? String, !existingValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count)
            self.typeText(deleteString)
        }
        if !text.isEmpty {
            self.typeText(text)
        }
    }
}
