//
//  EmailServiceTests.swift
//  MeterReaderKeeperTests
//

import Testing
import Foundation
@testable import MeterReaderKeeper

/// Mirrors `Source/Screens/Management/EmailService.swift`. Only
/// `EmailError`'s message text is covered here — `EmailService` itself
/// needs `MFMailComposeViewController.canSendMail()` and a presenting
/// `UIViewController` to do anything, which makes its actual send/present
/// flow a UIKit-presentation concern (mirrors the "Views own UI, aren't
/// unit-tested" boundary already drawn elsewhere in this codebase) rather
/// than something to unit test directly.
@Suite("EmailError")
struct EmailServiceTests {

    @Test("error descriptions")
    func errorDescriptions() {
        #expect(EmailError.mailUnavailable.errorDescription == "Email services are not available on this device")
        #expect(EmailError.attachmentTooLarge.errorDescription == "The attachment is too large to send")
        #expect(EmailError.invalidAttachment.errorDescription == "The attachment data is invalid")
    }
}
