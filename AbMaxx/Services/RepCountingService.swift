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
             "cable_crunch", "ab_rollout", "machine_crunch", "smith_machine_crunch", "ghd_sit_up",
             "ab_wheel_rollout_standing":
            return .crunchBased
        case "leg_raises", "hanging_leg_raises", "reverse_crunches", "flutter_kicks", "scissor_kicks",
             "toe_raise_lying", "bench_leg_raises", "reverse_crunch_pulse", "mountain_climbers",
             "cable_reverse_crunch":
            return .legRaiseBased
        case "russian_twists", "bicycle_crunch", "heel_taps", "windshield_wipers", "twisting_sit_ups",
             "oblique_crunch", "cross_body_mountain_climbers", "side_plank_dips",
             "landmine_rotation", "cable_low_to_high_chop":
            return .twistBased
        case "cable_pallof_press", "cable_dead_bug":
            return .plankHold
        case "v_ups", "toe_touch_control":
            return .vUpBased
        case "plank", "side_plank", "hollow_hold", "l_sit_hold", "dead_bug", "bird_dog",
             "stomach_vacuum", "slow_mountain_climbers":
            return .plankHold
        default:
            return .generic
        }
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

@Observable
class RepCountingService {
    var repCount: Int = 0
    var phase: RepPhase = .neutral
    var movementProgress: Double = 0
    var formFeedback: FormFeedback?

    private var movementType: ExerciseMovementType = .generic
    private var exerciseId: String = ""

    private var angleBuffer: [Double] = []
    private let bufferSize = 8
    private var smoothedAngle: Double = 0
    private var prevSmoothed: Double = 0

    private var baselineAngle: Double?
    private var baselineFrames: [Double] = []
    private let baselineCount = 5

    private var peakAngle: Double = 0
    private var valleyAngle: Double = 0
    private var trackingDirection: Direction = .unknown
    private var lastRepTime: Date = .distantPast
    private let minRepInterval: TimeInterval = 0.4
    private var repStartAngle: Double = 0
    private var maxDeflection: Double = 0

