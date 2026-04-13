import AVFoundation

class ExerciseCameraManager: NSObject {
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "exerciseCameraQueue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "videoProcessingQueue")

    nonisolated(unsafe) var frameHandler: ((CMSampleBuffer) -> Void)?
    private nonisolated(unsafe) var frameCount: Int = 0
    private nonisolated(unsafe) var frameSkip: Int = 2
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
        captureSession.sessionPreset = .medium

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

        try? camera.lockForConfiguration()
        if camera.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= 30 }) {
            camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
            camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
        }
        camera.unlockForConfiguration()

        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]

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
            self.frameCount = 0
        }
    }
}

extension ExerciseCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCount += 1
        guard frameCount % frameSkip == 0 else { return }
        frameHandler?(sampleBuffer)
    }
}
