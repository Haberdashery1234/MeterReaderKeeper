//
//  UIService.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/7/21.
//

import UIKit

/// Image-compression helpers used when building the app's data export
/// (building/floor/meter photos are size-capped before being embedded in
/// the exported plist — see `SDFloor.getExportDictionary()` and
/// `SDMeter.getExportDictionary()`).
class UIService {

    static let shared = UIService()
    
    /// Compresses image data to meet a maximum size requirement
    /// - Parameters:
    ///   - imageData: The source image data
    ///   - maxSize: Maximum size in megabytes
    /// - Returns: Compressed image data, or nil if compression fails
    func getExportSizeImageData(from imageData: Data, ofMaxSizeMB maxSize: Float) -> Data? {
        guard let image = UIImage(data: imageData) else {
            print("Failed to create UIImage from data")
            return Data()
        }
        return getExportSizeImage(from: image, ofMaxSizeMB: maxSize)
    }
    
    /// Compresses an image to meet a maximum size requirement
    /// - Parameters:
    ///   - image: The source image
    ///   - ofMaxSizeMB: Maximum size in megabytes
    /// - Returns: Compressed image data, or original PNG data if already small enough
    /// Binary-searches JPEG compression quality to fit `image` under
    /// `ofMaxSizeMB`, falling back to its PNG data if already small enough
    /// or the best achievable JPEG is still larger than the limit.
    func getExportSizeImage(from image: UIImage, ofMaxSizeMB: Float) -> Data? {
        guard let pngData = image.pngData() else {
            print("Failed to generate PNG data from image")
            return Data()
        }
        
        let maxSizeBytes = Int(ofMaxSizeMB * 1_000_000)
        
        // If image is already small enough, return PNG data
        if pngData.count <= maxSizeBytes {
            print("Image already within size limit (\(pngData.count) bytes)")
            return pngData
        }
        
        // Start with high quality JPEG compression
        var compressionQuality: CGFloat = 1.0
        var compressedData: Data?
        var currentSize = pngData.count
        
        print("Starting compression from \(pngData.count) bytes to target \(maxSizeBytes) bytes")
        
        // Binary search for optimal compression quality
        var minQuality: CGFloat = 0.0
        var maxQuality: CGFloat = 1.0
        
        while maxQuality - minQuality > 0.01 {
            compressionQuality = (minQuality + maxQuality) / 2
            
            guard let data = image.jpegData(compressionQuality: compressionQuality) else {
                print("Failed to generate JPEG data at quality \(compressionQuality)")
                return compressedData ?? pngData
            }
            
            currentSize = data.count
            print("Quality: \(compressionQuality), Size: \(currentSize) bytes")
            
            if currentSize <= maxSizeBytes {
                compressedData = data
                minQuality = compressionQuality // Try higher quality
            } else {
                maxQuality = compressionQuality // Need more compression
            }
            
            // Safety check: if we can't compress further
            if compressionQuality < 0.05 {
                print("Minimum compression reached, image may exceed size limit")
                break
            }
        }
        
        if let finalData = compressedData {
            print("Compression complete: \(pngData.count) → \(finalData.count) bytes")
            return finalData
        } else {
            print("Could not compress image below size limit, returning original")
            return pngData
        }
    }
}
