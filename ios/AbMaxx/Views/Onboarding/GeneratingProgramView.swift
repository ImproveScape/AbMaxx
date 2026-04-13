import SwiftUI

struct GeneratingProgramView: View {
    let profile: UserProfile
    let onComplete: () -> Void

    @State private var activeIndex: Int = -1
    @State private var completedIndices: Set<Int> = []
    @State private var headerVisible: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var allDone: Bool = false
    @State private var overallProgress: CGFloat = 0
    @State private var currentStatusText: String = ""
    @State private var pulseGlow: Bool = false

    private let greenCheck = Color(hex: "30D158")

    private var steps: [(label: String, status: String)] {
        [
            ("Targeting your weak points", "Analyzing your abs..."),
            ("Daily calories", "Calculating your intake..."),
            ("Ab exercises", "Matching to your body type..."),
            ("Weekly schedule", "Building your routine..."),
            ("Transformation timeline", "Mapping your progress..."),
            ("Plan locked in", "Finalizing your plan..."),
        ]
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [AppTheme.primaryAccent.opacity(pulseGlow ? 0.06 : 0.01), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseGlow)

            VStack(spacing: 0) {
                Spacer()

                percentageHeader
                    .opacity(headerVisible ? 1 : 0)
                    .scaleEffect(headerVisible ? 1 : 0.92)

                Spacer().frame(height: 32)

                progressBar
                    .opacity(headerVisible ? 1 : 0)

                Spacer().frame(height: 12)

                Text(currentStatusText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: currentStatusText)
                    .frame(height: 22)
                    .opacity(headerVisible ? 1 : 0)

                Spacer().frame(height: 40)

                checklistSection

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
        .onAppear {
            pulseGlow = true
            startSequence()
        }
    }

    private var percentageHeader: some View {
        VStack(spacing: 10) {
            Text("\(Int(overallProgress * 100))%")
                .font(.system(size: 64, weight: .heavy))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: Int(overallProgress * 100))

            Text(allDone ? "Your plan is ready" : "We're setting everything\nup for you")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: allDone)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent, Color(red: 0.15, green: 0.75, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geo.size.width * overallProgress, 6), height: 6)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 8)
            }
        }
        .frame(height: 6)
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                let isDone = completedIndices.contains(index)
                let isActive = index == activeIndex
                let isVisible = index <= activeIndex || isDone

                HStack(spacing: 16) {
                    ZStack {
                        if isDone {
                            Circle()
                                .fill(greenCheck)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(.white)
                        } else if isActive {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1.5)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(.white.opacity(0.6))
                                }
                        } else {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .animation(.spring(duration: 0.4, bounce: 0.2), value: isDone)

                    Text(step.label)
                        .font(.system(size: 16, weight: isDone ? .semibold : .medium))
                        .foregroundStyle(
                            isDone ? .white : isActive ? .white.opacity(0.8) : .white.opacity(0.2)
                        )

                    Spacer()

                    if isDone {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(greenCheck)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }
                .padding(.vertical, 14)
                .opacity(isVisible ? 1 : 0.3)
                .animation(.easeInOut(duration: 0.3), value: isActive)
                .animation(.spring(duration: 0.35), value: isDone)

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                        .padding(.leading, 44)
                }
            }
        }
    }

    private func startSequence() {
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) { headerVisible = true }
            try? await Task.sleep(for: .milliseconds(500))

            currentStatusText = "Engineered for your abs"

            for index in 0..<steps.count {
                withAnimation(.easeInOut(duration: 0.25)) {
                    activeIndex = index
                    currentStatusText = steps[index].status
                }

                let duration = Int.random(in: 1400...2200)
                let progressSteps = 15
                let stepDelay = duration / progressSteps
                for s in 1...progressSteps {
                    try? await Task.sleep(for: .milliseconds(stepDelay))
                    withAnimation(.easeOut(duration: 0.15)) {
                        overallProgress = (CGFloat(index) + CGFloat(s) / CGFloat(progressSteps)) / CGFloat(steps.count)
                    }
                }

                withAnimation(.spring(duration: 0.4, bounce: 0.25)) {
                    completedIndices.insert(index)
                }
                hapticTrigger += 1

                try? await Task.sleep(for: .milliseconds(300))
            }

            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                allDone = true
                activeIndex = -1
                overallProgress = 1.0
                currentStatusText = "Your personalized plan is ready"
            }
            hapticTrigger += 1

            try? await Task.sleep(for: .milliseconds(900))
            onComplete()
        }
    }
}
