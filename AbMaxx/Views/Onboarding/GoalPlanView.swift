import SwiftUI

struct GoalPlanView: View {
    let goal: AbsGoal
    let username: String

    @State private var phase: Int = 0
    @State private var glowPulse: Bool = false
    @State private var shimmerOffset: CGFloat = -1.5
    @State private var particleActive: Bool = false
    @State private var hapticTrigger: Int = 0

    private var goalConfig: GoalDisplayConfig {
        switch goal {
        case .visibleAbs:
            return GoalDisplayConfig(
                headline: "Reveal Your Abs",
                subtitle: "Here's your personalized plan to uncover what's already there.",
                accentColor: Color(red: 0.30, green: 0.85, blue: 1.0),
                steps: [
                    StepItem(icon: "flame.fill", title: "Smart Deficit", detail: "Calculated to your metabolism — burn fat without losing muscle"),
                    StepItem(icon: "figure.core.training", title: "Targeted Training", detail: "Progressive ab routines that build definition fast"),
                    StepItem(icon: "camera.viewfinder", title: "AI Body Scans", detail: "Track real changes weekly — not just the scale"),
                    StepItem(icon: "chart.line.uptrend.xyaxis", title: "Visible in Weeks", detail: "Most users see definition within 4–6 weeks"),
                ]
            )
        case .sixPack:
            return GoalDisplayConfig(
                headline: "Build Your Six-Pack",
                subtitle: "The elite plan — high protein, precision cuts, maximum definition.",
                accentColor: Color(red: 1.0, green: 0.78, blue: 0.2),
                steps: [
                    StepItem(icon: "bolt.fill", title: "Lean Cut Protocol", detail: "Aggressive but sustainable — high protein keeps muscle intact"),
                    StepItem(icon: "dumbbell.fill", title: "Hypertrophy Focus", detail: "Ab-specific volume training to maximize each muscle"),
                    StepItem(icon: "camera.viewfinder", title: "Weekly AI Scans", detail: "Watch each ab pop into visibility over time"),
                    StepItem(icon: "trophy.fill", title: "Six-Pack Timeline", detail: "A clear path from where you are to where you want to be"),
                ]
            )
        case .loseBellyFat:
            return GoalDisplayConfig(
                headline: "Torch Belly Fat",
                subtitle: "An aggressive but healthy plan to strip away stubborn fat.",
                accentColor: Color(red: 1.0, green: 0.45, blue: 0.3),
                steps: [
                    StepItem(icon: "flame.circle.fill", title: "Fat-Burn Mode", detail: "Optimized calorie deficit that targets belly fat first"),
                    StepItem(icon: "fork.knife", title: "Nutrition Engine", detail: "Meal guidance that keeps you full while in deficit"),
                    StepItem(icon: "figure.run", title: "Core + Cardio", detail: "Routines that burn calories and build a foundation"),
                    StepItem(icon: "chart.bar.fill", title: "Weekly Check-ins", detail: "See your waist shrink and confidence grow"),
                ]
            )
        case .coreStrength:
            return GoalDisplayConfig(
                headline: "Bulletproof Your Core",
                subtitle: "Strength from the inside out — stability, power, performance.",
                accentColor: Color(red: 0.5, green: 0.8, blue: 1.0),
                steps: [
                    StepItem(icon: "bolt.shield.fill", title: "Strength Protocol", detail: "Progressive overload for deep core muscles"),
                    StepItem(icon: "fork.knife", title: "Performance Fuel", detail: "Maintenance calories to keep strength gains coming"),
                    StepItem(icon: "figure.strengthtraining.traditional", title: "Functional Training", detail: "Exercises that translate to real-world power"),
                    StepItem(icon: "gauge.open.with.lines.needle.33percent.and.arrowtriangle", title: "Strength Score", detail: "Track your core power level over time"),
                ]
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 12)

            VStack(spacing: 6) {
                Text(goalConfig.headline)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
                    .opacity(phase >= 1 ? 1 : 0)
                    .offset(y: phase >= 1 ? 0 : 15)

                Text(goalConfig.subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
                    .opacity(phase >= 1 ? 1 : 0)
                    .offset(y: phase >= 1 ? 0 : 10)
            }
            .animation(.spring(duration: 0.6, bounce: 0.15), value: phase)
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)

            VStack(spacing: 0) {
                ForEach(Array(goalConfig.steps.enumerated()), id: \.offset) { index, step in
                    stepRow(index: index, step: step)

                    if index < goalConfig.steps.count - 1 {
                        HStack(spacing: 0) {
                            Spacer().frame(width: 28)
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            phase >= index + 2 ? goalConfig.accentColor.opacity(0.4) : Color.white.opacity(0.04),
                                            phase >= index + 2 ? goalConfig.accentColor.opacity(0.1) : Color.white.opacity(0.04)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 2, height: 24)
                                .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: phase)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 28)

            if phase >= 6 {
                personalizedBadge
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            Spacer()
        }
        .background(backgroundOrbs)
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
        .onAppear { startSequence() }
    }

    private func stepRow(index: Int, step: StepItem) -> some View {
        let isRevealed = phase >= index + 2
        let config = goalConfig

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isRevealed ? config.accentColor.opacity(0.15) : Color.white.opacity(0.03))
                    .frame(width: 52, height: 52)

                Circle()
                    .strokeBorder(
                        isRevealed ? config.accentColor.opacity(0.4) : Color.white.opacity(0.06),
                        lineWidth: 1.5
                    )
                    .frame(width: 52, height: 52)

                if isRevealed {
                    Image(systemName: step.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(config.accentColor)
                        .transition(.scale.combined(with: .opacity))
                        .shadow(color: config.accentColor.opacity(0.4), radius: 8)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.15))
                }
            }
            .animation(.spring(duration: 0.5, bounce: 0.3), value: isRevealed)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isRevealed ? .white : .white.opacity(0.15))

                Text(step.detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isRevealed ? AppTheme.secondaryText : AppTheme.secondaryText.opacity(0.3))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isRevealed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(config.accentColor)
                    .transition(.scale.combined(with: .opacity))
                    .shadow(color: config.accentColor.opacity(0.3), radius: 6)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isRevealed ? config.accentColor.opacity(0.04) : .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isRevealed ? config.accentColor.opacity(0.12) : .clear,
                            lineWidth: 1
                        )
                )
        )
        .opacity(isRevealed ? 1 : 0.4)
        .offset(x: isRevealed ? 0 : 20)
        .animation(.spring(duration: 0.55, bounce: 0.2).delay(Double(index) * 0.05), value: isRevealed)
    }

    private var personalizedBadge: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(goalConfig.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(goalConfig.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Built for \(username.isEmpty ? "you" : username)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text("Personalized to your goal & body")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(goalConfig.accentColor.opacity(0.6))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(goalConfig.accentColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(goalConfig.accentColor.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }

    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(goalConfig.accentColor.opacity(glowPulse ? 0.06 : 0.02))
                .frame(width: 350, height: 350)
                .blur(radius: 120)
                .offset(y: -100)

            Circle()
                .fill(AppTheme.primaryAccent.opacity(glowPulse ? 0.04 : 0.01))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: 120, y: 250)
        }
        .ignoresSafeArea()
    }

    private func startSequence() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation { phase = 1 }
            hapticTrigger += 1

            try? await Task.sleep(for: .milliseconds(500))

            for i in 2...5 {
                withAnimation { phase = i }
                hapticTrigger += 1
                try? await Task.sleep(for: .milliseconds(350))
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.5, bounce: 0.25)) { phase = 6 }
            hapticTrigger += 1
        }
    }
}

private struct GoalDisplayConfig {
    let headline: String
    let subtitle: String
    let accentColor: Color
    let steps: [StepItem]
}

private struct StepItem {
    let icon: String
    let title: String
    let detail: String
}
