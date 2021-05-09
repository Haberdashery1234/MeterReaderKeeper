//
//  UIService.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/7/21.
//

import UIKit

class UIService {
    
    static let shared = UIService()
    
    func getExportSizeImageData(from imageData: Data, ofMaxSizeMB maxSize: Float) -> Data? {
        guard let image = UIImage(data: imageData) else {
            return Data()
        }
        return getExportSizeImage(from: image, ofMaxSizeMB: maxSize)
    }
    
    func getExportSizeImage(from image: UIImage, ofMaxSizeMB: Float) -> Data? {
        guard let pngData = image.pngData() else {
            return Data()
        }
        let maxSizeBytes = Int(ofMaxSizeMB * 1000000)
        var maxQuality: CGFloat = 1.0
        var bestData: Data?
        var thisSize = pngData.count
        while thisSize > maxSizeBytes {
            let thisQuality = maxQuality / 2
            guard let data = image.jpegData(compressionQuality: thisQuality) else {
                print("image jpegData failed")
                return nil
            }
            if thisSize == data.count {
                print("image won't compress further")
                return bestData
            }
            thisSize = data.count
            print(thisQuality)
            print(thisSize)
            if thisSize > maxSizeBytes {
                maxQuality = thisQuality
            } else {
                bestData = data
                return bestData
            }
        }
        return nil
    }
}
