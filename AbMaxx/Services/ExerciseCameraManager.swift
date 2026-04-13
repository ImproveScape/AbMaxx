import AVFoundation

class ExerciseCameraManager: NSObject {
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "exerciseCameraQueue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "videoProcessingQueue")

    nonisolated(unsafe) var frameHandler: ((CMSampleBuffer) -> Void)?
    private nonisolated(unsafe) var frameCount: Int = 0
    private var isConfigured = false

    func configure(position: AVCaptureDevice.Position = .front) {
        guard !isConfigured else { return }
        isConfigured = true
        sessionQueue.async { [weak self] in
            self?.setupSession(position: position)
        }
    }

    private func setupSession(position: AVCaptureDevice.Position) {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            if position == .front {
                connection.isVideoMirrored = true
            }
        }

        captureSession.commitConfiguration()
        captureSession.startRunning()
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.isConfigured = false
        }
    }
}

extension ExerciseCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCount += 1
        guard frameCount % 2 == 0 else { return }
        frameHandler?(sampleBuffer)
    }
}
