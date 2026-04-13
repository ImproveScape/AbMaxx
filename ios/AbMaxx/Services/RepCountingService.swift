import Foundation
import Vision

nonisolated enum RepPhase: Sendable {
    case neutral
    case contracting
    case contracted
    case releasing
}

nonisolated enum ExerciseMovementType: Sendable {
    case crunchBased
    case legRaiseBased
    case twistBased
    case vUpBased
    case plankHold
    case generic

    static func from(exerciseId: String) -> ExerciseMovementType {
        switch exerciseId {
        case "crunches", "sit_ups", "decline_crunch", "pulse_crunches", "weighted_crunch", "crunch_hold",
             "cable_crunch", "ab_rollout":
            return .crunchBased
        case "leg_raises", "hanging_leg_raises", "reverse_crunches", "flutter_kicks", "scissor_kicks",
             "toe_raise_lying", "bench_leg_raises", "reverse_crunch_pulse", "mountain_climbers":
            return .legRaiseBased
        case "russian_twists", "bicycle_crunch", "heel_taps", "windshield_wipers", "twisting_sit_ups",
             "oblique_crunch", "cross_body_mountain_climbers", "side_plank_dips":
            return .twistBased

        case "v_ups", "toe_touch_control":
            return .vUpBased
        case "plank", "side_plank", "hollow_hold", "l_sit_hold", "dead_bug", "bird_dog",
             "stomach_vacuum", "slow_mountain_climbers":
            return .plankHold
        default:
            return .generic
        }
    }

    var contractionThreshold: Double {
        switch self {
        case .crunchBased: return 12.0
        case .legRaiseBased: return 14.0
        case .twistBased: return 8.0
        case .vUpBased: return 16.0
        case .generic: return 12.0
        case .plankHold: return 0
        }
    }

    var fullROMAngle: Double {
        switch self {
        case .crunchBased: return 30.0
        case .legRaiseBased: return 40.0
        case .twistBased: return 22.0
        case .vUpBased: return 45.0
        case .generic: return 30.0
        case .plankHold: return 0
        }
    }

    var returnThreshold: Double {
        switch self {
        case .twistBased: return 0.50
        case .legRaiseBased: return 0.55
        default: return 0.55
        }
    }

    var minRepDuration: TimeInterval {
        switch self {
        case .crunchBased: return 0.6
        case .legRaiseBased: return 0.7
        case .twistBased: return 0.4
        case .vUpBased: return 0.7
        case .generic: return 0.6
        case .plankHold: return 0
        }
    }

    var maxRepDuration: TimeInterval {
        switch self {
        case .crunchBased: return 8.0
        case .legRaiseBased: return 10.0
        case .twistBased: return 6.0
        case .vUpBased: return 10.0
        case .generic: return 8.0
        case .plankHold: return 0
        }
    }

    var startMovementThreshold: Double {
        switch self {
        case .twistBased: return 0.35
        default: return 0.40
        }
    }

    var velocityStartThreshold: Double {
        switch self {
        case .twistBased: return 0.3
        default: return 0.4
        }
    }

    var stableFramesForStart: Int {
        switch self {
        case .twistBased: return 2
        default: return 3
        }
    }

    var stableFramesForPeak: Int {
        return 2
    }

    var stableFramesForReturn: Int {
        return 2
    }
}

nonisolated struct FormFeedback: Sendable {
    let message: String
    let quality: FormQuality
}

nonisolated enum FormQuality: Sendable {
    case good
    case warning
    case bad
}

private enum RepState {
    case calibrating
    case idle
    case contracting
    case peaked
    case returning
}

@Observable
class RepCountingService {
    var repCount: Int = 0
    var phase: RepPhase = .neutral
    var movementProgress: Double = 0
    var formFeedback: FormFeedback?

    private var movementType: ExerciseMovementType = .generic
    private var exerciseId: String = ""

    private var angleBuffer: [Double] = []
    private let smoothingBufferSize = 10
    private var smoothedAngle: Double = 0
    private var prevSmoothed: Double = 0

    private var baselineAngle: Double?
    private var baselineFrames: [Double] = []
    private let baselineFrameCount = 15

    private var repState: RepState = .calibrating
    private var contractionStartAngle: Double = 0
    private var peakDeflection: Double = 0
    private var lastRepTime: Date = .distantPast

