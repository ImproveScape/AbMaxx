import SwiftUI

struct FeelConfidentView: View {
    @State private var phase: Int = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text("It's time to feel")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .opacity(phase >= 1 ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: phase)

                Text("CONFIDENT")
                    .font(.system(size: 50, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: AppTheme.primaryAccent.opacity(glowPulse ? 0.7 : 0.15), radius: glowPulse ? 35 : 12)
                    .opacity(phase >= 2 ? 1 : 0)
                    .scaleEffect(phase >= 2 ? 1 : 0.85)
                    .animation(.spring(duration: 0.6, bounce: 0.15), value: phase)

                Text("in your own body.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .opacity(phase >= 2 ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.15), value: phase)

                Capsule()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: phase >= 3 ? 40 : 0, height: 3)
                    .animation(.spring(duration: 0.6), value: phase)
                    .padding(.top, 8)

                Text("You deserve to look in the mirror\nand actually love what you see.")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(phase >= 3 ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: phase)
            }
            .padding(.horizontal, 36)

            Spacer()
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation { phase = 2 }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation { phase = 3 }
            }
        }
    }
}
