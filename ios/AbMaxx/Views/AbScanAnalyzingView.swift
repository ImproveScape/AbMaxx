import SwiftUI

struct AbScanAnalyzingView: View {
    let capturedImage: UIImage?
    var resultReady: Bool = false
    let onComplete: () -> Void
    @State private var progress: Double = 0
    @State private var currentStep: Int = 0
    @State private var scanLineY: CGFloat = 0
    @State private var pulseGlow: Bool = false
    @State private var animationDone: Bool = false
    @State private var ringRotation: Double = 0
    @State private var showDataPoint: Int = -1

    private let steps = [
        "Initializing AI Vision...",
        "Detecting muscle groups...",
        "Measuring ab definition...",
        "Analyzing symmetry & thickness...",
        "Scanning obliques & frame...",
        "Rating aesthetic appeal...",
        "Generating AbMaxx Score...",
    ]

    private let dataLabels: [(label: String, value: String, icon: String)] = [
        ("RECTUS ABDOMINIS", "DETECTED", "checkmark.circle.fill"),
        ("BODY FAT", "ANALYZING", "waveform.path"),
        ("SYMMETRY", "MAPPING", "arrow.left.and.right"),
        ("DEFINITION", "SCANNING", "lines.measurement.horizontal"),
        ("OBLIQUES", "DETECTED", "checkmark.circle.fill"),
        ("CORE DENSITY", "MEASURING", "gauge.with.dots.needle.33percent"),
    ]

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            Circle()
                .fill(AppTheme.primaryAccent.opacity(pulseGlow ? 0.1 : 0.02))
                .frame(width: 500, height: 500)
                .blur(radius: 120)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulseGlow)

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("ANALYZING YOUR ABS")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(4)

                Spacer().frame(height: 32)

                scanCircleArea

                Spacer().frame(height: 28)

                VStack(spacing: 10) {
                    Text(steps[currentStep])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                        .id(currentStep)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)

                    HStack(spacing: 4) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(AppTheme.primaryAccent)
                                .frame(width: 4, height: 4)
                                .opacity(dotOpacity(index: i))
                        }
                    }
                }

                Spacer().frame(height: 28)

                progressSection

                Spacer()
            }
            .padding(.horizontal, 24)

            ForEach(Array(dataLabels.enumerated()), id: \.offset) { index, point in
                if showDataPoint >= index {
                    dataLabel(label: point.label, value: point.value, icon: point.icon, index: index)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: currentStep)
        .onChange(of: resultReady) { _, ready in
            if ready && animationDone {
                Task { await finishAnalysis() }
            }
        }
        .onAppear {
            pulseGlow = true
            startScanLineAnimation()
            startRingRotation()
            startDataPointReveal()
            startAnalysis()
        }
    }

    private var scanCircleArea: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primaryAccent.opacity(0.03))
                .frame(width: 240, height: 240)

            Circle()
                .stroke(AppTheme.border.opacity(0.15), lineWidth: 2)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    AppTheme.primaryAccent.opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4])
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .trim(from: 0.5, to: 0.7)
                .stroke(
                    AppTheme.primaryAccent.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4])
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-ringRotation))

            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .allowsHitTesting(false)
            } else {
                Circle()
                    .fill(AppTheme.cardSurface)
                    .frame(width: 180, height: 180)
                    .overlay(
                        Image(systemName: "figure.stand")
                            .font(.system(size: 50, weight: .thin))
                            .foregroundStyle(AppTheme.primaryAccent.opacity(0.3))
                    )
            }

            scanLineOverlay

            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.primaryAccent.opacity(0.6), AppTheme.primaryAccent.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 180, height: 180)

            ForEach(0..<4) { i in
                let angle = Double(i) * 90.0
                Circle()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: 6, height: 6)
                    .offset(y: -90)
                    .rotationEffect(.degrees(angle + ringRotation * 0.5))
            }
        }
        .shadow(color: AppTheme.primaryAccent.opacity(0.25), radius: 40)
    }

    private var scanLineOverlay: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.primaryAccent.opacity(0),
                            AppTheme.primaryAccent.opacity(0.7),
                            AppTheme.secondaryAccent.opacity(0.9),
                            AppTheme.primaryAccent.opacity(0.7),
                            AppTheme.primaryAccent.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 170, height: 2.5)
                .blur(radius: 0.5)
                .overlay(
                    Rectangle()
                        .fill(AppTheme.primaryAccent.opacity(0.2))
                        .frame(width: 170, height: 40)
                        .blur(radius: 15)
                )
                .offset(y: scanLineY)
        }
        .frame(width: 180, height: 180)
        .clipShape(Circle())
    }

    private func dotOpacity(index: Int) -> Double {
        let phase = Int(progress * 30) % 3
        return phase == index ? 1.0 : 0.3
    }

    private var progressSection: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * progress, 8), height: 8)
                        .animation(.easeInOut(duration: 0.4), value: progress)

                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 8)
                        .offset(x: max(geo.size.width * progress - 50, 0))
                        .blur(radius: 4)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 20)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 44, weight: .black, design: .default))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: Int(progress * 100))
        }
    }

    private func dataLabel(label: String, value: String, icon: String, index: Int) -> some View {
        let isLeft = index % 2 == 0
        let yOffset: CGFloat = CGFloat(index) * 50 - 80

        return HStack(spacing: 6) {
            if !isLeft { Spacer() }

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1)
                    Text(value)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent.opacity(0.8))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.06))
            .clipShape(.rect(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(AppTheme.primaryAccent.opacity(0.15), lineWidth: 0.5)
            )

            if isLeft { Spacer() }
        }
        .padding(.horizontal, isLeft ? 16 : 16)
        .offset(y: yOffset)
    }

    private func startScanLineAnimation() {
        scanLineY = -80
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            scanLineY = 80
        }
    }

    private func startRingRotation() {
        withAnimation(
            .linear(duration: 8)
            .repeatForever(autoreverses: false)
        ) {
            ringRotation = 360
        }
    }

    private func startDataPointReveal() {
        Task {
            for i in 0..<dataLabels.count {
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation(.spring(duration: 0.4)) {
                    showDataPoint = i
                }
            }
        }
    }

    private func startAnalysis() {
        Task {
            for index in 0..<steps.count - 1 {
                withAnimation(.snappy) { currentStep = index }
                let stepProgress = Double(index + 1) / Double(steps.count)
                withAnimation(.easeInOut(duration: 0.3)) { progress = stepProgress }
                try? await Task.sleep(for: .milliseconds(350))
            }
            withAnimation(.snappy) { currentStep = steps.count - 1 }
            withAnimation(.easeInOut(duration: 0.4)) { progress = 0.95 }
            animationDone = true
            if resultReady {
                await finishAnalysis()
            } else {
                try? await Task.sleep(for: .seconds(60))
                if !resultReady {
                    onComplete()
                }
            }
        }
    }

    private func finishAnalysis() async {
        withAnimation(.easeInOut(duration: 0.3)) { progress = 1.0 }
        try? await Task.sleep(for: .milliseconds(400))
        onComplete()
    }
}
