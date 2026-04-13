import SwiftUI

struct BadNewsRevealView: View {
    let scanResult: ScanResult
    let username: String
    let onContinue: () -> Void

    @State private var phase: Int = 0
    @State private var currentBarHeight: CGFloat = 0
    @State private var potentialBarHeight: CGFloat = 0
    @State private var glowPulse: Bool = false
    @State private var countUp: Int = 0

    private var currentPercent: Int {
        max(8, min(scanResult.overallScore, 65))
    }

    private var potentialPercent: Int {
        min(100, max(currentPercent + 30, scanResult.geneticPotential + 15))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            VStack(spacing: 12) {
                Text("\(username), your scan\nrevealed something")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(phase >= 1 ? 1 : 0)
                    .offset(y: phase >= 1 ? 0 : 16)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: phase)

                Text("You\u{2019}re walking around at only **\(countUp)%** of\nwhat your abs could look like.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(phase >= 2 ? 1 : 0)
                    .offset(y: phase >= 2 ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: phase)
            }

            Spacer().frame(height: 48)

            barsSection
                .opacity(phase >= 3 ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: phase)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.accentGradient)
                    .clipShape(.capsule)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 8)
            }
            .opacity(phase >= 4 ? 1 : 0)
            .offset(y: phase >= 4 ? 0 : 16)
            .animation(.spring(duration: 0.5, bounce: 0.2), value: phase)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .onAppear { runSequence() }
    }

    private var barsSection: some View {
        HStack(spacing: 0) {
            Spacer()

            barColumn(
                label: "You Now",
                percent: currentPercent,
                targetHeight: currentBarHeight,
                color: AppTheme.destructive
            )

            Spacer()

            barColumn(
                label: "Your Potential",
                percent: potentialPercent,
                targetHeight: potentialBarHeight,
                color: AppTheme.primaryAccent
            )

            Spacer()
        }
        .frame(height: 260)
        .padding(.horizontal, 32)
        .onChange(of: phase) { _, newVal in
            if newVal >= 3 {
                withAnimation(.spring(duration: 1.2, bounce: 0.05).delay(0.2)) {
                    currentBarHeight = 1.0
                }
                withAnimation(.spring(duration: 1.2, bounce: 0.05).delay(0.5)) {
                    potentialBarHeight = 1.0
                }
                animateCount()
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.5)) {
                    glowPulse = true
                }
            }
        }
    }

    private func barColumn(label: String, percent: Int, targetHeight: CGFloat, color: Color) -> some View {
        VStack(spacing: 14) {
            Text("\(percent)%")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(color)
                .opacity(targetHeight > 0.5 ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: targetHeight)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 64, height: 160)

                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.5), color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 64, height: 160 * CGFloat(percent) / 100.0 * targetHeight)
                    .shadow(color: color.opacity(glowPulse ? 0.5 : 0.15), radius: glowPulse ? 16 : 6)
            }

            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(width: 120)
    }

    private func animateCount() {
        let target = currentPercent
        countUp = 0
        let interval: Double = 0.8 / Double(max(target, 1))
        for i in 1...target {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * interval) {
                countUp = i
            }
        }
    }

    private func runSequence() {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            phase = 1
            try? await Task.sleep(for: .milliseconds(500))
            phase = 2
            try? await Task.sleep(for: .milliseconds(500))
            phase = 3
            try? await Task.sleep(for: .milliseconds(1800))
            phase = 4
        }
    }
}
