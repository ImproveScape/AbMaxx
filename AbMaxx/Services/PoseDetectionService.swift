import AVFoundation
import Vision

nonisolated struct DetectedPose: Sendable {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let confidences: [VNHumanBodyPoseObservation.JointName: Float]
    let timestamp: TimeInterval

    func point(for joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        guard let conf = confidences[joint], conf > 0.2 else { return nil }
        return joints[joint]
    }

    func screenPoint(for joint: VNHumanBodyPoseObservation.JointName, in size: CGSize) -> CGPoint? {
        guard let p = point(for: joint) else { return nil }
        return CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
    }

    var hasEnoughJoints: Bool {
        let requiredJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftHip, .rightHip
        ]
        let detected = requiredJoints.filter { point(for: $0) != nil }.count
        return detected >= 3
    }

    var visibleJointCount: Int {
        confidences.values.filter { $0 > 0.2 }.count
    }
}

nonisolated class PoseDetectionService: NSObject, @unchecked Sendable {
    private let onPoseDetected: @Sendable (DetectedPose?) -> Void

    init(onPoseDetected: @escaping @Sendable (DetectedPose?) -> Void) {
        self.onPoseDetected = onPoseDetected
    }

    func detectPose(in sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            onPoseDetected(nil)
            return
        }

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)

        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                onPoseDetected(nil)
                return
            }

            let jointNames: [VNHumanBodyPoseObservation.JointName] = [
                .nose, .leftEye, .rightEye, .leftEar, .rightEar,
                .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
                .leftWrist, .rightWrist, .leftHip, .rightHip,
                .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
                .neck, .root
            ]

            var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
            var confidences: [VNHumanBodyPoseObservation.JointName: Float] = [:]

            for name in jointNames {
                if let point = try? observation.recognizedPoint(name) {
                    joints[name] = point.location
                    confidences[name] = point.confidence
                }
            }

            let pose = DetectedPose(
                joints: joints,
                confidences: confidences,
                timestamp: CACurrentMediaTime()
            )

            if pose.hasEnoughJoints {
                onPoseDetected(pose)
            } else {
                onPoseDetected(nil)
            }
        } catch {
            onPoseDetected(nil)
        }
    }
}
