import SwiftUI

struct GrowthChartSlide: View {
    let onBack: () -> Void
    let onNext: () -> Void
    let currentPage: Int
    let totalPages: Int
    var currentScore: Int = 42

    @State private var phase: Int = 0
    @State private var barProgress: CGFloat = 0
    @State private var pulseGlow: Bool = false

    private var currentPercent: Int {
        max(15, min(currentScore, 65))
    }

    private let potentialPercent: Int = 100

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(minHeight: 20, maxHeight: 48)

                VStack(spacing: 12) {
                    Text("We found something\nyou need to see")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(phase >= 1 ? 1 : 0)
                        .offset(y: phase >= 1 ? 0 : 12)
                        .animation(.spring(duration: 0.5), value: phase)

                    Text("You're walking around at only **\(currentPercent)%** of\nwhat your abs could look like.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .opacity(phase >= 2 ? 1 : 0)
                        .offset(y: phase >= 2 ? 0 : 10)
                        .animation(.spring(duration: 0.5), value: phase)
                }
                .padding(.horizontal, 24)

                Spacer().frame(minHeight: 32, maxHeight: 56)

                barsSection
                    .padding(.horizontal, 32)
                    .opacity(phase >= 3 ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: phase)

                Spacer().frame(minHeight: 20, maxHeight: 36)

                Text("AbMaxx closes this gap for you.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .opacity(phase >= 4 ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: phase)

                Spacer()

                Button(action: onNext) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.primaryAccent)
                        .clipShape(.capsule)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 24, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(phase >= 4 ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: phase)

                pageDots
                    .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { runEntrance() }
    }

    private var barsSection: some View {
        HStack(spacing: 24) {
            barColumn(
                label: "You Now",
                percent: currentPercent,
                fillRatio: CGFloat(currentPercent) / 100.0,
                color: AppTheme.muted.opacity(0.5),
                labelColor: AppTheme.muted,
                isHighlighted: false
            )

            barColumn(
                label: "Your Potential",
                percent: potentialPercent,
                fillRatio: 1.0,
                color: AppTheme.primaryAccent,
                labelColor: AppTheme.primaryAccent,
                isHighlighted: true
            )
        }
        .frame(height: 280)
    }

    private func barColumn(
        label: String,
        percent: Int,
        fillRatio: CGFloat,
        color: Color,
        labelColor: Color,
        isHighlighted: Bool
    ) -> some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let maxH = geo.size.height
                let targetH = maxH * fillRatio
                let animatedH = targetH * barProgress

                VStack(spacing: 0) {
                    Spacer()

                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                isHighlighted
                                    ? LinearGradient(
                                        colors: [color, color.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    : LinearGradient(
                                        colors: [color, color.opacity(0.4)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )
                            .frame(height: animatedH)

                        if isHighlighted && barProgress > 0.5 {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.primaryAccent.opacity(pulseGlow ? 0.15 : 0.05))
                                .frame(height: animatedH)
                                .blur(radius: 12)
                        }

                        Text("\(percent)%")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.top, animatedH > 50 ? 16 : 4)
                            .opacity(barProgress > 0.6 ? 1 : 0)
                            .animation(.easeIn(duration: 0.3).delay(0.2), value: barProgress)
                    }
                }
            }

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(labelColor)
                .multilineTextAlignment(.center)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? AppTheme.primaryAccent : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func runEntrance() {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation { phase = 1 }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation { phase = 2 }
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation { phase = 3 }
            withAnimation(.spring(response: 1.0, dampingFraction: 0.75).delay(0.1)) {
                barProgress = 1
            }
            try? await Task.sleep(for: .milliseconds(800))
            withAnimation { phase = 4 }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
    }
}
