//
//  EmailService.swift
//  MeterReaderKeeper
//
//  Created by Code Modernization on 8/25/26.
//

import UIKit
import MessageUI

/// Presents `MFMailComposeViewController` to send the app's plist/CSV
/// exports as email attachments. A singleton (`shared`) since only one
/// mail composer can be presented at a time, and it needs to retain itself
/// as the compose controller's delegate for the duration of that presentation.
class EmailService: NSObject {

    static let shared = EmailService()

    /// The view controller the mail composer was presented from, kept only
    /// to dismiss back to it; cleared once composition finishes.
    private weak var presentingViewController: UIViewController?
    /// The caller's completion handler, invoked once composition finishes.
    private var completionHandler: ((MFMailComposeResult, Error?) -> Void)?

    private override init() {
        super.init()
    }
    
    /// Sends an email with attachment
    /// - Parameters:
    ///   - from: The view controller to present the mail compose controller from
    ///   - recipients: Array of email addresses (empty for no pre-filled recipients)
    ///   - subject: Email subject line
    ///   - body: Email body text
    ///   - isHTML: Whether the body is HTML formatted
    ///   - attachment: Optional attachment data
    ///   - mimeType: MIME type of attachment
    ///   - fileName: Name for the attachment file
    ///   - completion: Called when email composition is complete
    func sendEmail(
        from viewController: UIViewController,
        recipients: [String] = [],
        subject: String,
        body: String,
        isHTML: Bool = false,
        attachment: Data? = nil,
        mimeType: String? = nil,
        fileName: String? = nil,
        completion: ((MFMailComposeResult, Error?) -> Void)? = nil
    ) {
        guard MFMailComposeViewController.canSendMail() else {
            print("Mail services not available")
            showEmailUnavailableAlert(from: viewController)
            completion?(.failed, EmailError.mailUnavailable)
            return
        }
        
        self.presentingViewController = viewController
        self.completionHandler = completion
        
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients(recipients)
        mail.setSubject(subject)
        mail.setMessageBody(body, isHTML: isHTML)
        
        if let attachment = attachment,
           let mimeType = mimeType,
           let fileName = fileName {
            mail.addAttachmentData(attachment, mimeType: mimeType, fileName: fileName)
            print("Email prepared with attachment: \(fileName) (\(attachment.count) bytes)")
        }
        
        viewController.present(mail, animated: true)
        print("Presented email composer")
    }
    
    /// Convenience method for sending export plist via email
    func sendExport(
        from viewController: UIViewController,
        plistData: Data,
        completion: ((MFMailComposeResult, Error?) -> Void)? = nil
    ) {
        sendEmail(
            from: viewController,
            recipients: [],
            subject: "Meter Reader Export",
            body: "Please find the exported meter reading data attached.",
            isHTML: false,
            attachment: plistData,
            mimeType: "application/xml",
            fileName: "exportData.plist",
            completion: completion
        )
    }
    
    /// Convenience method for sending CSV readings via email
    func sendCSV(
        from viewController: UIViewController,
        csvData: Data,
        buildingName: String,
        completion: ((MFMailComposeResult, Error?) -> Void)? = nil
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        
        sendEmail(
            from: viewController,
            recipients: [],
            subject: "Meter Readings - \(buildingName)",
            body: "Meter readings for \(buildingName) as of \(dateString).",
            isHTML: false,
            attachment: csvData,
            mimeType: "text/csv",
            fileName: "MeterReadings_\(buildingName).csv",
            completion: completion
        )
    }
    
    /// Presents an alert explaining that Mail isn't configured on this device.
    private func showEmailUnavailableAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Email Unavailable",
            message: "Email is not configured on this device. Please set up Mail in Settings to use this feature.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension EmailService: MFMailComposeViewControllerDelegate {
    /// Dismisses the mail composer and forwards the result to whichever
    /// `sendEmail`/`sendExport`/`sendCSV` caller is waiting on it.
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        if let error = error {
            print("Mail compose error: \(error.localizedDescription)")
        }
        
        switch result {
        case .sent:
            print("Email sent successfully")
        case .saved:
            print("Email saved as draft")
        case .cancelled:
            print("Email cancelled by user")
        case .failed:
            print("Email send failed")
        @unknown default:
            print("Unknown mail compose result")
        }
        
        controller.dismiss(animated: true) { [weak self] in
            self?.completionHandler?(result, error)
            self?.completionHandler = nil
            self?.presentingViewController = nil
        }
    }
}

// MARK: - Errors

/// Errors specific to `EmailService`.
enum EmailError: LocalizedError {
    /// The device has no Mail account configured, so
    /// `MFMailComposeViewController.canSendMail()` returned `false`.
    case mailUnavailable
    /// Unused today — reserved for a future attachment-size check.
    case attachmentTooLarge
    /// Unused today — reserved for a future attachment-validity check.
    case invalidAttachment


    var errorDescription: String? {
        switch self {
        case .mailUnavailable:
            return "Email services are not available on this device"
        case .attachmentTooLarge:
            return "The attachment is too large to send"
        case .invalidAttachment:
            return "The attachment data is invalid"
        }
    }
}
