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
                GeometryReader { geometry in
                    bodyOutlineImage(in: geometry.size)
                }
                .allowsHitTesting(false)
            }
            .compositingGroup()
            .clipShape(.rect(cornerRadius: 14))
            .padding(8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Anatomy score diagram")
    }

    private var cardBackground: Color {
        Color(.sRGB, red: 10.0 / 255.0, green: 10.0 / 255.0, blue: 10.0 / 255.0, opacity: 1.0)
    }

    @ViewBuilder
    private func bodyOutlineImage(in size: CGSize) -> some View {
        let rect: CGRect = diagramRect(in: size)

        AsyncImage(url: bodyOutlineURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(1.0, contentMode: .fit)
                    .blendMode(.screen)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            case .empty:
                EmptyView()
            case .failure:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
    }

    private func drawZoneFills(context: inout GraphicsContext, size: CGSize) {
        let rect: CGRect = diagramRect(in: size)
        let upperAbs: [Path] = upperAbsPaths(in: rect)
        let lowerAbs: [Path] = lowerAbsPaths(in: rect)
        let leftOblique: Path = obliquePath(side: .left, in: rect)
        let rightOblique: Path = obliquePath(side: .right, in: rect)
        let leftVTaper: Path = vTaperPath(side: .left, in: rect)
        let rightVTaper: Path = vTaperPath(side: .right, in: rect)
        let deepCore: Path = deepCorePath(in: rect)

        var clippedContext: GraphicsContext = context
        clippedContext.clip(to: torsoClipPath(in: rect))

        for path in upperAbs {
            clippedContext.fill(path, with: .color(zoneColor(for: upperAbsScore).opacity(0.92)))
        }

        for path in lowerAbs {
            clippedContext.fill(path, with: .color(zoneColor(for: lowerAbsScore).opacity(0.92)))
        }

        clippedContext.fill(leftOblique, with: .color(zoneColor(for: obliquesScore).opacity(0.82)))
        clippedContext.fill(rightOblique, with: .color(zoneColor(for: obliquesScore).opacity(0.82)))
        clippedContext.fill(leftVTaper, with: .color(zoneColor(for: vTaperScore).opacity(0.80)))
        clippedContext.fill(rightVTaper, with: .color(zoneColor(for: vTaperScore).opacity(0.80)))
        clippedContext.fill(deepCore, with: .color(zoneColor(for: deepCoreScore).opacity(0.48)))
    }

    private func upperAbsPaths(in rect: CGRect) -> [Path] {
        [
            muscleBlockPath(
                in: normalizedRect(0.372, 0.442, 0.117, 0.079, in: rect),
                side: .left,
                topInset: rect.width * 0.004,
                bottomInset: rect.width * 0.005,
                topCurveLift: rect.width * 0.005,
                bottomCurveDrop: rect.width * 0.007
            ),
            muscleBlockPath(
                in: normalizedRect(0.511, 0.442, 0.117, 0.079, in: rect),
                side: .right,
                topInset: rect.width * 0.004,
                bottomInset: rect.width * 0.005,
                topCurveLift: rect.width * 0.005,
                bottomCurveDrop: rect.width * 0.007
            ),
            muscleBlockPath(
                in: normalizedRect(0.381, 0.533, 0.109, 0.083, in: rect),
                side: .left,
                topInset: rect.width * 0.004,
                bottomInset: rect.width * 0.005,
                topCurveLift: rect.width * 0.005,
                bottomCurveDrop: rect.width * 0.008
            ),
            muscleBlockPath(
                in: normalizedRect(0.510, 0.533, 0.109, 0.083, in: rect),
                side: .right,
                topInset: rect.width * 0.004,
                bottomInset: rect.width * 0.005,
                topCurveLift: rect.width * 0.005,
                bottomCurveDrop: rect.width * 0.008
            )
        ]
    }

    private func lowerAbsPaths(in rect: CGRect) -> [Path] {
        [
            muscleBlockPath(
                in: normalizedRect(0.388, 0.635, 0.101, 0.088, in: rect),
                side: .left,
                topInset: rect.width * 0.004,
                bottomInset: rect.width * 0.006,
                topCurveLift: rect.width * 0.005,
                bottomCurveDrop: rect.width * 0.009
            ),
            muscleBlockPath(
                in: normalizedRect(0.511, 0.635, 0.101, 0.088, in: rect),
                side: .right,
                topInset: rect.width * 0.004,
                bottomInset: rect.width * 0.006,
                topCurveLift: rect.width * 0.005,
                bottomCurveDrop: rect.width * 0.009
            ),
            muscleBlockPath(
                in: normalizedRect(0.394, 0.741, 0.094, 0.108, in: rect),
                side: .left,
                topInset: rect.width * 0.004,
                bottomInset: rect.width * 0.008,
                topCurveLift: rect.width * 0.005,
                bottomCurveDrop: rect.width * 0.012
            ),
            muscleBlockPath(
                in: normalizedRect(0.512, 0.741, 0.094, 0.108, in: rect),
                side: .right,
                topInset: rect.width * 0.004,
                bottomInset: rect.width * 0.008,
                topCurveLift: rect.width * 0.005,
                bottomCurveDrop: rect.width * 0.012
            )
        ]
    }

    private func obliquePath(side: DiagramSide, in rect: CGRect) -> Path {
        var path: Path = Path()
        path.move(to: point(mirroredX(0.311, side: side), 0.434, in: rect))
        path.addCurve(
            to: point(mirroredX(0.274, side: side), 0.531, in: rect),
            control1: point(mirroredX(0.289, side: side), 0.463, in: rect),
            control2: point(mirroredX(0.266, side: side), 0.492, in: rect)
        )
        path.addCurve(
            to: point(mirroredX(0.286, side: side), 0.694, in: rect),
            control1: point(mirroredX(0.266, side: side), 0.590, in: rect),
            control2: point(mirroredX(0.270, side: side), 0.646, in: rect)
        )
        path.addCurve(
            to: point(mirroredX(0.322, side: side), 0.786, in: rect),
            control1: point(mirroredX(0.294, side: side), 0.736, in: rect),
            control2: point(mirroredX(0.306, side: side), 0.771, in: rect)
        )
        path.addCurve(
            to: point(mirroredX(0.356, side: side), 0.774, in: rect),
            control1: point(mirroredX(0.334, side: side), 0.791, in: rect),
            control2: point(mirroredX(0.346, side: side), 0.787, in: rect)
        )
        path.addCurve(
            to: point(mirroredX(0.389, side: side), 0.683, in: rect),
            control1: point(mirroredX(0.373, side: side), 0.749, in: rect),
            control2: point(mirroredX(0.388, side: side), 0.719, in: rect)
        )
        path.addCurve(
            to: point(mirroredX(0.393, side: side), 0.540, in: rect),
            control1: point(mirroredX(0.391, side: side), 0.637, in: rect),
            control2: point(mirroredX(0.397, side: side), 0.587, in: rect)
        )
        path.addCurve(
            to: point(mirroredX(0.384, side: side), 0.450, in: rect),
            control1: point(mirroredX(0.390, side: side), 0.505, in: rect),
            control2: point(mirroredX(0.390, side: side), 0.473, in: rect)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.311, side: side), 0.434, in: rect),
            control: point(mirroredX(0.346, side: side), 0.435, in: rect)
        )
        path.closeSubpath()
        return path
    }

    private func vTaperPath(side: DiagramSide, in rect: CGRect) -> Path {
        var path: Path = Path()
        path.move(to: point(mirroredX(0.321, side: side), 0.696, in: rect))
        path.addQuadCurve(
            to: point(mirroredX(0.306, side: side), 0.761, in: rect),
            control: point(mirroredX(0.308, side: side), 0.728, in: rect)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.336, side: side), 0.858, in: rect),
            control: point(mirroredX(0.307, side: side), 0.822, in: rect)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.403, side: side), 0.841, in: rect),
            control: point(mirroredX(0.366, side: side), 0.866, in: rect)
        )
        path.addCurve(
            to: point(mirroredX(0.361, side: side), 0.709, in: rect),
            control1: point(mirroredX(0.397, side: side), 0.806, in: rect),
            control2: point(mirroredX(0.381, side: side), 0.759, in: rect)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.321, side: side), 0.696, in: rect),
            control: point(mirroredX(0.340, side: side), 0.694, in: rect)
        )
        path.closeSubpath()
        return path
    }

    private func deepCorePath(in rect: CGRect) -> Path {
        let pathRect: CGRect = normalizedRect(0.494, 0.438, 0.012, 0.399, in: rect)
        return Path(roundedRect: pathRect, cornerRadius: rect.width * 0.006)
    }

    private func torsoClipPath(in rect: CGRect) -> Path {
        var path: Path = Path()
        path.move(to: point(0.334, 0.356, in: rect))
        path.addCurve(
            to: point(0.500, 0.394, in: rect),
            control1: point(0.385, 0.343, in: rect),
            control2: point(0.452, 0.382, in: rect)
        )
        path.addCurve(
            to: point(0.666, 0.356, in: rect),
            control1: point(0.548, 0.382, in: rect),
            control2: point(0.615, 0.343, in: rect)
        )
        path.addCurve(
            to: point(0.690, 0.470, in: rect),
            control1: point(0.686, 0.393, in: rect),
            control2: point(0.698, 0.430, in: rect)
        )
        path.addCurve(
            to: point(0.684, 0.650, in: rect),
            control1: point(0.682, 0.530, in: rect),
            control2: point(0.691, 0.594, in: rect)
        )
        path.addCurve(
            to: point(0.659, 0.874, in: rect),
            control1: point(0.678, 0.724, in: rect),
            control2: point(0.680, 0.820, in: rect)
        )
        path.addCurve(
            to: point(0.500, 0.896, in: rect),
            control1: point(0.614, 0.892, in: rect),
            control2: point(0.554, 0.903, in: rect)
        )
        path.addCurve(
            to: point(0.341, 0.874, in: rect),
            control1: point(0.446, 0.903, in: rect),
            control2: point(0.386, 0.892, in: rect)
        )
        path.addCurve(
            to: point(0.316, 0.650, in: rect),
            control1: point(0.320, 0.820, in: rect),
            control2: point(0.298, 0.724, in: rect)
        )
        path.addCurve(
            to: point(0.310, 0.470, in: rect),
            control1: point(0.309, 0.594, in: rect),
            control2: point(0.302, 0.530, in: rect)
        )
        path.addCurve(
            to: point(0.334, 0.356, in: rect),
            control1: point(0.302, 0.430, in: rect),
            control2: point(0.314, 0.393, in: rect)
        )
        path.closeSubpath()
        return path
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
        let bottomY: CGFloat = rect.maxY - rect.height * 0.04

        var path: Path = Path()
        path.move(to: CGPoint(x: outerTopX, y: topY))
        path.addQuadCurve(
            to: CGPoint(x: innerTopX, y: rect.minY + rect.height * 0.05),
            control: CGPoint(x: rect.midX, y: rect.minY - topCurveLift)
        )
        path.addCurve(
            to: CGPoint(x: innerBottomX, y: bottomY),
            control1: CGPoint(x: rect.maxX + rect.width * 0.014, y: rect.minY + rect.height * 0.32),
            control2: CGPoint(x: rect.maxX + rect.width * 0.010, y: rect.maxY - rect.height * 0.26)
        )
        path.addQuadCurve(
            to: CGPoint(x: outerBottomX, y: rect.maxY - rect.height * 0.01),
            control: CGPoint(x: rect.midX, y: rect.maxY + bottomCurveDrop)
        )
        path.addCurve(
            to: CGPoint(x: outerTopX, y: topY),
            control1: CGPoint(x: rect.minX - rect.width * 0.010, y: rect.maxY - rect.height * 0.26),
            control2: CGPoint(x: rect.minX - rect.width * 0.014, y: rect.minY + rect.height * 0.32)
        )
        path.closeSubpath()
        return path
    }

    private func diagramRect(in size: CGSize) -> CGRect {
        let side: CGFloat = min(size.width, size.height) * 1.08
        return CGRect(
            x: (size.width - side) / 2.0,
            y: ((size.height - side) / 2.0) - (size.height * 0.012),
            width: side,
            height: side
        )
    }

    private func normalizedRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, in rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX + (rect.width * x),
            y: rect.minY + (rect.height * y),
            width: rect.width * width,
            height: rect.height * height
        )
    }

    private func mirroredX(_ x: CGFloat, side: DiagramSide) -> CGFloat {
        side == .left ? x : 1.0 - x
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + (rect.width * x), y: rect.minY + (rect.height * y))
    }

    private func zoneColor(for score: Int) -> Color {
        if score >= 85 { return Color(red: 0.20, green: 0.90, blue: 0.40) }
        if score >= 75 { return Color(red: 0.95, green: 0.80, blue: 0.10) }
        if score >= 65 { return Color(red: 1.00, green: 0.55, blue: 0.10) }
        return Color(red: 1.00, green: 0.22, blue: 0.20)
    }
}

nonisolated private enum DiagramSide {
    case left
    case right
}
