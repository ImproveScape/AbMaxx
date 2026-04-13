import SwiftUI

struct HeatMapOverlayView: View {
    let zones: [HeatMapZone]
    let imageSize: CGSize
    @State private var appeared: Bool = false

    var body: some View {
        Canvas { context, size in
            for zone in zones {
                let color = heatColor(for: zone.definitionScore)
                let opacity = appeared ? 0.7 : 0.0

                let path = musclePath(for: zone, in: size)

                var innerContext = context
                innerContext.fill(path, with: .color(color.opacity(opacity)))

                let borderPath = path
                innerContext.stroke(borderPath, with: .color(color.opacity(opacity * 0.4)), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                appeared = true
            }
        }
    }

    private func musclePath(for zone: HeatMapZone, in size: CGSize) -> Path {
        let cx = zone.centerX * size.width
        let cy = zone.centerY * size.height
        let w = zone.width * size.width
        let h = zone.height * size.height

        let name = zone.name.lowercased()

        if name.contains("oblique") {
            return obliquePath(cx: cx, cy: cy, w: w, h: h, isLeft: name.contains("left"))
        } else if name.contains("v-line") || name.contains("v_taper") || name.contains("taper") {
            return vTaperPath(cx: cx, cy: cy, w: w, h: h, isLeft: name.contains("l"))
        } else if name.contains("upper") {
            return upperAbPath(cx: cx, cy: cy, w: w, h: h, isLeft: name.contains("l"))
        } else if name.contains("mid") {
            return midAbPath(cx: cx, cy: cy, w: w, h: h, isLeft: name.contains("l"))
        } else if name.contains("lower") {
            return lowerAbPath(cx: cx, cy: cy, w: w, h: h, isLeft: name.contains("l"))
        } else {
            return genericAbPath(cx: cx, cy: cy, w: w, h: h)
        }
    }

    private func upperAbPath(cx: Double, cy: Double, w: Double, h: Double, isLeft: Bool) -> Path {
        let inset: Double = 2.0
        let hw = (w * 0.46) - inset
        let hh = (h * 0.46) - inset
        let r = min(hw, hh) * 0.2

        var path = Path()
        let topNarrow: Double = 0.92
        let outerBulge: Double = 1.06

        path.move(to: CGPoint(x: cx - hw * topNarrow + r, y: cy - hh))
        path.addLine(to: CGPoint(x: cx + hw * topNarrow - r, y: cy - hh))
        path.addQuadCurve(
            to: CGPoint(x: cx + hw * topNarrow, y: cy - hh + r),
            control: CGPoint(x: cx + hw * topNarrow, y: cy - hh)
        )
        path.addCurve(
            to: CGPoint(x: cx + hw * outerBulge, y: cy + hh * 0.3),
            control1: CGPoint(x: cx + hw * topNarrow, y: cy - hh * 0.4),
            control2: CGPoint(x: cx + hw * outerBulge, y: cy - hh * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: cx + hw * 0.95, y: cy + hh),
            control1: CGPoint(x: cx + hw * outerBulge, y: cy + hh * 0.6),
            control2: CGPoint(x: cx + hw, y: cy + hh * 0.85)
        )
        path.addLine(to: CGPoint(x: cx - hw * 0.95 + r, y: cy + hh))
        path.addQuadCurve(
            to: CGPoint(x: cx - hw * 0.95, y: cy + hh - r),
            control: CGPoint(x: cx - hw * 0.95, y: cy + hh)
        )
        path.addCurve(
            to: CGPoint(x: cx - hw * topNarrow, y: cy - hh + r),
            control1: CGPoint(x: cx - hw * 0.98, y: cy + hh * 0.3),
            control2: CGPoint(x: cx - hw * topNarrow, y: cy - hh * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx - hw * topNarrow + r, y: cy - hh),
            control: CGPoint(x: cx - hw * topNarrow, y: cy - hh)
        )
        path.closeSubpath()
        return path
    }

    private func midAbPath(cx: Double, cy: Double, w: Double, h: Double, isLeft: Bool) -> Path {
        let inset: Double = 2.0
        let hw = (w * 0.46) - inset
        let hh = (h * 0.46) - inset
        let r = min(hw, hh) * 0.18

        var path = Path()
        let bulge: Double = 1.04

        path.move(to: CGPoint(x: cx - hw + r, y: cy - hh))
        path.addLine(to: CGPoint(x: cx + hw - r, y: cy - hh))
        path.addQuadCurve(
            to: CGPoint(x: cx + hw, y: cy - hh + r),
            control: CGPoint(x: cx + hw, y: cy - hh)
        )
        path.addCurve(
            to: CGPoint(x: cx + hw * bulge, y: cy),
            control1: CGPoint(x: cx + hw * 1.01, y: cy - hh * 0.5),
            control2: CGPoint(x: cx + hw * bulge, y: cy - hh * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: cx + hw, y: cy + hh - r),
            control1: CGPoint(x: cx + hw * bulge, y: cy + hh * 0.2),
            control2: CGPoint(x: cx + hw * 1.01, y: cy + hh * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx + hw - r, y: cy + hh),
            control: CGPoint(x: cx + hw, y: cy + hh)
        )
        path.addLine(to: CGPoint(x: cx - hw + r, y: cy + hh))
        path.addQuadCurve(
            to: CGPoint(x: cx - hw, y: cy + hh - r),
            control: CGPoint(x: cx - hw, y: cy + hh)
        )
        path.addCurve(
            to: CGPoint(x: cx - hw, y: cy - hh + r),
            control1: CGPoint(x: cx - hw * 1.01, y: cy + hh * 0.3),
            control2: CGPoint(x: cx - hw * 1.01, y: cy - hh * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx - hw + r, y: cy - hh),
            control: CGPoint(x: cx - hw, y: cy - hh)
        )
        path.closeSubpath()
        return path
    }

    private func lowerAbPath(cx: Double, cy: Double, w: Double, h: Double, isLeft: Bool) -> Path {
        let inset: Double = 2.0
        let hw = (w * 0.46) - inset
        let hh = (h * 0.46) - inset
        let r = min(hw, hh) * 0.2

        var path = Path()
        let bottomNarrow: Double = 0.88

        path.move(to: CGPoint(x: cx - hw + r, y: cy - hh))
        path.addLine(to: CGPoint(x: cx + hw - r, y: cy - hh))
        path.addQuadCurve(
            to: CGPoint(x: cx + hw, y: cy - hh + r),
            control: CGPoint(x: cx + hw, y: cy - hh)
        )
        path.addCurve(
            to: CGPoint(x: cx + hw * bottomNarrow, y: cy + hh),
            control1: CGPoint(x: cx + hw * 1.02, y: cy),
            control2: CGPoint(x: cx + hw * 0.98, y: cy + hh * 0.7)
        )
        path.addLine(to: CGPoint(x: cx - hw * bottomNarrow + r, y: cy + hh))
        path.addQuadCurve(
            to: CGPoint(x: cx - hw * bottomNarrow, y: cy + hh - r),
            control: CGPoint(x: cx - hw * bottomNarrow, y: cy + hh)
        )
        path.addCurve(
            to: CGPoint(x: cx - hw, y: cy - hh + r),
            control1: CGPoint(x: cx - hw * 0.95, y: cy + hh * 0.4),
            control2: CGPoint(x: cx - hw * 1.01, y: cy)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx - hw + r, y: cy - hh),
            control: CGPoint(x: cx - hw, y: cy - hh)
        )
        path.closeSubpath()
        return path
    }

