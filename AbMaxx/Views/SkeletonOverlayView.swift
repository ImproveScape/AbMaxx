import SwiftUI
import Vision

struct SkeletonOverlayView: View {
    let pose: DetectedPose?
    let viewSize: CGSize

    private let skeletonColor = Color(red: 0.0, green: 0.85, blue: 1.0)
    private let jointColor = Color(red: 1.0, green: 0.85, blue: 0.0)
    private let lineWidth: CGFloat = 4

    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.nose, .neck),
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
        (.leftShoulder, .rightShoulder),
        (.nose, .leftEye), (.nose, .rightEye),
        (.leftEye, .leftEar), (.rightEye, .rightEar),
    ]

    private let jointNames: [VNHumanBodyPoseObservation.JointName] = [
        .nose, .leftEye, .rightEye, .leftEar, .rightEar,
        .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
        .leftWrist, .rightWrist, .leftHip, .rightHip,
        .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
        .neck, .root
    ]

    var body: some View {
        Canvas { context, size in
            guard let pose else { return }

            for (from, to) in connections {
                guard let p1 = pose.screenPoint(for: from, in: size),
                      let p2 = pose.screenPoint(for: to, in: size) else { continue }

                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)

                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [skeletonColor, skeletonColor.opacity(0.7)]),
                        startPoint: p1,
                        endPoint: p2
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

                context.stroke(
                    path,
                    with: .color(skeletonColor.opacity(0.3)),
                    style: StrokeStyle(lineWidth: lineWidth + 6, lineCap: .round)
                )
            }

            for name in jointNames {
                guard let point = pose.screenPoint(for: name, in: size) else { continue }

                let majorJoints: Set<VNHumanBodyPoseObservation.JointName> = [
                    .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
                    .leftWrist, .rightWrist, .leftHip, .rightHip,
                    .leftKnee, .rightKnee, .leftAnkle, .rightAnkle
                ]
                let isMajor = majorJoints.contains(name)
                let radius: CGFloat = isMajor ? 8 : 5

                let glowRect = CGRect(
                    x: point.x - radius * 2,
                    y: point.y - radius * 2,
                    width: radius * 4,
                    height: radius * 4
                )
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(skeletonColor.opacity(0.2))
                )

                let outerRect = CGRect(
                    x: point.x - radius,
                    y: point.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.fill(
                    Circle().path(in: outerRect),
                    with: .color(isMajor ? jointColor : skeletonColor)
                )

                let innerRadius = radius * 0.5
                let innerRect = CGRect(
                    x: point.x - innerRadius,
                    y: point.y - innerRadius,
                    width: innerRadius * 2,
                    height: innerRadius * 2
                )
                context.fill(
                    Circle().path(in: innerRect),
                    with: .color(.white)
                )
            }
        }
        .allowsHitTesting(false)
    }
}
