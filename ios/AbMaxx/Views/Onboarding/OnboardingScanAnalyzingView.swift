import SwiftUI

struct OnboardingScanAnalyzingView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var currentPhaseIndex: Int = 0
    @State private var analysisStarted: Bool = false
    @State private var scanLineY: CGFloat = 0
    @State private var ringRotation: Double = 0
    @State private var completedMetrics: Set<Int> = []
    @State private var activeMetricIndex: Int = -1
    @State private var pulseGlow: Bool = false

    private let phases: [(title: String, subtitle: String)] = [
        ("Identifying your genetics", "Reading muscle fiber composition"),
        ("Mapping ab insertions", "Analyzing tendon placement"),
        ("Measuring definition depth", "Scanning shadow contrast"),
        ("Analyzing symmetry", "Comparing left & right balance"),
        ("Evaluating core density", "Calculating muscle thickness"),
        ("Compiling your score", "Finalizing results"),
    ]

    private let metrics: [(label: String, subtitle: String)] = [
        ("Upper Abs", "Identifying genetics"),
        ("Lower Abs", "Mapping insertions"),
        ("Obliques", "Detecting separation"),
        ("Symmetry", "Measuring balance"),
        ("Body Fat", "Estimating composition"),
        ("Core Depth", "Analyzing thickness"),
    ]

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
                Spacer().frame(height: 60)

                scanImageArea

                Spacer().frame(height: 32)

                phaseLabel

                Spacer().frame(height: 28)

                progressSection

                Spacer().frame(height: 32)

                metricsList

                Spacer()

                if viewModel.scanThumbnail != nil {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: 5, height: 5)
                        Text("AI Vision Active")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.success.opacity(0.8))
                    }
                    .padding(.bottom, 40)
                }
            }
            .padding(.horizontal, 24)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: currentPhaseIndex)
        .sensoryFeedback(.impact(weight: .medium), trigger: completedMetrics.count)
        .onAppear {
            guard !analysisStarted else { return }
            analysisStarted = true
            pulseGlow = true
            startScanLineAnimation()
            startRingRotation()
            startAnalysisFlow()
        }
    }

    private var scanImageArea: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                .frame(width: 190, height: 190)

            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(AppTheme.primaryAccent.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .trim(from: 0.5, to: 0.7)
                .stroke(AppTheme.primaryAccent.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-ringRotation * 0.7))

            if let image = viewModel.scanThumbnail {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 160)
                    .clipShape(Circle())
                    .allowsHitTesting(false)
            } else {
                Circle()
                    .fill(AppTheme.cardSurface)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Image(systemName: "figure.stand")
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundStyle(AppTheme.primaryAccent.opacity(0.2))
                    )
            }

            scanLineOverlay

            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.primaryAccent.opacity(0.4), AppTheme.primaryAccent.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 160, height: 160)
        }
        .shadow(color: AppTheme.primaryAccent.opacity(0.12), radius: 25)
    }

    private var scanLineOverlay: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.primaryAccent.opacity(0),
                            AppTheme.primaryAccent.opacity(0.5),
                            Color(red: 0.15, green: 0.75, blue: 1.0).opacity(0.7),
                            AppTheme.primaryAccent.opacity(0.5),
                            AppTheme.primaryAccent.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 150, height: 2)
                .blur(radius: 0.5)
                .overlay(
                    Rectangle()
                        .fill(AppTheme.primaryAccent.opacity(0.12))
                        .frame(width: 150, height: 25)
                        .blur(radius: 10)
                )
                .offset(y: scanLineY)
        }
        .frame(width: 160, height: 160)
        .clipShape(Circle())
    }

    private var phaseLabel: some View {
        VStack(spacing: 6) {
            Text(phases[currentPhaseIndex].title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.opacity)
                .id("phase-\(currentPhaseIndex)")
                .animation(.easeInOut(duration: 0.3), value: currentPhaseIndex)

            Text(phases[currentPhaseIndex].subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.muted)
                .contentTransition(.opacity)
                .id("sub-\(currentPhaseIndex)")
                .animation(.easeInOut(duration: 0.3), value: currentPhaseIndex)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
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
                        .frame(width: max(geo.size.width * progress, 6), height: 6)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 8)
                }
            }
            .frame(height: 6)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: Int(progress * 100))
        }
    }

    private var metricsList: some View {
        VStack(spacing: 6) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                let isComplete = completedMetrics.contains(index)
                let isActive = activeMetricIndex == index

                HStack(spacing: 12) {
                    ZStack {
                        if isComplete {
                            Circle()
                                .fill(AppTheme.success)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        } else if isActive {
                            Circle()
                                .strokeBorder(AppTheme.primaryAccent.opacity(0.5), lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                            Circle()
                                .fill(AppTheme.primaryAccent.opacity(0.3))
                                .frame(width: 10, height: 10)
                        } else {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                .frame(width: 22, height: 22)
                        }
                    }
                    .animation(.spring(duration: 0.4), value: isComplete)
                    .animation(.easeInOut(duration: 0.3), value: isActive)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(isComplete ? 1.0 : (isActive ? 0.8 : 0.3)))

                        if isActive && !isComplete {
                            Text(metric.subtitle)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.primaryAccent.opacity(0.7))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else if isComplete {
                            Text("Complete")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.success.opacity(0.7))
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: isActive)
                    .animation(.easeInOut(duration: 0.25), value: isComplete)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isComplete ? Color.white.opacity(0.04)
                    : (isActive ? AppTheme.primaryAccent.opacity(0.04) : Color.clear)
                )
                .clipShape(.rect(cornerRadius: 10))
                .animation(.easeOut(duration: 0.3), value: isComplete)
                .animation(.easeOut(duration: 0.3), value: isActive)
            }
        }
    }

    private func startScanLineAnimation() {
        scanLineY = -70
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            scanLineY = 70
        }
    }

    private func startRingRotation() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }

    private func startAnalysisFlow() {
        Task { @MainActor in
            await runAnimationSequence()

            guard !Task.isCancelled else { return }

            var waitCount = 0
            while !viewModel.analysisAPIFinished && waitCount < 120 {
                try? await Task.sleep(for: .milliseconds(500))
                waitCount += 1
                guard !Task.isCancelled else { return }
            }

            guard !Task.isCancelled else { return }

            viewModel.applyPendingOutcome()

            progress = 1.0
            try? await Task.sleep(for: .milliseconds(600))

            guard !Task.isCancelled else { return }

            if viewModel.poorPhotoDetected {
                viewModel.goBackToScanIntro()
                return
            }

            if viewModel.scanResult == nil {
                viewModel.goBackToScanIntro()
                return
            }

            onComplete()
        }
    }

    private func runAnimationSequence() async {
        let metricCount = metrics.count
        let phaseCount = phases.count

        for i in 0..<metricCount {
            guard !Task.isCancelled else { return }

            let phaseIndex = min(i, phaseCount - 1)
            currentPhaseIndex = phaseIndex
            activeMetricIndex = i

            let stepProgress = Double(i) / Double(metricCount)
            withAnimation(.easeInOut(duration: 0.4)) { progress = stepProgress }

            let delay = i < 2 ? 1200 : (i < 4 ? 1000 : 900)
            try? await Task.sleep(for: .milliseconds(delay))

            guard !Task.isCancelled else { return }
            completedMetrics.insert(i)

            if i < metricCount - 1 {
                try? await Task.sleep(for: .milliseconds(200))
            }
        }

        guard !Task.isCancelled else { return }

        if phaseCount > 0 {
            currentPhaseIndex = phaseCount - 1
        }
        activeMetricIndex = -1
    }
}

nonisolated struct ScanDataPoint: Sendable {
    let label: String
    let value: String
    let icon: String
    let angle: Double
}
