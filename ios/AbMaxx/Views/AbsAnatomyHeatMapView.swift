import SwiftUI

struct AbsAnatomyHeatMapView: View {
    let upperAbs: Int
    let lowerAbs: Int
    let obliquesScore: Int
    let deepCore: Int
    let vTaper: Int
    let symmetryScore: Int

    @State private var appeared: Bool = false

    private let vbW: CGFloat = 200
    private let vbH: CGFloat = 360

    init(scan: ScanResult) {
        self.upperAbs = scan.definition
        self.lowerAbs = scan.thickness
        self.obliquesScore = scan.obliques
        self.deepCore = scan.aesthetic
        self.vTaper = scan.frame
        self.symmetryScore = scan.symmetry
    }

    private struct MuscleZone {
        let label: String
        let score: Int
        let path: Path
        let showLabel: Bool
    }

    var body: some View {
        Canvas { context, size in
            let s = min(size.width / vbW, size.height / vbH)
            let ox = (size.width - vbW * s) / 2
            let oy = (size.height - vbH * s) / 2

            drawOutline(ctx: &context, s: s, ox: ox, oy: oy)

            let zones = buildZones(s: s, ox: ox, oy: oy)

            for zone in zones {
                let color = AppTheme.subscoreColor(for: zone.score)
                let opacity = appeared ? 0.82 : 0.0

                context.drawLayer { lc in
                    lc.addFilter(.blur(radius: 8 * s))
                    lc.fill(zone.path, with: .color(color.opacity(opacity * 0.2)))
                }

                context.fill(zone.path, with: .color(color.opacity(opacity)))

                context.stroke(zone.path, with: .color(color.opacity(opacity * 0.35)), lineWidth: 1.2 * s)
                context.stroke(zone.path, with: .color(Color.white.opacity(0.08)), lineWidth: 0.5 * s)
            }

            if appeared {
                for zone in zones where zone.showLabel {
                    let b = zone.path.boundingRect
                    guard b.width > 14 * s, b.height > 14 * s else { continue }
                    let c = CGPoint(x: b.midX, y: b.midY)
                    let color = AppTheme.subscoreColor(for: zone.score)

                    let pw: CGFloat = 30 * s
                    let ph: CGFloat = 18 * s
                    let pr = CGRect(x: c.x - pw / 2, y: c.y - ph / 2, width: pw, height: ph)
                    let pill = Path(roundedRect: pr, cornerRadius: 5 * s)
                    context.fill(pill, with: .color(Color.black.opacity(0.72)))
                    context.stroke(pill, with: .color(color.opacity(0.4)), lineWidth: 0.5 * s)

                    var a = AttributeContainer()
                    a.font = .system(size: max(9, 11 * s), weight: .heavy)
                    a.foregroundColor = UIColor.white
                    context.draw(context.resolve(Text(AttributedString("\(zone.score)", attributes: a))), at: c)
                }
            }
        }
        .aspectRatio(vbW / vbH, contentMode: .fit)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
    }

    private func pt(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ox: CGFloat, _ oy: CGFloat) -> CGPoint {
        CGPoint(x: x * s + ox, y: y * s + oy)
    }

    private func drawOutline(ctx: inout GraphicsContext, s: CGFloat, ox: CGFloat, oy: CGFloat) {
        var path = Path()
        path.move(to: pt(42, 0, s, ox, oy))
        path.addCurve(to: pt(18, 70, s, ox, oy), control1: pt(30, 8, s, ox, oy), control2: pt(18, 35, s, ox, oy))
        path.addCurve(to: pt(12, 180, s, ox, oy), control1: pt(18, 105, s, ox, oy), control2: pt(10, 140, s, ox, oy))
        path.addCurve(to: pt(22, 275, s, ox, oy), control1: pt(14, 215, s, ox, oy), control2: pt(16, 250, s, ox, oy))
        path.addCurve(to: pt(38, 320, s, ox, oy), control1: pt(26, 290, s, ox, oy), control2: pt(32, 308, s, ox, oy))
        path.addCurve(to: pt(65, 355, s, ox, oy), control1: pt(44, 332, s, ox, oy), control2: pt(54, 348, s, ox, oy))
        path.addLine(to: pt(100, 360, s, ox, oy))
        path.addLine(to: pt(135, 355, s, ox, oy))
        path.addCurve(to: pt(162, 320, s, ox, oy), control1: pt(146, 348, s, ox, oy), control2: pt(156, 332, s, ox, oy))
        path.addCurve(to: pt(178, 275, s, ox, oy), control1: pt(168, 308, s, ox, oy), control2: pt(174, 290, s, ox, oy))
        path.addCurve(to: pt(188, 180, s, ox, oy), control1: pt(184, 250, s, ox, oy), control2: pt(186, 215, s, ox, oy))
        path.addCurve(to: pt(182, 70, s, ox, oy), control1: pt(190, 140, s, ox, oy), control2: pt(182, 105, s, ox, oy))
        path.addCurve(to: pt(158, 0, s, ox, oy), control1: pt(182, 35, s, ox, oy), control2: pt(170, 8, s, ox, oy))

        ctx.stroke(path, with: .color(Color.white.opacity(0.06)), lineWidth: 1.5 * s)
    }