    private enum Direction {
        case unknown, goingUp, goingDown
    }

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
        peakAngle = 0
        valleyAngle = 0
        trackingDirection = .unknown
        lastRepTime = .distantPast
        repStartAngle = 0
        maxDeflection = 0
    }

    func processPose(_ pose: DetectedPose) {
        guard movementType != .plankHold else {
            analyzeHoldForm(pose)
            return
        }

        guard let rawAngle = extractAngle(from: pose) else { return }

        angleBuffer.append(rawAngle)
        if angleBuffer.count > bufferSize {
            angleBuffer.removeFirst()
        }

        prevSmoothed = smoothedAngle
        smoothedAngle = angleBuffer.reduce(0, +) / Double(angleBuffer.count)

        if baselineAngle == nil {
            baselineFrames.append(smoothedAngle)
            if baselineFrames.count >= baselineCount {
                baselineAngle = baselineFrames.reduce(0, +) / Double(baselineFrames.count)
                valleyAngle = baselineAngle!
                peakAngle = baselineAngle!
            }
            return
        }

        let deflection = smoothedAngle - (baselineAngle ?? 0)
        let absDeflection = abs(deflection)
        maxDeflection = max(maxDeflection, absDeflection)

        let minMovement: Double = 12.0
        let threshold = max(minMovement, maxDeflection * 0.3)

        movementProgress = min(1.0, absDeflection / max(threshold * 2, 1))

        let delta = smoothedAngle - prevSmoothed
        let significantDelta: Double = 0.3

        if abs(delta) > significantDelta {
            let newDirection: Direction = delta > 0 ? .goingUp : .goingDown

            if trackingDirection != .unknown && newDirection != trackingDirection {
                let range = abs(peakAngle - valleyAngle)

                if range > threshold {
                    let now = Date()
                    if now.timeIntervalSince(lastRepTime) > minRepInterval {
                        repCount += 1
                        lastRepTime = now

                        if maxDeflection < range * 1.5 {
                            maxDeflection = range
                        }
                    }
                }

                if newDirection == .goingUp {
                    valleyAngle = smoothedAngle
                } else {
                    peakAngle = smoothedAngle
                }
            }

            if newDirection == .goingUp {
                peakAngle = max(peakAngle, smoothedAngle)
                if trackingDirection == .goingDown || trackingDirection == .unknown {
                    valleyAngle = smoothedAngle
                }
            } else {
                valleyAngle = min(valleyAngle, smoothedAngle)
                if trackingDirection == .goingUp || trackingDirection == .unknown {
                    peakAngle = smoothedAngle
                }
            }

            trackingDirection = newDirection
        }

        updatePhase(absDeflection: absDeflection, threshold: threshold)
        analyzeRepForm(pose)
    }

    private func updatePhase(absDeflection: Double, threshold: Double) {
        if absDeflection < threshold * 0.3 {
            phase = .neutral
        } else if absDeflection < threshold {
            phase = smoothedAngle > prevSmoothed ? .contracting : .releasing
        } else {
            phase = .contracted
        }
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

    // MARK: - Angle Metrics

    private func crunchAngle(_ pose: DetectedPose) -> Double? {
        guard let shoulder = bestPoint(pose, .leftShoulder, .rightShoulder),
              let hip = bestPoint(pose, .root, .leftHip),
              let knee = bestPoint(pose, .leftKnee, .rightKnee) else { return nil }
        return angleBetween(a: shoulder, b: hip, c: knee)
    }

    private func legRaiseAngle(_ pose: DetectedPose) -> Double? {
        guard let hip = bestPoint(pose, .root, .leftHip),
              let knee = bestPoint(pose, .leftKnee, .rightKnee),
              let shoulder = bestPoint(pose, .leftShoulder, .rightShoulder) else { return nil }
        return angleBetween(a: knee, b: hip, c: shoulder)
    }

    private func twistAngle(_ pose: DetectedPose) -> Double? {
        guard let leftShoulder = pose.point(for: .leftShoulder),
              let rightShoulder = pose.point(for: .rightShoulder),
              let leftHip = pose.point(for: .leftHip),
              let rightHip = pose.point(for: .rightHip) else { return nil }
        let shoulderAngle = atan2(rightShoulder.y - leftShoulder.y,
                                   rightShoulder.x - leftShoulder.x)
        let hipAngle = atan2(rightHip.y - leftHip.y,
                              rightHip.x - leftHip.x)
        return (shoulderAngle - hipAngle) * (180.0 / .pi)
    }

    private func vUpAngle(_ pose: DetectedPose) -> Double? {
        guard let shoulder = bestPoint(pose, .leftShoulder, .rightShoulder),
              let hip = bestPoint(pose, .root, .leftHip),
              let ankle = bestPoint(pose, .leftAnkle, .rightAnkle) else { return nil }
        return angleBetween(a: shoulder, b: hip, c: ankle)
    }

    private func genericAngle(_ pose: DetectedPose) -> Double? {
        if let angle = crunchAngle(pose) { return angle }
        guard let neck = bestPoint(pose, .neck, .nose),
              let hip = bestPoint(pose, .root, .leftHip),
              let knee = bestPoint(pose, .leftKnee, .rightKnee) else { return nil }
        return angleBetween(a: neck, b: hip, c: knee)
    }

    private func bestPoint(_ pose: DetectedPose, _ primary: VNHumanBodyPoseObservation.JointName, _ fallback: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        if let p = pose.point(for: primary) { return p }
        return pose.point(for: fallback)
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

    // MARK: - Form Analysis

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
           let leftWrist = pose.point(for: .leftWrist),
           let rightWrist = pose.point(for: .rightWrist) {
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
        if let leftHip = pose.point(for: .leftHip),
           let rightHip = pose.point(for: .rightHip),
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
              let hip = bestPoint(pose, .root, .leftHip),
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
