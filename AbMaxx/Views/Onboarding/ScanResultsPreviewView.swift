import SwiftUI

struct ScanResultsPreviewView: View {
    let scanResult: ScanResult
    let estimatedWeeks: Int
    let onContinue: () -> Void

    @State private var phase: Int = 0
    @State private var scoreAnimated: Bool = false
    @State private var displayScore: Int = 0
    @State private var subscoreDisplayValues: [String: Int] = [:]

    private var scanPhoto: UIImage? {
        scanResult.loadImage()
    }

    private var tierIndex: Int {
        RankTier.currentTierIndex(for: scanResult.overallScore)
    }

    private var tier: RankTier {
        RankTier.allTiers[tierIndex]
    }

    private var regionMetrics: [(name: String, score: Int, icon: String)] {
        [
            ("Upper Abs", scanResult.upperAbsScore, "star.fill"),
            ("Lower Abs", scanResult.lowerAbsScore, "chevron.down"),
            ("Obliques", scanResult.obliquesScore, "plus"),
            ("Deep Core", scanResult.deepCoreScore, "circle.grid.2x2.fill")
        ]
    }

    private var extraMetrics: [(name: String, score: Int, icon: String)] {
        [
            ("Symmetry", scanResult.symmetry, "arrow.left.arrow.right"),
            ("V Taper", scanResult.frame, "chart.bar.fill")
        ]
    }

    private var allMetrics: [(name: String, score: Int, icon: String)] {
        regionMetrics + extraMetrics
    }

    private var weakestMetricName: String {
        let allScores = allMetrics
        return allScores.min(by: { $0.score < $1.score })?.name ?? "Lower Abs"
    }

    private var weakZoneNames: Set<String> {
        let sorted = regionMetrics.sorted { $0.score < $1.score }
        return Set(sorted.prefix(2).map(\.name))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("SCAN COMPLETE")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.primaryAccent)
                            .tracking(3)
                            .opacity(phase >= 1 ? 1 : 0)
                            .animation(.easeIn(duration: 0.4), value: phase)

                        Text("Here's where\nyou stand.")
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(phase >= 1 ? 1 : 0)
                            .offset(y: phase >= 1 ? 0 : 15)
                            .animation(.spring(duration: 0.5).delay(0.2), value: phase)
                    }
                    .padding(.top, 16)

                    scoreHeroSection
                        .blur(radius: phase >= 2 ? 40 : 0)
                        .opacity(phase >= 2 ? 1 : 0)
                        .scaleEffect(phase >= 2 ? 1 : 0.85)
                        .animation(.spring(duration: 0.6), value: phase)

                    subscoreGrid
                        .padding(.horizontal, 20)
                        .opacity(phase >= 3 ? 1 : 0)
                        .animation(.easeIn(duration: 0.4), value: phase)

                    Button(action: onContinue) {
                        Text("Unlock Your Full Results")
                            .font(.headline.weight(.heavy))
                    }
                    .buttonStyle(GlowButtonStyle())
                    .padding(.horizontal, 24)
                    .opacity(phase >= 4 ? 1 : 0)
                    .offset(y: phase >= 4 ? 0 : 15)
                    .animation(.spring(duration: 0.5), value: phase)

                    Spacer().frame(height: 32)
                }
            }
            .scrollIndicators(.hidden)
            .sensoryFeedback(.impact(weight: .heavy), trigger: phase == 2 ? true : false)
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation { phase = 2 }
                animateScore()
                animateSubscores()
                withAnimation(.spring(duration: 1.5)) { scoreAnimated = true }
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation { phase = 3 }
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation { phase = 4 }
            }
        }
    }

    // MARK: - Score Hero (matches breakdown page)

    private var scoreHeroSection: some View {
        let score = scanResult.overallScore
        let ringProgress = scoreAnimated ? Double(score) / 100.0 : 0
        let circleSize: CGFloat = 160
        let photoSize: CGFloat = circleSize - 12

        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 6)
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [tier.color1, tier.color2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1.2, bounce: 0.1), value: ringProgress)

                if let photo = scanPhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: photoSize, height: photoSize)
                        .clipShape(Circle())
                        .allowsHitTesting(false)
                } else {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tier.color1.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 90
                            )
                        )
                        .frame(width: photoSize, height: photoSize)
                    Image(systemName: "figure.core.training")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(AppTheme.muted.opacity(0.4))
                }
            }
            .shadow(color: tier.color1.opacity(0.15), radius: 24)

            VStack(spacing: 4) {
                Text("\(displayScore)")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.25), value: displayScore)

                Text("OVERALL SCORE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(AppTheme.muted)
            }

            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    Text(scanResult.absStructure.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("ABS")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.muted)
                }
                .frame(maxWidth: .infinity)

                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 22)

                VStack(spacing: 3) {
                    Text("\(String(format: "%.0f", scanResult.estimatedBodyFat))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("BODY FAT")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.muted)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Subscore Grid (matches breakdown page)

    private var subscoreGrid: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(regionMetrics, id: \.name) { metric in
                    let isWeak = weakZoneNames.contains(metric.name)
                    let isWeakest = metric.name == weakestMetricName
                    subscoreCard(metric: metric, isWeak: isWeak, isBlurred: !isWeakest)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(extraMetrics, id: \.name) { metric in
                    let isWeakest = metric.name == weakestMetricName
                    subscoreCard(metric: metric, isWeak: false, isBlurred: !isWeakest)
                }
            }
        }
    }

    private func subscoreCard(metric: (name: String, score: Int, icon: String), isWeak: Bool, isBlurred: Bool) -> some View {
        let isWeakest = metric.name == weakestMetricName
        let barColor: Color = isWeakest ? AppTheme.destructive : (isBlurred ? Color.white.opacity(0.12) : subscoreBarColor(for: metric.score))
        let animatedValue = subscoreDisplayValues[metric.name] ?? 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isWeakest ? AppTheme.destructive : (isBlurred ? AppTheme.muted : barColor))
                Text(metric.name.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(isBlurred ? AppTheme.secondaryText : .white)
                    .tracking(0.5)
                Spacer()
                if isWeakest {
                    Text("WEAK")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(0.5)
                        .foregroundStyle(AppTheme.destructive)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(animatedValue)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: animatedValue)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 4)
                    Capsule()
                        .fill(barColor)
                        .frame(width: phase >= 3 ? geo.size.width * Double(metric.score) / 100.0 : 0, height: 4)
                        .animation(.spring(duration: 0.8), value: phase)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isWeakest ? AppTheme.destructive.opacity(0.3) : AppTheme.primaryAccent.opacity(0.15),
                    lineWidth: 1
                )
        )
        .blur(radius: isBlurred ? 40 : 0)
    }

    private func subscoreBarColor(for score: Int) -> Color {
        if score >= 75 { return AppTheme.success }
        if score >= 60 { return AppTheme.primaryAccent }
        return AppTheme.warning
    }

    // MARK: - Animations

    private func animateScore() {
        let target = scanResult.overallScore
        Task {
            for i in 0...target {
                displayScore = i
                try? await Task.sleep(for: .milliseconds(15))
            }
        }
    }

    private func animateSubscores() {
        for metric in allMetrics {
            subscoreDisplayValues[metric.name] = 0
        }
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            let maxScore = allMetrics.map(\.score).max() ?? 100
            for i in 0...maxScore {
                for metric in allMetrics {
                    if i <= metric.score {
                        subscoreDisplayValues[metric.name] = i
                    }
                }
                try? await Task.sleep(for: .milliseconds(12))
            }
        }
    }
}
