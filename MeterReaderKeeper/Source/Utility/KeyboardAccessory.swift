//
//  KeyboardAccessory.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//

import UIKit

/// Which button layout a `KeyboardToolbar` should show.
public enum TextFieldAccessoryView: Int {
    /// A single "Done" button.
    case done,
    /// Previous/Next arrows plus a "Done" button.
    nextPreviousDone,
    /// "Cancel" and "Done" buttons.
    doneCancel
}

/// Notified when a `KeyboardToolbar`'s buttons are tapped. All methods are
/// optional, since not every toolbar layout has every button.
@objc public protocol KeyboardToolbarDelegate {
    @objc optional func doneButtonTapped()
    @objc optional func nextButtonTapped()
    @objc optional func previousButtonTapped()
    @objc optional func cancelButtonTapped()
}

/// A `UIToolbar` preconfigured as a text field's `inputAccessoryView`, in
/// one of a few standard button layouts (see `TextFieldAccessoryView`).
public class KeyboardToolbar: UIToolbar {
    public weak var keyboardToolbarDelegate: KeyboardToolbarDelegate!

    /// Creates a toolbar with the given button layout.
    ///
    /// - Parameters:
    ///   - type: Which button layout to show.
    ///   - delegate: Notified when a button is tapped.
    public convenience init(type: TextFieldAccessoryView, delegate: KeyboardToolbarDelegate? = nil) {
        self.init()
        switch type {
        case .done:
            doneToolbar()
        case .nextPreviousDone:
            nextPreviousToolbar()
        case .doneCancel:
            doneCancelToolbar()
        }
        self.keyboardToolbarDelegate = delegate
    }
    
    private func cancelButton() -> UIBarButtonItem {
        let btnCancel = UIBarButtonItem(title: Constants.UIStrings.cancel, style: .plain, target: keyboardToolbarDelegate, action: #selector(keyboardToolbarDelegate.cancelButtonTapped))
        return btnCancel
    }
    private func doneButton() -> UIBarButtonItem {
        let btnDone = UIBarButtonItem(title: Constants.UIStrings.done, style: .plain, target: keyboardToolbarDelegate, action: #selector(keyboardToolbarDelegate.doneButtonTapped))
        return btnDone
    }
    
    private func flex() -> UIBarButtonItem {
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return flex
    }
    
    private func previousArrow() -> UIBarButtonItem {
        let btnPrevious = UIBarButtonItem(image: UIImage.init(systemName: "arrow.left"), style: .plain, target: keyboardToolbarDelegate, action: #selector(keyboardToolbarDelegate.previousButtonTapped))
        return btnPrevious
    }
    
    private func nextArrow() -> UIBarButtonItem {
        let btnNext = UIBarButtonItem(image: UIImage.init(systemName: "arrow.right"), style: .plain, target: keyboardToolbarDelegate, action: #selector(keyboardToolbarDelegate.nextButtonTapped))
        return btnNext
    }
    
    /// Configures this toolbar with just a "Done" button.
    public func doneToolbar() {
        self.items = [ flex(), doneButton() ]
        self.sizeToFit()
    }

    /// Configures this toolbar with Previous/Next arrows and a "Done" button.
    public func nextPreviousToolbar() {
        self.items = [ previousArrow(), nextArrow(), flex(), doneButton() ]
        self.sizeToFit()
    }

    /// Configures this toolbar with "Cancel" and "Done" buttons.
    public func doneCancelToolbar() {
        self.items = [ cancelButton(), flex(), doneButton() ]
        self.sizeToFit()
    }

    /// Forwards to `keyboardToolbarDelegate`, if one is set.
    private func doneButtonTapped() {
        if let delegate = keyboardToolbarDelegate {
            delegate.doneButtonTapped?()
        }
    }

    /// Forwards to `keyboardToolbarDelegate`, if one is set.
    private func cancelButtonTapped() {
        if let delegate = keyboardToolbarDelegate {
            delegate.cancelButtonTapped?()
        }
    }
}
