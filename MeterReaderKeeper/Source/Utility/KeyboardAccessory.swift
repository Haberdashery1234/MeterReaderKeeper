//
//  KeyboardAccessory.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//

import UIKit

public enum TextFieldAccessoryView: Int {
    case done,
    nextPreviousDone,
    doneCancel
}

@objc public protocol KeyboardToolbarDelegate {
    @objc optional func doneButtonTapped()
    @objc optional func nextButtonTapped()
    @objc optional func previousButtonTapped()
    @objc optional func cancelButtonTapped()
}

public class KeyboardToolbar: UIToolbar {
    public weak var keyboardToolbarDelegate: KeyboardToolbarDelegate!
    
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
    
    public func doneToolbar() {
        self.items = [ flex(), doneButton() ]
        self.sizeToFit()
    }
    
    public func nextPreviousToolbar() {
        self.items = [ previousArrow(), nextArrow(), flex(), doneButton() ]
        self.sizeToFit()
    }
    
    public func doneCancelToolbar() {
        self.items = [ cancelButton(), flex(), doneButton() ]
        self.sizeToFit()
    }
    
    private func doneButtonTapped() {
        if let delegate = keyboardToolbarDelegate {
            delegate.doneButtonTapped?()
        }
    }
    
    private func cancelButtonTapped() {
        if let delegate = keyboardToolbarDelegate {
            delegate.cancelButtonTapped?()
        }
    }
}
