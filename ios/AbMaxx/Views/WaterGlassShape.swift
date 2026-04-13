import SwiftUI

struct WaterGlassShape: View {
    let fillLevel: Double
    let index: Int

    private let waterColor = Color(red: 0.3, green: 0.7, blue: 1.0)

    var body: some View {
        let filled = fillLevel > 0

        Circle()
            .fill(
                filled
                    ? LinearGradient(
                        colors: [waterColor.opacity(0.9), waterColor.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                      )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                      )
            )
            .overlay {
                Circle()
                    .strokeBorder(
                        filled ? waterColor.opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            }
            .overlay {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(filled ? .white : Color.white.opacity(0.2))
            }
            .frame(width: 36, height: 36)
            .scaleEffect(filled ? 1.0 : 0.92)
            .animation(.spring(duration: 0.35, bounce: 0.3).delay(Double(index) * 0.03), value: fillLevel)
    }
}