    private func genericAbPath(cx: Double, cy: Double, w: Double, h: Double) -> Path {
        let inset: Double = 2.0
        let hw = (w * 0.46) - inset
        let hh = (h * 0.46) - inset
        let r = min(hw, hh) * 0.18

        return Path(roundedRect: CGRect(
            x: cx - hw, y: cy - hh,
            width: hw * 2, height: hh * 2
        ), cornerRadius: r)
    }

    private func obliquePath(cx: Double, cy: Double, w: Double, h: Double, isLeft: Bool) -> Path {
        let inset: Double = 2.5
        let hw = (w * 0.48) - inset
        let hh = (h * 0.48) - inset
        let dir: Double = isLeft ? -1 : 1

        var path = Path()

        let innerEdge = cx - hw * 0.1 * dir
        let outerTop = cx + hw * 0.95 * dir
        let outerMid = cx + hw * 1.0 * dir
        let outerBot = cx + hw * 0.7 * dir

        path.move(to: CGPoint(x: innerEdge, y: cy - hh * 0.9))

        path.addCurve(
            to: CGPoint(x: outerTop, y: cy - hh * 0.6),
            control1: CGPoint(x: innerEdge + hw * 0.3 * dir, y: cy - hh * 0.92),
            control2: CGPoint(x: outerTop - hw * 0.15 * dir, y: cy - hh * 0.78)
        )

        path.addCurve(
            to: CGPoint(x: outerMid, y: cy + hh * 0.1),
            control1: CGPoint(x: outerTop + hw * 0.08 * dir, y: cy - hh * 0.35),
            control2: CGPoint(x: outerMid + hw * 0.05 * dir, y: cy - hh * 0.1)
        )

        path.addCurve(
            to: CGPoint(x: outerBot, y: cy + hh * 0.85),
            control1: CGPoint(x: outerMid, y: cy + hh * 0.35),
            control2: CGPoint(x: outerBot + hw * 0.15 * dir, y: cy + hh * 0.65)
        )

        path.addCurve(
            to: CGPoint(x: innerEdge + hw * 0.05 * dir, y: cy + hh * 0.7),
            control1: CGPoint(x: outerBot - hw * 0.1 * dir, y: cy + hh * 0.92),
            control2: CGPoint(x: innerEdge + hw * 0.2 * dir, y: cy + hh * 0.85)
        )

        path.addCurve(
            to: CGPoint(x: innerEdge, y: cy - hh * 0.9),
            control1: CGPoint(x: innerEdge - hw * 0.05 * dir, y: cy + hh * 0.3),
            control2: CGPoint(x: innerEdge - hw * 0.08 * dir, y: cy - hh * 0.4)
        )

        path.closeSubpath()
        return path
    }