    private func buildZones(s: CGFloat, ox: CGFloat, oy: CGFloat) -> [MuscleZone] {
        let midScore = (upperAbs + lowerAbs) / 2

        var zones: [MuscleZone] = []

        zones.append(MuscleZone(label: "Deep Core", score: deepCore, path: deepCorePath(s: s, ox: ox, oy: oy), showLabel: false))

        zones.append(MuscleZone(label: "L Oblique", score: obliquesScore, path: leftObliquePath(s: s, ox: ox, oy: oy), showLabel: true))
        zones.append(MuscleZone(label: "R Oblique", score: obliquesScore, path: rightObliquePath(s: s, ox: ox, oy: oy), showLabel: true))

        zones.append(MuscleZone(label: "Upper L", score: upperAbs, path: upperAbLeftPath(s: s, ox: ox, oy: oy), showLabel: true))
        zones.append(MuscleZone(label: "Upper R", score: upperAbs, path: upperAbRightPath(s: s, ox: ox, oy: oy), showLabel: true))

        zones.append(MuscleZone(label: "Mid L", score: midScore, path: midAbLeftPath(s: s, ox: ox, oy: oy), showLabel: true))
        zones.append(MuscleZone(label: "Mid R", score: midScore, path: midAbRightPath(s: s, ox: ox, oy: oy), showLabel: true))

        zones.append(MuscleZone(label: "Lower L", score: lowerAbs, path: lowerAbLeftPath(s: s, ox: ox, oy: oy), showLabel: true))
        zones.append(MuscleZone(label: "Lower R", score: lowerAbs, path: lowerAbRightPath(s: s, ox: ox, oy: oy), showLabel: true))

        zones.append(MuscleZone(label: "V-Taper L", score: vTaper, path: vTaperLeftPath(s: s, ox: ox, oy: oy), showLabel: true))
        zones.append(MuscleZone(label: "V-Taper R", score: vTaper, path: vTaperRightPath(s: s, ox: ox, oy: oy), showLabel: true))

        return zones
    }

