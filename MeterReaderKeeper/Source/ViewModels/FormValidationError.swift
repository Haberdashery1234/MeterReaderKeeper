//
//  FormValidationError.swift
//  MeterReaderKeeper
//
//  Created by MVVM Refactor on 8/26/26.
//

import Foundation

/// A validation failure a ViewModel wants its View to present as an alert.
///
/// Before this pass, every screen's `validateInput()` called
/// `showAlert(title:message:)` directly and returned `nil`. Now that
/// validation lives in the ViewModel (which must not touch UIKit
/// presentation), the same title/message pairs are thrown as this typed
/// error instead. Every View catches `FormValidationError` specifically
/// (before the generic `catch`) so the exact original alert copy is
/// preserved:
///
/// ```swift
/// do {
///     try viewModel.save(...)
///     navigationController?.popViewController(animated: true)
/// } catch let error as FormValidationError {
///     showAlert(title: error.title, message: error.message)
/// } catch {
///     showAlert(title: "Save Failed", message: error.localizedDescription)
/// }
/// ```
struct FormValidationError: LocalizedError {
    let title: String
    let message: String

    var errorDescription: String? { message }
}
