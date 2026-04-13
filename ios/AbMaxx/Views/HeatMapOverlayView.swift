import SwiftUI

struct HeatMapOverlayView: View {
    let zones: [HeatMapZone]
    let imageSize: CGSize
    @State private var opacity: Double = 0

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

                let color = heatColor(for: zone.definitionScore)
                let zoneOpacity = heatOpacity(for: zone.definitionScore)

                let path = Path(roundedRect: rect, cornerRadius: min(w, h) * 0.2)
                context.fill(path, with: .color(color.opacity(zoneOpacity)))
                context.stroke(path, with: .color(color.opacity(0.6)), lineWidth: 1.5)

                let scoreText = "\(zone.definitionScore)"
                var attrs = AttributeContainer()
                attrs.font = .system(size: max(10, min(w, h) * 0.25), weight: .heavy)
                attrs.foregroundColor = UIColor.white
                let resolved = context.resolve(Text(AttributedString(scoreText, attributes: attrs)))
                context.draw(resolved, at: CGPoint(x: cx, y: cy))
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .onAppear {
            if opacity == 0 {
                withAnimation(.easeOut(duration: 1.2)) {
                    opacity = 1
                }
            } else {
                opacity = 1
            }
        }
    }

    private func heatColor(for score: Int) -> Color {
        if score >= 80 {
            return Color(red: 0.0, green: 1.0, blue: 0.4)
        } else if score >= 65 {
            return Color(red: 0.2, green: 0.9, blue: 0.2)
        } else if score >= 50 {
            return Color(red: 1.0, green: 0.85, blue: 0.0)
        } else if score >= 35 {
            return Color(red: 1.0, green: 0.5, blue: 0.0)
        } else {
            return Color(red: 1.0, green: 0.15, blue: 0.15)
        }
    }

    private func heatOpacity(for score: Int) -> Double {
        if score >= 80 { return 0.35 }
        if score >= 65 { return 0.4 }
        if score >= 50 { return 0.45 }
        if score >= 35 { return 0.5 }
        return 0.55
    }
}
