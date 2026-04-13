@preconcurrency import AVFoundation
import UIKit

class FoodCameraManager: NSObject {
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "foodCameraQueue")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true
        sessionQueue.async { [weak self] in
            self?.setupSession()
        }
    }

    private func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        for input in captureSession.inputs { captureSession.removeInput(input) }
        for output in captureSession.outputs { captureSession.removeOutput(output) }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) { captureSession.addInput(input) }
        if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }

        captureSession.commitConfiguration()
        captureSession.startRunning()
    }

    func capturePhoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            photoContinuation = continuation
            let settings = AVCapturePhotoSettings()
            sessionQueue.async { [weak self] in
                guard let self else {
                    Task { @MainActor in continuation.resume(returning: nil) }
                    return
                }
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func toggleFlash(_ on: Bool) {
        sessionQueue.async { [weak self] in
            guard let self,
                  let device = (self.captureSession.inputs.first as? AVCaptureDeviceInput)?.device,
                  device.hasTorch else { return }
            try? device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if let device = (self.captureSession.inputs.first as? AVCaptureDeviceInput)?.device, device.hasTorch {
                try? device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.isConfigured = false
        }
    }
}

extension FoodCameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let image: UIImage?
        if let data = photo.fileDataRepresentation() {
            image = UIImage(data: data)
        } else {
            image = nil
        }
        Task { @MainActor [weak self] in
            self?.photoContinuation?.resume(returning: image)
            self?.photoContinuation = nil
        }
    }
}