    private var calibratedRange: Double = 0
    private var completedReps: Int = 0

    private var velocityBuffer: [Double] = []
    private let velocityBufferSize = 5
    private var stableFrameCount: Int = 0

    private var contractionDirection: Double = 0
    private var repStartTime: Date = .distantPast
    private var noMovementFrames: Int = 0

    private var peakHoldFrames: Int = 0
    private let minPeakHoldFrames = 2

    private var lastProcessTime: Date = .distantPast
    private var rawAngleHistory: [Double] = []
    private let rawHistorySize = 20

    func configure(for exerciseId: String) {
        self.exerciseId = exerciseId
        movementType = ExerciseMovementType.from(exerciseId: exerciseId)
        reset()
    }

    func reset() {
        repCount = 0
        phase = .neutral
        movementProgress = 0
        formFeedback = nil
        angleBuffer.removeAll()
        smoothedAngle = 0
        prevSmoothed = 0
        baselineAngle = nil
        baselineFrames.removeAll()
        repState = .calibrating
        contractionStartAngle = 0
        peakDeflection = 0
        lastRepTime = .distantPast
        calibratedRange = 0
        completedReps = 0
        velocityBuffer.removeAll()
        stableFrameCount = 0
        contractionDirection = 0
        repStartTime = .distantPast
        noMovementFrames = 0
        peakHoldFrames = 0
        lastProcessTime = .distantPast
        rawAngleHistory.removeAll()
    }

    func processPose(_ pose: DetectedPose) {
        guard movementType != .plankHold else {
            analyzeHoldForm(pose)
            return
        }

        guard let rawAngle = extractAngle(from: pose) else { return }

        rawAngleHistory.append(rawAngle)
        if rawAngleHistory.count > rawHistorySize {
            rawAngleHistory.removeFirst()
        }

        angleBuffer.append(rawAngle)
        if angleBuffer.count > smoothingBufferSize {
            angleBuffer.removeFirst()
        }
        guard angleBuffer.count >= 5 else { return }

        prevSmoothed = smoothedAngle
        smoothedAngle = medianSmooth(angleBuffer)

        let velocity = smoothedAngle - prevSmoothed
        velocityBuffer.append(velocity)
        if velocityBuffer.count > velocityBufferSize {
            velocityBuffer.removeFirst()
        }
        let smoothedVelocity = velocityBuffer.reduce(0, +) / Double(velocityBuffer.count)

        if repState == .calibrating {
            baselineFrames.append(smoothedAngle)
            if baselineFrames.count >= baselineFrameCount {
                let sorted = baselineFrames.sorted()
                let trimCount = baselineFrames.count / 4
                let trimmed = Array(sorted[trimCount..<(baselineFrames.count - trimCount)])
                baselineAngle = trimmed.reduce(0, +) / Double(trimmed.count)

                let variance = trimmed.map { ($0 - baselineAngle!) * ($0 - baselineAngle!) }.reduce(0, +) / Double(trimmed.count)
                if variance > 100 {
                    baselineFrames.removeAll()
                    return
                }
                repState = .idle
            }
            return
        }

        guard let baseline = baselineAngle else { return }

        let deflection = smoothedAngle - baseline
        let absDeflection = abs(deflection)
        let threshold = movementType.contractionThreshold

        let effectiveRange = calibratedRange > 0 ? calibratedRange : movementType.fullROMAngle
        movementProgress = min(1.0, absDeflection / max(effectiveRange, 1))

        processStateMachine(
            deflection: deflection,
            absDeflection: absDeflection,
            velocity: smoothedVelocity,
            threshold: threshold
        )

        analyzeRepForm(pose)
    }

    private func medianSmooth(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let count = sorted.count
        if count >= 6 {
            let trimCount = count / 4
            let trimmed = Array(sorted[trimCount..<(count - trimCount)])
            return trimmed.reduce(0, +) / Double(trimmed.count)
        } else {
            return sorted[count / 2]
        }
    }

