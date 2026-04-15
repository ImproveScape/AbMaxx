import SwiftUI

struct AnatomyScoreOverlayView: View {
    let upperAbsScore: Int
    let lowerAbsScore: Int
    let obliquesScore: Int
    let vTaperScore: Int
    let deepCoreScore: Int

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            drawDiagram(context: &context, size: size)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .padding(20)
        .background(cardBackground)
        .clipShape(.rect(cornerRadius: 14))
        .accessibilityLabel("Anatomy score diagram")
    }

    private var cardBackground: Color {
        Color(.sRGB, red: 10.0 / 255.0, green: 10.0 / 255.0, blue: 10.0 / 255.0, opacity: 1.0)
    }

    private var neutralMuscleFill: Color {
        Color(.sRGB, red: 26.0 / 255.0, green: 26.0 / 255.0, blue: 26.0 / 255.0, opacity: 1.0)
    }

    private var outlineColor: Color {
        Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.9)
    }

    private func drawDiagram(context: inout GraphicsContext, size: CGSize) {
        let outlineStyle: StrokeStyle = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
        let chestLeft: Path = chestPath(side: .left, size: size)
        let chestRight: Path = chestPath(side: .right, size: size)
        let upperAbs: [Path] = upperAbsPaths(size: size)
        let lowerAbs: [Path] = lowerAbsPaths(size: size)
        let leftOblique: Path = obliquePath(side: .left, size: size)
        let rightOblique: Path = obliquePath(side: .right, size: size)
        let leftVTaper: Path = vTaperPath(side: .left, size: size)
        let rightVTaper: Path = vTaperPath(side: .right, size: size)
        let deepCore: Path = deepCorePath(size: size)
        let silhouette: Path = silhouettePath(size: size)
        let centerLine: Path = centerDividerPath(size: size)
        let rowLines: [Path] = abRowSeparatorPaths(size: size)

        context.fill(chestLeft, with: .color(neutralMuscleFill))
        context.fill(chestRight, with: .color(neutralMuscleFill))

        for path in upperAbs {
            context.fill(path, with: .color(zoneColor(for: upperAbsScore)))
        }

        for path in lowerAbs {
            context.fill(path, with: .color(zoneColor(for: lowerAbsScore)))
        }

        context.fill(leftOblique, with: .color(zoneColor(for: obliquesScore)))
        context.fill(rightOblique, with: .color(zoneColor(for: obliquesScore)))
        context.fill(leftVTaper, with: .color(zoneColor(for: vTaperScore)))
        context.fill(rightVTaper, with: .color(zoneColor(for: vTaperScore)))
        context.fill(deepCore, with: .color(zoneColor(for: deepCoreScore).opacity(0.5)))

        context.stroke(chestLeft, with: .color(outlineColor), style: outlineStyle)
        context.stroke(chestRight, with: .color(outlineColor), style: outlineStyle)

        for path in upperAbs {
            context.stroke(path, with: .color(outlineColor), style: outlineStyle)
        }

        for path in lowerAbs {
            context.stroke(path, with: .color(outlineColor), style: outlineStyle)
        }

        context.stroke(leftOblique, with: .color(outlineColor), style: outlineStyle)
        context.stroke(rightOblique, with: .color(outlineColor), style: outlineStyle)
        context.stroke(leftVTaper, with: .color(outlineColor), style: outlineStyle)
        context.stroke(rightVTaper, with: .color(outlineColor), style: outlineStyle)
        context.stroke(deepCore, with: .color(outlineColor), style: outlineStyle)

        for path in rowLines {
            context.stroke(path, with: .color(outlineColor), style: outlineStyle)
        }

        context.stroke(centerLine, with: .color(outlineColor), style: outlineStyle)
        context.stroke(silhouette, with: .color(outlineColor), style: outlineStyle)
    }

    private func chestPath(side: DiagramSide, size: CGSize) -> Path {
        var path: Path = Path()
        path.move(to: point(mirroredX(0.24, side: side), 0.16, in: size))
        path.addCurve(
            to: point(mirroredX(0.37, side: side), 0.12, in: size),
            control1: point(mirroredX(0.27, side: side), 0.11, in: size),
            control2: point(mirroredX(0.32, side: side), 0.10, in: size)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.48, side: side), 0.20, in: size),
            control: point(mirroredX(0.45, side: side), 0.11, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.45, side: side), 0.30, in: size),
            control1: point(mirroredX(0.50, side: side), 0.24, in: size),
            control2: point(mirroredX(0.48, side: side), 0.29, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.30, side: side), 0.27, in: size),
            control1: point(mirroredX(0.40, side: side), 0.31, in: size),
            control2: point(mirroredX(0.34, side: side), 0.30, in: size)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.24, side: side), 0.16, in: size),
            control: point(mirroredX(0.25, side: side), 0.23, in: size)
        )
        path.closeSubpath()
        return path
    }

    private func upperAbsPaths(size: CGSize) -> [Path] {
        [
            muscleBlockPath(
                in: normalizedRect(0.388, 0.245, 0.098, 0.094, in: size),
                side: .left,
                topInset: size.width * 0.014,
                bottomInset: size.width * 0.008
            ),
            muscleBlockPath(
                in: normalizedRect(0.514, 0.245, 0.098, 0.094, in: size),
                side: .right,
                topInset: size.width * 0.014,
                bottomInset: size.width * 0.008
            ),
            muscleBlockPath(
                in: normalizedRect(0.382, 0.352, 0.104, 0.098, in: size),
                side: .left,
                topInset: size.width * 0.012,
                bottomInset: size.width * 0.008
            ),
            muscleBlockPath(
                in: normalizedRect(0.514, 0.352, 0.104, 0.098, in: size),
                side: .right,
                topInset: size.width * 0.012,
                bottomInset: size.width * 0.008
            )
        ]
    }

    private func lowerAbsPaths(size: CGSize) -> [Path] {
        [
            muscleBlockPath(
                in: normalizedRect(0.376, 0.467, 0.110, 0.102, in: size),
                side: .left,
                topInset: size.width * 0.011,
                bottomInset: size.width * 0.012
            ),
            muscleBlockPath(
                in: normalizedRect(0.514, 0.467, 0.110, 0.102, in: size),
                side: .right,
                topInset: size.width * 0.011,
                bottomInset: size.width * 0.012
            ),
            muscleBlockPath(
                in: normalizedRect(0.389, 0.584, 0.091, 0.103, in: size),
                side: .left,
                topInset: size.width * 0.008,
                bottomInset: size.width * 0.020
            ),
            muscleBlockPath(
                in: normalizedRect(0.520, 0.584, 0.091, 0.103, in: size),
                side: .right,
                topInset: size.width * 0.008,
                bottomInset: size.width * 0.020
            )
        ]
    }

    private func obliquePath(side: DiagramSide, size: CGSize) -> Path {
        var path: Path = Path()
        path.move(to: point(mirroredX(0.33, side: side), 0.24, in: size))
        path.addCurve(
            to: point(mirroredX(0.27, side: side), 0.42, in: size),
            control1: point(mirroredX(0.30, side: side), 0.28, in: size),
            control2: point(mirroredX(0.25, side: side), 0.34, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.31, side: side), 0.72, in: size),
            control1: point(mirroredX(0.24, side: side), 0.54, in: size),
            control2: point(mirroredX(0.25, side: side), 0.67, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.40, side: side), 0.79, in: size),
            control1: point(mirroredX(0.34, side: side), 0.77, in: size),
            control2: point(mirroredX(0.37, side: side), 0.80, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.44, side: side), 0.67, in: size),
            control1: point(mirroredX(0.42, side: side), 0.76, in: size),
            control2: point(mirroredX(0.45, side: side), 0.72, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.41, side: side), 0.30, in: size),
            control1: point(mirroredX(0.41, side: side), 0.57, in: size),
            control2: point(mirroredX(0.38, side: side), 0.38, in: size)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.33, side: side), 0.24, in: size),
            control: point(mirroredX(0.38, side: side), 0.25, in: size)
        )
        path.closeSubpath()
        return path
    }

    private func vTaperPath(side: DiagramSide, size: CGSize) -> Path {
        var path: Path = Path()
        path.move(to: point(mirroredX(0.41, side: side), 0.70, in: size))
        path.addCurve(
            to: point(mirroredX(0.34, side: side), 0.83, in: size),
            control1: point(mirroredX(0.38, side: side), 0.74, in: size),
            control2: point(mirroredX(0.35, side: side), 0.79, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.46, side: side), 0.90, in: size),
            control1: point(mirroredX(0.36, side: side), 0.88, in: size),
            control2: point(mirroredX(0.41, side: side), 0.91, in: size)
        )
        path.addCurve(
            to: point(mirroredX(0.49, side: side), 0.74, in: size),
            control1: point(mirroredX(0.49, side: side), 0.87, in: size),
            control2: point(mirroredX(0.51, side: side), 0.79, in: size)
        )
        path.addQuadCurve(
            to: point(mirroredX(0.41, side: side), 0.70, in: size),
            control: point(mirroredX(0.46, side: side), 0.71, in: size)
        )
        path.closeSubpath()
        return path
    }

    private func deepCorePath(size: CGSize) -> Path {
        let rect: CGRect = normalizedRect(0.488, 0.238, 0.024, 0.456, in: size)
        return Path(roundedRect: rect, cornerRadius: size.width * 0.012)
    }

    private func silhouettePath(size: CGSize) -> Path {
        var path: Path = Path()
        path.move(to: point(0.45, 0.06, in: size))
        path.addQuadCurve(to: point(0.38, 0.07, in: size), control: point(0.41, 0.03, in: size))
        path.addCurve(
            to: point(0.20, 0.18, in: size),
            control1: point(0.31, 0.08, in: size),
            control2: point(0.24, 0.11, in: size)
        )
        path.addCurve(
            to: point(0.18, 0.34, in: size),
            control1: point(0.15, 0.22, in: size),
            control2: point(0.15, 0.28, in: size)
        )
        path.addCurve(
            to: point(0.23, 0.72, in: size),
            control1: point(0.18, 0.48, in: size),
            control2: point(0.16, 0.64, in: size)
        )
        path.addCurve(
            to: point(0.34, 0.88, in: size),
            control1: point(0.26, 0.79, in: size),
            control2: point(0.29, 0.85, in: size)
        )
        path.addQuadCurve(to: point(0.50, 0.95, in: size), control: point(0.41, 0.94, in: size))
        path.addQuadCurve(to: point(0.66, 0.88, in: size), control: point(0.59, 0.94, in: size))
        path.addCurve(
            to: point(0.77, 0.72, in: size),
            control1: point(0.71, 0.85, in: size),
            control2: point(0.74, 0.79, in: size)
        )
        path.addCurve(
            to: point(0.82, 0.34, in: size),
            control1: point(0.84, 0.64, in: size),
            control2: point(0.82, 0.48, in: size)
        )
        path.addCurve(
            to: point(0.80, 0.18, in: size),
            control1: point(0.85, 0.28, in: size),
            control2: point(0.85, 0.22, in: size)
        )
        path.addCurve(
            to: point(0.62, 0.07, in: size),
            control1: point(0.76, 0.11, in: size),
            control2: point(0.69, 0.08, in: size)
        )
        path.addQuadCurve(to: point(0.55, 0.06, in: size), control: point(0.59, 0.03, in: size))
        return path
    }

    private func centerDividerPath(size: CGSize) -> Path {
        var path: Path = Path()
        path.move(to: point(0.50, 0.238, in: size))
        path.addLine(to: point(0.50, 0.694, in: size))
        return path
    }

    private func abRowSeparatorPaths(size: CGSize) -> [Path] {
        [
            separatorLinePath(y: 0.347, size: size),
            separatorLinePath(y: 0.462, size: size),
            separatorLinePath(y: 0.578, size: size)
        ]
    }

    private func separatorLinePath(y: CGFloat, size: CGSize) -> Path {
        var path: Path = Path()
        path.move(to: point(0.39, y, in: size))
        path.addQuadCurve(to: point(0.61, y, in: size), control: point(0.50, y + 0.006, in: size))
        return path
    }

    private func muscleBlockPath(in rect: CGRect, side: DiagramSide, topInset: CGFloat, bottomInset: CGFloat) -> Path {
        let outerTopX: CGFloat = side == .left ? rect.minX + topInset : rect.minX
        let innerTopX: CGFloat = side == .left ? rect.maxX : rect.maxX - topInset
        let innerBottomX: CGFloat = side == .left ? rect.maxX - bottomInset : rect.maxX
        let outerBottomX: CGFloat = side == .left ? rect.minX : rect.minX + bottomInset
        let topY: CGFloat = rect.minY + rect.height * 0.06
        let bottomY: CGFloat = rect.maxY - rect.height * 0.04

        var path: Path = Path()
        path.move(to: CGPoint(x: outerTopX, y: topY))
        path.addQuadCurve(
            to: CGPoint(x: innerTopX, y: rect.minY + rect.height * 0.05),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: innerBottomX, y: bottomY),
            control1: CGPoint(x: rect.maxX + rect.width * 0.02, y: rect.minY + rect.height * 0.32),
            control2: CGPoint(x: rect.maxX + rect.width * 0.01, y: rect.maxY - rect.height * 0.28)
        )
        path.addQuadCurve(
            to: CGPoint(x: outerBottomX, y: rect.maxY - rect.height * 0.02),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.10)
        )
        path.addCurve(
            to: CGPoint(x: outerTopX, y: topY),
            control1: CGPoint(x: rect.minX - rect.width * 0.01, y: rect.maxY - rect.height * 0.28),
            control2: CGPoint(x: rect.minX - rect.width * 0.02, y: rect.minY + rect.height * 0.32)
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
