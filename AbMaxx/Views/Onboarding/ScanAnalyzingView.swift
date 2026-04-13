import SwiftUI

struct ScanAnalyzingView: View {
    let onComplete: () -> Void
    @State private var progress: Double = 0
    @State private var currentStep: Int = 0
    @State private var pulseGlow: Bool = false

    private let steps = [
        "Scanning muscle structure",
        "Measuring definition depth",
        "Analyzing symmetry",
        "Evaluating oblique separation",
        "Calculating frame ratio",
        "Assessing tightness",
        "Scoring aesthetic appeal",
        "Finalizing results",
    ]

    var body: some View {
        ZStack {
        AppTheme.background.ignoresSafeArea()
        AppTheme.backgroundGradient.ignoresSafeArea()
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 44) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(pulseGlow ? 0.06 : 0.01))
                        .frame(width: 180, height: 180)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulseGlow)

                    Circle()
                        .stroke(AppTheme.border.opacity(0.1), lineWidth: 4)
                        .frame(width: 130, height: 130)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AppTheme.accentGradient,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 6) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.primaryAccent)
                            .symbolEffect(.pulse)

                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: Int(progress * 100))
                    }
                }

                VStack(spacing: 10) {
                    Text("Analyzing Your Abs")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text(steps[currentStep])
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                        .contentTransition(.opacity)
                        .id(currentStep)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .sensoryFeedback(.impact(weight: .light), trigger: currentStep)
        .onAppear {
            pulseGlow = true
            startAnalysis()
        }
        }
    }

    private func startAnalysis() {
        Task {
            for index in 0..<steps.count {
                withAnimation(.snappy) { currentStep = index }
                let stepProgress = Double(index + 1) / Double(steps.count)
                withAnimation(.easeInOut(duration: 0.5)) { progress = stepProgress }
                let delay = index < 2 ? 1100 : (index < 5 ? 900 : 700)
                try? await Task.sleep(for: .milliseconds(delay))
            }
            try? await Task.sleep(for: .milliseconds(500))
            onComplete()
        }
    }
}
