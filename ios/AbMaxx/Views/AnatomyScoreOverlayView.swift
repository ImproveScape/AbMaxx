import SwiftUI

struct AnatomyScoreOverlayView: View {
    let upperAbsScore: Int
    let lowerAbsScore: Int
    let obliquesScore: Int
    let vTaperScore: Int
    let deepCoreScore: Int

    private let bodyOutlineURL: URL? = URL(string: "https://r2-pub.rork.com/projects/ef37pg3laezo1t2hj7mt0/assets/41ef9665-b339-47e4-ab53-b264826c1930.png")

    var body: some View {
        cardBackground
            .aspectRatio(1.0, contentMode: .fit)
            .overlay {
                Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
                    drawZoneFills(context: &context, size: size)
                }
                .allowsHitTesting(false)
            }
            .overlay {
                AsyncImage(url: bodyOutlineURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fit)
                            .blendMode(.screen)
                            .allowsHitTesting(false)
                    case .empty:
                        EmptyView()
                    case .failure:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .compositingGroup()
            .clipShape(.rect(cornerRadius: 14))
            .padding(20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Anatomy score diagram")
        }

    private var cardBackground: Color {
        Color(.sRGB, red: 10.0 / 255.0, green: 10.0 / 255.0, blue: 10.0 / 255.0, opacity: 1.0)
    }

    private func drawZoneFills(context: inout GraphicsContext, size: CGSize) {
        let upperAbs: [Path] = upperAbsPaths(size: size)
        let lowerAbs: [Path] = lowerAbsPaths(size: size)
        let leftOblique: Path = obliquePath(side: .left, size: size)
        let rightOblique: Path = obliquePath(side: .right, size: size)
        let leftVTaper: Path = vTaperPath(side: .left, size: size)
        let rightVTaper: Path = vTaperPath(side: .right, size: size)
        let deepCore: Path = deepCorePath(size: size)

        for path in upperAbs {
            context.fill(path, with: .color(zoneColor(for: upperAbsScore).opacity(0.92)))
        }

        for path in lowerAbs {
            context.fill(path, with: .color(zoneColor(for: lowerAbsScore).opacity(0.92)))
        }

        context.fill(leftOblique, with: .color(zoneColor(for: obliquesScore).opacity(0.82)))
        context.fill(rightOblique, with: .color(zoneColor(for: obliquesScore).opacity(0.82)))
        context.fill(leftVTaper, with: .color(zoneColor(for: vTaperScore).opacity(0.80)))
        context.fill(rightVTaper, with: .color(zoneColor(for: vTaperScore).opacity(0.80)))
        context.fill(deepCore, with: .color(zoneColor(for: deepCoreScore).opacity(0.48)))
    }

    private func upperAbsPaths(size: CGSize) -> [Path] {
        [
            muscleBlockPath(
                in: normalizedRect(0.383, 0.438, 0.106, 0.080, in: size),
                side: .left,
                topInset: size.width * 0.008,
                bottomInset: size.width * 0.008,
                topCurveLift: size.width * 0.008,
                bottomCurveDrop: size.width * 0.010
            ),
            muscleBlockPath(
                in: normalizedRect(0.511, 0.438, 0.106, 0.080, in: size),
                side: .right,
                topInset: size.width * 0.008,
                bottomInset: size.width * 0.008,
                topCurveLift: size.width * 0.008,
                bottomCurveDrop: size.width * 0.010
            ),
            muscleBlockPath(
                in: normalizedRect(0.387, 0.533, 0.102, 0.085, in: size),
                side: .left,
                topInset: size.width * 0.007,
                bottomInset: size.width * 0.008,
                topCurveLift: size.width * 0.008,
                bottomCurveDrop: size.width * 0.010
            ),
            muscleBlockPath(
                in: normalizedRect(0.511, 0.533, 0.102, 0.085, in: size),
                side: .right,
                topInset: size.width * 0.007,
                bottomInset: size.width * 0.008,
                topCurveLift: size.width * 0.008,
                bottomCurveDrop: size.width * 0.010
            )
        ]
    }

    private func lowerAbsPaths(size: CGSize) -> [Path] {
        [
            muscleBlockPath(
                in: normalizedRect(0.391, 0.626, 0.098, 0.086, in: size),
                side: .left,
                topInset: size.width * 0.006,
                bottomInset: size.width * 0.008,
                topCurveLift: size.width * 0.007,
                bottomCurveDrop: size.width * 0.012
            ),
            muscleBlockPath(
                in: normalizedRect(0.511, 0.626, 0.098, 0.086, in: size),
                side: .right,
                topInset: size.width * 0.006,
                bottomInset: size.width * 0.008,
                topCurveLift: size.width * 0.007,
                bottomCurveDrop: size.width * 0.012
            ),
            muscleBlockPath(
                in: normalizedRect(0.395, 0.725, 0.096, 0.112, in: size),
                side: .left,
                topInset: size.width * 0.006,
                bottomInset: size.width * 0.020,
                topCurveLift: size.width * 0.007,
                bottomCurveDrop: size.width * 0.018
            ),
            muscleBlockPath(
                in: normalizedRect(0.509, 0.725, 0.096, 0.112, in: size),
                side: .right,
                topInset: size.width * 0.006,
                bottomInset: size.width * 0.020,
                topCurveLift: size.width * 0.007,
                bottomCurveDrop: size.width * 0.018
            )
        ]
    }

    private func obliquePath(side: DiagramSide, size: CGSize) -> Path {
        var path: Path = Path()
        path.move(to: point(mirroredX(0.292, side: side), 0.356, in: size))
        path.addCurve(
            to: point(mirroredX(0.262, side: side), 0.454, in: size),
            control1: point(mirroredX(0.271, side: side), 0.388, in: size),
            control2: point(mirroredX(0.253, side: side), 0.416, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.288, side: side), 0.616, in: size),
            control1: point(mirroredX(0.252, side: side), 0.520, in: size),
            control2: point(mirroredX(0.261, side: side), 0.585, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.347, side: side), 0.668, in: size),
            control1: point(mirroredX(0.307, side: side), 0.645, in: size),
            control2: point(mirroredX(0.326, side: side), 0.665, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.373, side: side), 0.575, in: size),
            control1: point(mirroredX(0.363, side: side), 0.649, in: size),
            control2: point(mirroredX(0.378, side: side), 0.615, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.359, side: side), 0.405, in: size),
            control1: point(mirroredX(0.367, side: side), 0.524, in: size),
            control2: point(mirroredX(0.367, side: side), 0.450, in: size)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.292, side: side), 0.356, in: size),
            control: point(mirroredX(0.328, side: side), 0.367, in: size)
        )
        path.closeSubpath()
        return path
    }

    private func vTaperPath(side: DiagramSide, size: CGSize) -> Path {
        var path: Path = Path()
        path.move(to: point(mirroredX(0.300, side: side), 0.690, in: size))
        path.addCurve(
            to: point(mirroredX(0.275, side: side), 0.776, in: size),
            control1: point(mirroredX(0.286, side: side), 0.718, in: size),
            control2: point(mirroredX(0.271, side: side), 0.748, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.341, side: side), 0.859, in: size),
            control1: point(mirroredX(0.281, side: side), 0.816, in: size),
            control2: point(mirroredX(0.306, side: side), 0.848, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.446, side: side), 0.834, in: size),
            control1: point(mirroredX(0.386, side: side), 0.870, in: size),
            control2: point(mirroredX(0.420, side: side), 0.860, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.378, side: side), 0.714, in: size),
            control1: point(mirroredX(0.425, side: side), 0.792, in: size),
            control2: point(mirroredX(0.401, side: side), 0.744, in: size)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.300, side: side), 0.690, in: size),
            control: point(mirroredX(0.340, side: side), 0.694, in: size)
        )
        path.closeSubpath()
        return path
    }

    private func deepCorePath(size: CGSize) -> Path {
        let rect: CGRect = normalizedRect(0.492, 0.435, 0.016, 0.390, in: size)
        return Path(roundedRect: rect, cornerRadius: size.width * 0.008)
    }

    private func muscleBlockPath(
        in rect: CGRect,
        side: DiagramSide,
        topInset: CGFloat,
        bottomInset: CGFloat,
        topCurveLift: CGFloat,
        bottomCurveDrop: CGFloat
    ) -> Path {
        let outerTopX: CGFloat = side == .left ? rect.minX + topInset : rect.minX
        let innerTopX: CGFloat = side == .left ? rect.maxX : rect.maxX - topInset
        let innerBottomX: CGFloat = side == .left ? rect.maxX - bottomInset : rect.maxX
        let outerBottomX: CGFloat = side == .left ? rect.minX : rect.minX + bottomInset
        let topY: CGFloat = rect.minY + rect.height * 0.08
        let bottomY: CGFloat = rect.maxY - rect.height * 0.05

        var path: Path = Path()
        path.move(to: CGPoint(x: outerTopX, y: topY))
        path.addQuadCurve(
            to: CGPoint(x: innerTopX, y: rect.minY + rect.height * 0.06),
            control: CGPoint(x: rect.midX, y: rect.minY - topCurveLift)
        )
        path.addCurve(
            to: CGPoint(x: innerBottomX, y: bottomY),
            control1: CGPoint(x: rect.maxX + rect.width * 0.018, y: rect.minY + rect.height * 0.34),
            control2: CGPoint(x: rect.maxX + rect.width * 0.012, y: rect.maxY - rect.height * 0.28)
        )
        path.addQuadCurve(
            to: CGPoint(x: outerBottomX, y: rect.maxY - rect.height * 0.02),
            control: CGPoint(x: rect.midX, y: rect.maxY + bottomCurveDrop)
        )
        path.addCurve(
            to: CGPoint(x: outerTopX, y: topY),
            control1: CGPoint(x: rect.minX - rect.width * 0.012, y: rect.maxY - rect.height * 0.28),
            control2: CGPoint(x: rect.minX - rect.width * 0.018, y: rect.minY + rect.height * 0.34)
        )
        path.closeSubpath()
        return path
    }

    private func normalizedRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, in size: CGSize) -> CGRect {
        CGRect(
            x: size.width * x,
            y: size.height * y,
            width: size.width * width,
            height: size.height * height
        )
    }

    private func mirroredX(_ x: CGFloat, side: DiagramSide) -> CGFloat {
        side == .left ? x : 1.0 - x
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * x, y: size.height * y)
    }

    private func zoneColor(for score: Int) -> Color {
        if score >= 85 { return Color(red: 0.20, green: 0.90, blue: 0.40) }
        if score >= 75 { return Color(red: 0.95, green: 0.80, blue: 0.10) }
        if score >= 65 { return Color(red: 1.00, green: 0.55, blue: 0.10) }
        return Color(red: 1.00, green: 0.22, blue: 0.20)
    }
}

private enum DiagramSide {
    case left
    case right
}