    private func processStateMachine(
        deflection: Double,
        absDeflection: Double,
        velocity: Double,
        threshold: Double
    ) {
        let absVelocity = abs(velocity)

        switch repState {
        case .calibrating:
            break

        case .idle:
            phase = .neutral

            let movementStartThreshold = threshold * movementType.startMovementThreshold
            if absDeflection > movementStartThreshold && absVelocity > movementType.velocityStartThreshold {
                stableFrameCount += 1
                if stableFrameCount >= movementType.stableFramesForStart {
                    repState = .contracting
                    contractionStartAngle = smoothedAngle
                    contractionDirection = deflection > 0 ? 1.0 : -1.0
                    peakDeflection = absDeflection
                    repStartTime = Date()
                    stableFrameCount = 0
                    noMovementFrames = 0
                    peakHoldFrames = 0
                }
            } else {
                stableFrameCount = max(0, stableFrameCount - 1)
            }

        case .contracting:
            phase = .contracting

            let directionalDeflection = deflection * contractionDirection
            if directionalDeflection > 0 && absDeflection > peakDeflection {
                peakDeflection = absDeflection
                noMovementFrames = 0
            }

            if peakDeflection >= threshold {
                let velocityInDir = velocity * contractionDirection
                if velocityInDir < -movementType.velocityStartThreshold * 0.5 {
                    stableFrameCount += 1
                    if stableFrameCount >= movementType.stableFramesForPeak {
                        repState = .peaked
                        stableFrameCount = 0
                        peakHoldFrames = 0
                    }
                } else if absVelocity < movementType.velocityStartThreshold * 0.3 && peakDeflection >= threshold {
                    peakHoldFrames += 1
                    if peakHoldFrames >= minPeakHoldFrames + 2 {
                        repState = .peaked
                        stableFrameCount = 0
                        peakHoldFrames = 0
                    }
                } else {
                    stableFrameCount = max(0, stableFrameCount - 1)
                }
            }

            let elapsed = Date().timeIntervalSince(repStartTime)
            if elapsed > movementType.maxRepDuration {
                resetToIdle()
            } else if absDeflection < threshold * 0.2 && peakDeflection < threshold {
                noMovementFrames += 1
                if noMovementFrames >= 8 {
                    resetToIdle()
                }
            } else {
                noMovementFrames = max(0, noMovementFrames - 1)
            }

        case .peaked:
            phase = .contracted

            if absDeflection > peakDeflection {
                peakDeflection = absDeflection
            }

            let returnRatio = 1.0 - (absDeflection / max(peakDeflection, 1))
            let neededReturn = movementType.returnThreshold

            if returnRatio >= neededReturn * 0.7 {
                stableFrameCount += 1
                if stableFrameCount >= movementType.stableFramesForReturn {
                    repState = .returning
                    stableFrameCount = 0
                }
            } else {
                stableFrameCount = max(0, stableFrameCount - 1)
            }

        case .returning:
            phase = .releasing

            let returnRatio = 1.0 - (absDeflection / max(peakDeflection, 1))

            if returnRatio >= movementType.returnThreshold {
                let now = Date()
                let sinceLastRep = now.timeIntervalSince(lastRepTime)
                let repDuration = now.timeIntervalSince(repStartTime)

                if sinceLastRep >= movementType.minRepDuration
                    && repDuration >= movementType.minRepDuration
                    && repDuration <= movementType.maxRepDuration
                    && peakDeflection >= threshold {
                    repCount += 1
                    lastRepTime = now
                    completedReps += 1

                    if completedReps <= 3 {
                        calibratedRange = calibratedRange == 0
                            ? peakDeflection
                            : (calibratedRange * 0.5 + peakDeflection * 0.5)
                    } else {
                        calibratedRange = calibratedRange * 0.8 + peakDeflection * 0.2
                    }
                }

                resetToIdle()
            }

            if absDeflection > peakDeflection * 0.9 {
                repState = .peaked
                stableFrameCount = 0
                phase = .contracted
            }

            let elapsed = Date().timeIntervalSince(repStartTime)
            if elapsed > movementType.maxRepDuration {
                resetToIdle()
            }
        }
    }

    private func resetToIdle() {
        repState = .idle
        peakDeflection = 0
        stableFrameCount = 0
        noMovementFrames = 0
        peakHoldFrames = 0
        phase = .neutral
    }

    private func extractAngle(from pose: DetectedPose) -> Double? {
        switch movementType {
        case .crunchBased:
            return crunchAngle(pose)
        case .legRaiseBased:
            return legRaiseAngle(pose)
        case .twistBased:
            return twistAngle(pose)
        case .vUpBased:
            return vUpAngle(pose)
        case .plankHold:
            return nil
        case .generic:
            return genericAngle(pose)
        }
    }

