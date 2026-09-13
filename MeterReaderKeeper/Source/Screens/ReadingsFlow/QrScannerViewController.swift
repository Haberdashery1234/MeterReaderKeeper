//
//  QrScannerViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/6/21.
//

import UIKit
import AVFoundation

/// Receives the result of a QR scan from `QrScannerViewController`.
@objc public protocol QRScannerDelegate {
    /// Called when a code is successfully scanned.
    ///
    /// - Parameters:
    ///   - codeString: The scanned code's raw string value.
    ///   - errorCompletion: Called back by the delegate with a non-nil
    ///     `NSError` if `codeString` couldn't be matched to a meter, so the
    ///     scanner can show an error and resume scanning.
    @objc func scannedCode(_ codeString: String, errorCompletion: @escaping (NSError?)->())
}

/// An `AVCaptureSession`-backed QR/barcode scanner, pushed by
/// `AppCoordinator.showQrScanner(delegate:)` — currently only from
/// `ReadingsMainViewController`'s scan button. `scannerDelegate` resolves
/// a scanned code to a meter and decides where to navigate; this screen
/// only owns the camera preview and capture session.
class QrScannerViewController: UIViewController {

    /// Notified when a code is scanned. Must be set before this screen is used.
    public weak var scannerDelegate: QRScannerDelegate!

    /// The view the camera preview layer is inserted into.
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?

    /// Adds `previewView`, builds the capture session, and starts the
    /// camera preview.
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        view.addSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if let captureSession = self.createCaptureSession() {
            self.captureSession = captureSession
            let previewLayer = self.createPreviewLayer(withCaptureSession: captureSession, view: previewView)
            previewView.layer.addSublayer(previewLayer)
            requestCaptureSessionStartRunning()
        }
    }

    /// Keeps the preview layer's frame in sync with `previewView`'s bounds
    /// across rotation/layout changes — it's a plain `CALayer`, not Auto
    /// Layout-managed, so this has to be done manually.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewView.layer.bounds
    }
    
    /// Starts the capture session if it isn't already running.
    func requestCaptureSessionStartRunning() {
        guard let captureSession = captureSession else {
            return
        }
        
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    /// Stops the capture session if it's currently running.
    func requestCaptureSessionStopRunning() {
        guard let captureSession = captureSession else {
            return
        }
        
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    /// Builds a preview layer sized to `view`'s bounds for `captureSession`.
    private func createPreviewLayer(withCaptureSession captureSession: AVCaptureSession, view: UIView) -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer = previewLayer
        return previewLayer
    }
    
    /// Builds a capture session on the default video device, outputting
    /// scanned metadata to `self`.
    ///
    /// - Returns: The configured session, or `nil` if no video device is
    ///   available or the input/output couldn't be attached.
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
    
    /// The barcode/QR symbologies this scanner recognizes.
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
    
    /// Presents an alert for a scan that didn't match a meter, resuming the
    /// capture session once dismissed.
    func showMeterScanErrorAlert(with message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.requestCaptureSessionStartRunning()
        }))
        present(alertController, animated: true, completion: nil)
    }
}

extension QrScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    /// Stops scanning and forwards the first detected code's string value
    /// to `scannerDelegate`.
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.requestCaptureSessionStopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard
                let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                let stringValue = readableObject.stringValue else {
                return
            }
            scannerDelegate.scannedCode(stringValue) { [weak self] (error) in
                if let error = error {
                    self?.showMeterScanErrorAlert(with: error.localizedDescription)
                }
            }
        }
    }
}