    private func upperAbLeftPath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(60, 28, s, ox, oy))
        p.addQuadCurve(to: pt(96, 28, s, ox, oy), control: pt(78, 22, s, ox, oy))
        p.addLine(to: pt(96, 102, s, ox, oy))
        p.addQuadCurve(to: pt(58, 102, s, ox, oy), control: pt(78, 108, s, ox, oy))
        p.addCurve(to: pt(60, 28, s, ox, oy),
                   control1: pt(50, 82, s, ox, oy),
                   control2: pt(50, 48, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func upperAbRightPath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(104, 28, s, ox, oy))
        p.addQuadCurve(to: pt(140, 28, s, ox, oy), control: pt(122, 22, s, ox, oy))
        p.addCurve(to: pt(142, 102, s, ox, oy),
                   control1: pt(150, 48, s, ox, oy),
                   control2: pt(150, 82, s, ox, oy))
        p.addQuadCurve(to: pt(104, 102, s, ox, oy), control: pt(122, 108, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func midAbLeftPath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(56, 112, s, ox, oy))
        p.addQuadCurve(to: pt(96, 112, s, ox, oy), control: pt(76, 106, s, ox, oy))
        p.addLine(to: pt(96, 192, s, ox, oy))
        p.addQuadCurve(to: pt(54, 192, s, ox, oy), control: pt(76, 198, s, ox, oy))
        p.addCurve(to: pt(56, 112, s, ox, oy),
                   control1: pt(46, 170, s, ox, oy),
                   control2: pt(46, 134, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func midAbRightPath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(104, 112, s, ox, oy))
        p.addQuadCurve(to: pt(144, 112, s, ox, oy), control: pt(124, 106, s, ox, oy))
        p.addCurve(to: pt(146, 192, s, ox, oy),
                   control1: pt(154, 134, s, ox, oy),
                   control2: pt(154, 170, s, ox, oy))
        p.addQuadCurve(to: pt(104, 192, s, ox, oy), control: pt(124, 198, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func lowerAbLeftPath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(58, 202, s, ox, oy))
        p.addQuadCurve(to: pt(96, 202, s, ox, oy), control: pt(78, 196, s, ox, oy))
        p.addLine(to: pt(96, 274, s, ox, oy))
        p.addQuadCurve(to: pt(66, 274, s, ox, oy), control: pt(82, 280, s, ox, oy))
        p.addCurve(to: pt(58, 202, s, ox, oy),
                   control1: pt(52, 256, s, ox, oy),
                   control2: pt(48, 226, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func lowerAbRightPath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(104, 202, s, ox, oy))
        p.addQuadCurve(to: pt(142, 202, s, ox, oy), control: pt(122, 196, s, ox, oy))
        p.addCurve(to: pt(134, 274, s, ox, oy),
                   control1: pt(152, 226, s, ox, oy),
                   control2: pt(148, 256, s, ox, oy))
        p.addQuadCurve(to: pt(104, 274, s, ox, oy), control: pt(118, 280, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func leftObliquePath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(48, 34, s, ox, oy))
        p.addCurve(to: pt(50, 152, s, ox, oy),
                   control1: pt(44, 60, s, ox, oy),
                   control2: pt(42, 110, s, ox, oy))
        p.addCurve(to: pt(52, 262, s, ox, oy),
                   control1: pt(42, 195, s, ox, oy),
                   control2: pt(44, 240, s, ox, oy))
        p.addCurve(to: pt(28, 270, s, ox, oy),
                   control1: pt(44, 265, s, ox, oy),
                   control2: pt(36, 268, s, ox, oy))
        p.addCurve(to: pt(18, 180, s, ox, oy),
                   control1: pt(18, 248, s, ox, oy),
                   control2: pt(14, 216, s, ox, oy))
        p.addCurve(to: pt(22, 70, s, ox, oy),
                   control1: pt(14, 142, s, ox, oy),
                   control2: pt(18, 105, s, ox, oy))
        p.addCurve(to: pt(48, 34, s, ox, oy),
                   control1: pt(24, 52, s, ox, oy),
                   control2: pt(34, 38, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func rightObliquePath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(152, 34, s, ox, oy))
        p.addCurve(to: pt(178, 70, s, ox, oy),
                   control1: pt(166, 38, s, ox, oy),
                   control2: pt(176, 52, s, ox, oy))
        p.addCurve(to: pt(182, 180, s, ox, oy),
                   control1: pt(182, 105, s, ox, oy),
                   control2: pt(186, 142, s, ox, oy))
        p.addCurve(to: pt(172, 270, s, ox, oy),
                   control1: pt(186, 216, s, ox, oy),
                   control2: pt(182, 248, s, ox, oy))
        p.addCurve(to: pt(148, 262, s, ox, oy),
                   control1: pt(164, 268, s, ox, oy),
                   control2: pt(156, 265, s, ox, oy))
        p.addCurve(to: pt(150, 152, s, ox, oy),
                   control1: pt(156, 240, s, ox, oy),
                   control2: pt(158, 195, s, ox, oy))
        p.addCurve(to: pt(152, 34, s, ox, oy),
                   control1: pt(158, 110, s, ox, oy),
                   control2: pt(156, 60, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func deepCorePath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(96, 26, s, ox, oy))
        p.addLine(to: pt(104, 26, s, ox, oy))
        p.addLine(to: pt(104, 276, s, ox, oy))
        p.addQuadCurve(to: pt(96, 276, s, ox, oy), control: pt(100, 280, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func vTaperLeftPath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(62, 278, s, ox, oy))
        p.addLine(to: pt(96, 278, s, ox, oy))
        p.addCurve(to: pt(88, 332, s, ox, oy),
                   control1: pt(96, 298, s, ox, oy),
                   control2: pt(94, 320, s, ox, oy))
        p.addCurve(to: pt(36, 312, s, ox, oy),
                   control1: pt(72, 338, s, ox, oy),
                   control2: pt(50, 328, s, ox, oy))
        p.addCurve(to: pt(62, 278, s, ox, oy),
                   control1: pt(40, 298, s, ox, oy),
                   control2: pt(48, 284, s, ox, oy))
        p.closeSubpath()
        return p
    }

    private func vTaperRightPath(s: CGFloat, ox: CGFloat, oy: CGFloat) -> Path {
        var p = Path()
        p.move(to: pt(104, 278, s, ox, oy))
        p.addLine(to: pt(138, 278, s, ox, oy))
        p.addCurve(to: pt(164, 312, s, ox, oy),
                   control1: pt(152, 284, s, ox, oy),
                   control2: pt(160, 298, s, ox, oy))
        p.addCurve(to: pt(112, 332, s, ox, oy),
                   control1: pt(150, 328, s, ox, oy),
                   control2: pt(128, 338, s, ox, oy))
        p.addCurve(to: pt(104, 278, s, ox, oy),
                   control1: pt(106, 320, s, ox, oy),
                   control2: pt(104, 298, s, ox, oy))
        p.closeSubpath()
        return p
    }
}