    private func crunchAngle(_ pose: DetectedPose) -> Double? {
        guard let shoulder = avgPoint(pose, .leftShoulder, .rightShoulder),
              let hip = avgPoint(pose, .leftHip, .rightHip) ?? pose.pointStable(for: .root) else { return nil }

        if let knee = avgPoint(pose, .leftKnee, .rightKnee) {
            let angle = angleBetween(a: shoulder, b: hip, c: knee)
            let shoulderHipDist = distance(shoulder, hip)
            let hipKneeDist = distance(hip, knee)
            guard shoulderHipDist > 0.03 && hipKneeDist > 0.03 else { return nil }
            return angle
        }

        let verticalRef = CGPoint(x: hip.x, y: hip.y + 0.3)
        return angleBetween(a: shoulder, b: hip, c: verticalRef)
    }

    private func legRaiseAngle(_ pose: DetectedPose) -> Double? {
        guard let hip = avgPoint(pose, .leftHip, .rightHip) ?? pose.pointStable(for: .root) else { return nil }

        if let knee = avgPoint(pose, .leftKnee, .rightKnee),
           let shoulder = avgPoint(pose, .leftShoulder, .rightShoulder) {
            let hipKneeDist = distance(hip, knee)
            let shoulderHipDist = distance(shoulder, hip)
            guard hipKneeDist > 0.03 && shoulderHipDist > 0.03 else { return nil }
            return angleBetween(a: knee, b: hip, c: shoulder)
        }

        if let ankle = avgPoint(pose, .leftAnkle, .rightAnkle),
           let shoulder = avgPoint(pose, .leftShoulder, .rightShoulder) {
            return angleBetween(a: ankle, b: hip, c: shoulder)
        }

        return nil
    }

    private func twistAngle(_ pose: DetectedPose) -> Double? {
        guard let leftShoulder = pose.pointStable(for: .leftShoulder),
              let rightShoulder = pose.pointStable(for: .rightShoulder),
              let leftHip = pose.pointStable(for: .leftHip),
              let rightHip = pose.pointStable(for: .rightHip) else { return nil }

        let shoulderDist = distance(leftShoulder, rightShoulder)
        let hipDist = distance(leftHip, rightHip)
        guard shoulderDist > 0.02 && hipDist > 0.02 else { return nil }

        let shoulderAngle = atan2(rightShoulder.y - leftShoulder.y,
                                   rightShoulder.x - leftShoulder.x)
        let hipAngle = atan2(rightHip.y - leftHip.y,
                              rightHip.x - leftHip.x)
        return (shoulderAngle - hipAngle) * (180.0 / .pi)
    }

    private func vUpAngle(_ pose: DetectedPose) -> Double? {
        guard let shoulder = avgPoint(pose, .leftShoulder, .rightShoulder),
              let hip = avgPoint(pose, .leftHip, .rightHip) ?? pose.pointStable(for: .root),
              let ankle = avgPoint(pose, .leftAnkle, .rightAnkle) else { return nil }
        let shoulderHipDist = distance(shoulder, hip)
        let hipAnkleDist = distance(hip, ankle)
        guard shoulderHipDist > 0.03 && hipAnkleDist > 0.03 else { return nil }
        return angleBetween(a: shoulder, b: hip, c: ankle)
    }

    private func genericAngle(_ pose: DetectedPose) -> Double? {
        if let angle = crunchAngle(pose) { return angle }
        guard let neck = bestPoint(pose, .neck, .nose),
              let hip = avgPoint(pose, .leftHip, .rightHip) ?? pose.pointStable(for: .root),
              let knee = avgPoint(pose, .leftKnee, .rightKnee) else { return nil }
        let neckHipDist = distance(neck, hip)
        let hipKneeDist = distance(hip, knee)
        guard neckHipDist > 0.03 && hipKneeDist > 0.03 else { return nil }
        return angleBetween(a: neck, b: hip, c: knee)
    }

    private func avgPoint(_ pose: DetectedPose, _ a: VNHumanBodyPoseObservation.JointName, _ b: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        let pa = pose.pointStable(for: a)
        let pb = pose.pointStable(for: b)
        if let pa, let pb {
            return CGPoint(x: (pa.x + pb.x) / 2, y: (pa.y + pb.y) / 2)
        }
        return pa ?? pb
    }

