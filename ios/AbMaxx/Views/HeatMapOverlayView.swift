import SwiftUI

struct HeatMapOverlayView: View {
    let zones: [HeatMapZone]
    let imageSize: CGSize
    @State private var appeared: Bool = false

    var body: some View {
        Canvas { context, size in
            for zone in zones {
                let cx = zone.centerX * size.width
                let cy = zone.centerY * size.height
                let w = zone.width * size.width
                let h = zone.height * size.height
                let rect = CGRect(
                    x: cx - w / 2,
                    y: cy - h / 2,
                    width: w,
                    height: h
                )

                let score = zone.definitionScore
                let baseColor = heatColor(for: score)
                let fillOpacity = appeared ? fillOpacityForScore(score) : 0
                let cornerRadius = min(w, h) * 0.15

                let path = Path(roundedRect: rect, cornerRadius: cornerRadius)

                context.fill(path, with: .color(baseColor.opacity(fillOpacity)))

                let innerRect = rect.insetBy(dx: 2, dy: 2)
                let innerPath = Path(roundedRect: innerRect, cornerRadius: max(0, cornerRadius - 2))
                let innerOpacity = appeared ? max(0.1, fillOpacity - 0.15) : 0
                context.fill(innerPath, with: .color(baseColor.opacity(innerOpacity)))

                let borderOpacity = appeared ? min(1.0, fillOpacity + 0.25) : 0
                context.stroke(path, with: .color(baseColor.opacity(borderOpacity)), lineWidth: 2)

                if appeared {
                    let scoreText = "\(score)"
                    var attrs = AttributeContainer()
                    attrs.font = .system(size: max(11, min(w, h) * 0.28), weight: .black)
                    attrs.foregroundColor = UIColor.white
                    let resolved = context.resolve(Text(AttributedString(scoreText, attributes: attrs)))

                    let shadowRect = CGRect(
                        x: cx - min(w, h) * 0.35,
                        y: cy - min(w, h) * 0.22,
                        width: min(w, h) * 0.7,
                        height: min(w, h) * 0.44
                    )
                    let pillPath = Path(roundedRect: shadowRect, cornerRadius: min(w, h) * 0.12)
                    context.fill(pillPath, with: .color(Color.black.opacity(0.55)))

                    context.draw(resolved, at: CGPoint(x: cx, y: cy))
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                appeared = true
            }
        }
    }

    private func heatColor(for score: Int) -> Color {
        if score >= 85 {
            return Color(red: 0.0, green: 0.95, blue: 0.35)
        } else if score >= 75 {
            return Color(red: 0.1, green: 0.85, blue: 0.25)
        } else if score >= 65 {
            return Color(red: 0.6, green: 0.9, blue: 0.0)
        } else if score >= 55 {
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        } else if score >= 45 {
            return Color(red: 1.0, green: 0.55, blue: 0.0)
        } else if score >= 35 {
            return Color(red: 1.0, green: 0.3, blue: 0.0)
        } else {
            return Color(red: 1.0, green: 0.12, blue: 0.12)
        }
    }

    private func fillOpacityForScore(_ score: Int) -> Double {
        if score >= 85 { return 0.65 }
        if score >= 75 { return 0.60 }
        if score >= 65 { return 0.58 }
        if score >= 55 { return 0.55 }
        if score >= 45 { return 0.55 }
        if score >= 35 { return 0.58 }
        return 0.60
    }
}