    private func vTaperPath(cx: Double, cy: Double, w: Double, h: Double, isLeft: Bool) -> Path {
        let inset: Double = 2.5
        let hw = (w * 0.46) - inset
        let hh = (h * 0.48) - inset
        let dir: Double = isLeft ? -1 : 1

        var path = Path()

        path.move(to: CGPoint(x: cx - hw * 0.3, y: cy - hh * 0.8))

        path.addCurve(
            to: CGPoint(x: cx + hw * 0.6 * dir, y: cy - hh * 0.3),
            control1: CGPoint(x: cx + hw * 0.05 * dir, y: cy - hh * 0.82),
            control2: CGPoint(x: cx + hw * 0.4 * dir, y: cy - hh * 0.6)
        )

        path.addCurve(
            to: CGPoint(x: cx + hw * 0.5 * dir, y: cy + hh * 0.7),
            control1: CGPoint(x: cx + hw * 0.7 * dir, y: cy + hh * 0.0),
            control2: CGPoint(x: cx + hw * 0.65 * dir, y: cy + hh * 0.4)
        )

        path.addCurve(
            to: CGPoint(x: cx - hw * 0.15, y: cy + hh * 0.85),
            control1: CGPoint(x: cx + hw * 0.3 * dir, y: cy + hh * 0.82),
            control2: CGPoint(x: cx + hw * 0.05 * dir, y: cy + hh * 0.88)
        )

        path.addCurve(
            to: CGPoint(x: cx - hw * 0.3, y: cy - hh * 0.8),
            control1: CGPoint(x: cx - hw * 0.25, y: cy + hh * 0.4),
            control2: CGPoint(x: cx - hw * 0.32, y: cy - hh * 0.2)
        )

        path.closeSubpath()
        return path
    }

    private func heatColor(for score: Int) -> Color {
        if score >= 80 {
            return Color(red: 0.0, green: 0.95, blue: 0.35)
        } else if score >= 65 {
            return Color(red: 0.15, green: 0.85, blue: 0.2)
        } else if score >= 50 {
            return Color(red: 1.0, green: 0.82, blue: 0.0)
        } else if score >= 35 {
            return Color(red: 1.0, green: 0.45, blue: 0.0)
        } else {
            return Color(red: 1.0, green: 0.12, blue: 0.12)
        }
    }
}