    private func bestPoint(_ pose: DetectedPose, _ primary: VNHumanBodyPoseObservation.JointName, _ fallback: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        if let p = pose.pointStable(for: primary) { return p }
        return pose.pointStable(for: fallback)
    }

    private func angleBetween(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
        let ba = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let bc = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = ba.dx * bc.dx + ba.dy * bc.dy
        let magBA = sqrt(ba.dx * ba.dx + ba.dy * ba.dy)
        let magBC = sqrt(bc.dx * bc.dx + bc.dy * bc.dy)
        guard magBA > 0.001, magBC > 0.001 else { return 0 }
        let cosAngle = max(-1, min(1, dot / (magBA * magBC)))
        return acos(cosAngle) * (180.0 / .pi)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }

    private func analyzeRepForm(_ pose: DetectedPose) {
        switch movementType {
        case .crunchBased:
            analyzeCrunchForm(pose)
        case .legRaiseBased:
            analyzeLegRaiseForm(pose)
        case .twistBased:
            analyzeTwistForm(pose)
        default:
            if phase == .contracted {
                formFeedback = FormFeedback(message: "Good form!", quality: .good)
            } else if phase == .neutral {
                formFeedback = nil
            }
        }
    }

    private func analyzeCrunchForm(_ pose: DetectedPose) {
        if let neck = bestPoint(pose, .neck, .nose),
           let leftWrist = pose.pointStable(for: .leftWrist),
           let rightWrist = pose.pointStable(for: .rightWrist) {
            let wristMidY = (leftWrist.y + rightWrist.y) / 2
            if abs(wristMidY - neck.y) < 0.03 && phase == .contracting {
                formFeedback = FormFeedback(message: "Don't pull your neck", quality: .warning)
                return
            }
        }

        if phase == .contracted {
            formFeedback = FormFeedback(message: "Good squeeze!", quality: .good)
        } else if phase == .neutral {
            formFeedback = nil
        }
    }

    private func analyzeLegRaiseForm(_ pose: DetectedPose) {
        if let leftHip = pose.pointStable(for: .leftHip),
           let rightHip = pose.pointStable(for: .rightHip),
           let shoulder = bestPoint(pose, .leftShoulder, .rightShoulder) {
            let hipMidY = (leftHip.y + rightHip.y) / 2
            if hipMidY > shoulder.y + 0.1 && phase == .contracting {
                formFeedback = FormFeedback(message: "Keep lower back flat", quality: .warning)
                return
            }
        }

        if phase == .contracted {
            formFeedback = FormFeedback(message: "Control the descent", quality: .good)
        } else if phase == .neutral {
            formFeedback = nil
        }
    }

    private func analyzeTwistForm(_ pose: DetectedPose) {
        if phase == .contracted {
            formFeedback = FormFeedback(message: "Full rotation!", quality: .good)
        } else if phase == .contracting {
            formFeedback = FormFeedback(message: "Rotate from your core", quality: .good)
        } else {
            formFeedback = nil
        }
    }

    private func analyzeHoldForm(_ pose: DetectedPose) {
        guard let shoulder = bestPoint(pose, .leftShoulder, .rightShoulder),
              let hip = avgPoint(pose, .leftHip, .rightHip) ?? pose.pointStable(for: .root),
              let ankle = bestPoint(pose, .leftAnkle, .rightAnkle) else {
            formFeedback = FormFeedback(message: "Get in position", quality: .warning)
            return
        }

        let bodyAngle = angleBetween(a: shoulder, b: hip, c: ankle)

        if exerciseId == "plank" || exerciseId == "side_plank" {
            if bodyAngle < 150 {
                formFeedback = FormFeedback(message: "Hips are sagging — lift up", quality: .bad)
            } else if bodyAngle > 190 {
                formFeedback = FormFeedback(message: "Hips too high — lower them", quality: .warning)
            } else {
                formFeedback = FormFeedback(message: "Perfect form — hold it!", quality: .good)
            }
        } else {
            if bodyAngle > 160 {
                formFeedback = FormFeedback(message: "Good position", quality: .good)
            } else {
                formFeedback = FormFeedback(message: "Tighten your core", quality: .warning)
            }
        }
    }
}
