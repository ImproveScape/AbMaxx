import SwiftUI

struct AbsRadarChartView: View {
    let scores: [Int]
    var colors: [Color] = []

    private func colorFor(_ index: Int, score: Int) -> Color {
        if index < colors.count { return colors[index] }
        return Self.scoreColor(score)
    }

    static func scoreColor(_ score: Int) -> Color {
        if score >= 85 { return AppTheme.success }
        if score >= 75 { return AppTheme.yellow }
        if score >= 65 { return AppTheme.caution }
        return AppTheme.destructive
    }

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let maxR = min(size.width, size.height) * 0.35
            let count = scores.count

            func pt(_ i: Int, _ r: CGFloat) -> CGPoint {
                let a = CGFloat(i) * .pi * 2 / CGFloat(count) - .pi / 2
                return CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r)
            }

            for pct in [0.25, 0.5, 0.75, 1.0] as [CGFloat] {
                var p = Path()
                for i in 0..<count {
                    let pt2 = pt(i, maxR * pct)
                    i == 0 ? p.move(to: pt2) : p.addLine(to: pt2)
                }
                p.closeSubpath()
                context.stroke(p, with: .color(.white.opacity(0.05)), lineWidth: 1)
            }

            var target = Path()
            for i in 0..<count {
                let pt2 = pt(i, maxR * 0.8)
                i == 0 ? target.move(to: pt2) : target.addLine(to: pt2)
            }
            target.closeSubpath()
            context.stroke(target, with: .color(.white.opacity(0.2)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))

            for i in 0..<count {
                var axis = Path()
                axis.move(to: CGPoint(x: cx, y: cy))
                axis.addLine(to: pt(i, maxR))
                context.stroke(axis, with: .color(.white.opacity(0.05)), lineWidth: 1)
            }

            let center = CGPoint(x: cx, y: cy)
            for i in 0..<count {
                let next = (i + 1) % count
                let r1 = maxR * CGFloat(scores[i]) / 100
                let r2 = maxR * CGFloat(scores[next]) / 100
                let p1 = pt(i, r1)
                let p2 = pt(next, r2)
                let c1 = colorFor(i, score: scores[i])
                let c2 = colorFor(next, score: scores[next])

                var seg = Path()
                seg.move(to: center)
                seg.addLine(to: p1)
                seg.addLine(to: p2)
                seg.closeSubpath()
                context.fill(seg, with: .color(c1.opacity(0.15)))

                var edge = Path()
                edge.move(to: p1)
                edge.addLine(to: p2)
                context.stroke(edge, with: .color(c1.opacity(0.5).blended(with: c2.opacity(0.5))), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            }

            for i in 0..<count {
                let r = maxR * CGFloat(scores[i]) / 100
                let p2 = pt(i, r)
                let c = colorFor(i, score: scores[i])
                context.fill(Path(ellipseIn: CGRect(x: p2.x - 5, y: p2.y - 5, width: 10, height: 10)), with: .color(c))
                context.fill(Path(ellipseIn: CGRect(x: p2.x - 2, y: p2.y - 2, width: 4, height: 4)), with: .color(.white))
            }

            let labels = ["Upper", "Lower", "Obliqs", "D.Core", "Sym", "V-Tap"]
            for i in 0..<count {
                let p2 = pt(i, maxR + 16)
                let c = colorFor(i, score: scores[i])
                context.draw(
                    Text(labels[i]).font(.system(size: 9, weight: .bold)).foregroundStyle(c.opacity(0.7)),
                    at: p2
                )
            }
        }
    }
}

extension Color {
    func blended(with other: Color) -> Color {
        let uiSelf = UIColor(self)
        let uiOther = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        uiSelf.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiOther.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(red: (r1 + r2) / 2, green: (g1 + g2) / 2, blue: (b1 + b2) / 2).opacity(Double((a1 + a2) / 2))
    }
}
