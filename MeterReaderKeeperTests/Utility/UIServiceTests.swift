//
//  UIServiceTests.swift
//  MeterReaderKeeperTests
//

import Testing
import UIKit
@testable import MeterReaderKeeper

/// Mirrors `Source/Utility/UIService.swift`. Per the audit,
/// `getExportSizeImage`/`getExportSizeImageData`'s binary-search
/// compression logic is pure enough (image/data in, data out) to unit
/// test without much UIKit ceremony.
///
/// Deliberately limited to outcomes that don't depend on actual
/// JPEG/PNG codec output sizes — those vary with the real on-device image
/// encoder and can't be predicted reliably without compiling and running
/// against one, which this environment can't do. No test here asserts a
/// specific compressed byte count; each instead exercises a branch of
/// `getExportSizeImage` whose outcome follows from the method's own
/// control flow regardless of actual encoder output sizes.
@Suite("UIService")
struct UIServiceTests {

    /// A tiny, deterministic image whose PNG data is always well under
    /// any of the size limits used below.
    private func tinyImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    @Test("returns PNG data unchanged when already within the size limit")
    func returnsPNGDataUnchangedWhenWithinLimit() throws {
        let image = tinyImage()
        let pngData = try #require(image.pngData())

        let result = UIService.shared.getExportSizeImage(from: image, ofMaxSizeMB: 10.0)

        #expect(result == pngData)
    }

    @Test("falls back to the original PNG data when even minimum-quality JPEG can't fit")
    func fallsBackToOriginalPNGDataWhenLimitIsUnreachable() throws {
        let image = tinyImage()
        let pngData = try #require(image.pngData())

        // 0 MB is unreachable by any non-empty JPEG, so the binary search
        // never finds a quality level that fits under the limit and
        // getExportSizeImage falls back to returning the original PNG
        // data untouched — true regardless of actual JPEG byte counts.
        let result = UIService.shared.getExportSizeImage(from: image, ofMaxSizeMB: 0)

        #expect(result == pngData)
    }

    @Test("getExportSizeImageData returns empty data for non-image input")
    func getExportSizeImageDataReturnsEmptyDataForInvalidInput() {
        let garbage = Data("not an image".utf8)

        let result = UIService.shared.getExportSizeImageData(from: garbage, ofMaxSizeMB: 1.0)

        #expect(result == Data())
    }
}
