//
//  QrScannerViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/6/21.
//

import UIKit
import AVFoundation

@objc public protocol QRScannerDelegate {
    @objc func scannedCode(_ codeString: String, errorCompletion: (NSError?)->())
}

class QrScannerViewController: UIViewController {

    public weak var scannerDelegate: QRScannerDelegate!
    
    @IBOutlet weak var previewView: UIView!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let captureSession = self.createCaptureSession() {
            self.captureSession = captureSession
            let previewLayer = self.createPreviewLayer(withCaptureSession: captureSession, view: previewView)
            previewView.layer.addSublayer(previewLayer)
            requestCaptureSessionStartRunning()
        }
    }
    
    func requestCaptureSessionStartRunning() {
        guard let captureSession = captureSession else {
            return
        }
        
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    func requestCaptureSessionStopRunning() {
        guard let captureSession = captureSession else {
            return
        }
        
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func createPreviewLayer(withCaptureSession captureSession: AVCaptureSession, view: UIView) -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    private func createCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return nil
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            let metaDataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            } else {
                return nil
            }
            
            if captureSession.canAddOutput(metaDataOutput) {
                captureSession.addOutput(metaDataOutput)
                
                metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metaDataOutput.metadataObjectTypes = metaObjectTypes()
            } else {
                return nil
            }
        } catch {
            return nil
        }
        
        return captureSession
    }
    
    private func metaObjectTypes() -> [AVMetadataObject.ObjectType] {
        return [.qr,
                .code39,
                .code39Mod43,
                .code93,
                .ean8,
                .ean13,
                .interleaved2of5,
                .itf14,
                .pdf417,
                .upce
        ]
    }
    
    func showMeterScanErrorAlert(with message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.requestCaptureSessionStartRunning()
        }))
        present(alertController, animated: true, completion: nil)
    }
}

extension QrScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.requestCaptureSessionStopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard
                let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                let stringValue = readableObject.stringValue else {
                return
            }
            scannerDelegate.scannedCode(stringValue) { (error) in
                if let error = error {
                    let errorString = "\(error.domain): Found \(error.code) meters"
                    showMeterScanErrorAlert(with: errorString)
                }
            }
        }
    }
}
