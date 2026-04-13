import SwiftUI

struct ScanResultsPreviewView: View {
    let scanResult: ScanResult
    let estimatedWeeks: Int
    let onContinue: () -> Void

    @State private var phase: Int = 0
    @State private var displayScore: Int = 0
    @State private var displaySubscores: [String: Int] = [:]
    @State private var ringProgress: Double = 0

    private var score: Int { scanResult.overallScore }

    private var currentTierIndex: Int {
        RankTier.currentTierIndex(for: score)
    }

    private var currentTier: RankTier {
        RankTier.allTiers[currentTierIndex]
    }

    private var regionMetrics: [(String, Int, String)] {
        [
            ("Upper Abs", scanResult.upperAbsScore, "star.fill"),
            ("Lower Abs", scanResult.lowerAbsScore, "chevron.down"),
            ("Obliques", scanResult.obliquesScore, "plus"),
            ("Deep Core", scanResult.deepCoreScore, "circle.grid.2x2.fill")
        ]
    }

    private var extraMetrics: [(String, Int, String)] {
        [
            ("Symmetry", scanResult.symmetry, "arrow.left.arrow.right"),
            ("V Taper", scanResult.frame, "chart.bar.fill")
        ]
    }

    private var allMetrics: [(String, Int, String)] {
        regionMetrics + extraMetrics
    }

    private var weakestMetricName: String {
        allMetrics.min(by: { $0.1 < $1.1 })?.0 ?? "Lower Abs"
    }

    private var weakZoneNames: Set<String> {
        let sorted = allMetrics.sorted { $0.1 < $1.1 }
        return Set(sorted.prefix(2).map(\.0))
    }

    private func isWeakest(_ name: String) -> Bool {
        name == weakestMetricName
    }

    private func subscoreBarColor(for score: Int, isWeak: Bool) -> Color {
        if score >= 85 { return AppTheme.success }
        if score >= 75 { return AppTheme.yellow }
        if score >= 65 { return AppTheme.caution }
        return AppTheme.destructive
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        headerText
                            .padding(.top, 12)

                        scoreHeroSection
                            .padding(.top, 16)

                        bodyFatStructureRow
                            .padding(.top, 8)
                            .padding(.horizontal, 20)

                        subscoreGridSection
                            .padding(.top, 16)
                            .padding(.horizontal, 20)

                        Spacer().frame(height: 120)
                    }
                }
                .scrollIndicators(.hidden)

                floatingButton
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: phase == 2)
        .onAppear { runSequence() }
    }

    // MARK: - Background

    private var backgroundGlow: some View {
        ZStack {
            Circle()
                .fill(currentTier.color1.opacity(0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -40, y: -100)
            Circle()
                .fill(AppTheme.destructive.opacity(0.03))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 100, y: 300)
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerText: some View {
        VStack(spacing: 8) {
            Text("SCAN COMPLETE")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AppTheme.primaryAccent)
                .tracking(3)

            Text("Here's Where\nYou Stand")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .opacity(phase >= 1 ? 1 : 0)
        .offset(y: phase >= 1 ? 0 : 15)
        .animation(.spring(duration: 0.5), value: phase)
    }

    // MARK: - Score Hero (matches BreakdownTabView exactly)

    private var scoreHeroSection: some View {
        let circleSize: CGFloat = 220
        let photoSize: CGFloat = circleSize - 14

        return VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(AppTheme.muted.opacity(0.3), lineWidth: 5)
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [currentTier.color1, currentTier.color2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))

                if let photo = scanResult.loadImage() {
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
                                colors: [currentTier.color1.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: photoSize, height: photoSize)
                    Image(systemName: "figure.core.training")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(AppTheme.muted.opacity(0.5))
                }
            }
            .shadow(color: currentTier.color1.opacity(0.2), radius: 30)

            VStack(spacing: 6) {
                ZStack {
                    Text("\(displayScore)")
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.75)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())
                        .shadow(color: currentTier.color1.opacity(0.3), radius: 20)
                        .blur(radius: phase >= 2 ? 10 : 0)
                        .opacity(phase >= 2 ? 0.7 : 1)
                }
                .padding(.top, 16)

                Text("OVERALL SCORE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .opacity(phase >= 2 ? 1 : 0)
        .scaleEffect(phase >= 2 ? 1 : 0.85)
        .animation(.spring(duration: 0.6), value: phase)
    }

    // MARK: - Body Fat + Structure (matches BreakdownTabView exactly)

    private var bodyFatStructureRow: some View {
        HStack(spacing: 0) {
            VStack(spacing: 3) {
                blurredValue(
                    text: scanResult.absStructure.rawValue,
                    fontSize: 20,
                    isRevealed: false
                )
                Text("ABS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)

            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 24)

            VStack(spacing: 3) {
                blurredValue(
                    text: String(format: "%.0f%%", scanResult.estimatedBodyFat),
                    fontSize: 20,
                    isRevealed: false
                )
                Text("BODY FAT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .opacity(phase >= 3 ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: phase)
    }

    // MARK: - Subscore Grid (matches BreakdownTabView exactly)

    private var subscoreGridSection: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(regionMetrics, id: \.0) { metric in
                    subscoreCard(metric: metric)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(extraMetrics, id: \.0) { metric in
                    subscoreCard(metric: metric)
                }
            }
        }
        .opacity(phase >= 4 ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: phase)
    }

    private func subscoreCard(metric: (String, Int, String)) -> some View {
        let weak = isWeakest(metric.0)
        let animatedValue = displaySubscores[metric.0] ?? 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: metric.2)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text(metric.0)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if weak {
                    Text("\(animatedValue)")
                        .font(.system(size: 30, weight: .black, design: .default))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                } else {
                    blurredValue(
                        text: "\(metric.1)",
                        fontSize: 30,
                        isRevealed: false
                    )
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.border)
                        .frame(height: 5)
                    Capsule()
                        .fill(weak ? subscoreBarColor(for: metric.1, isWeak: false) : Color.gray.opacity(0.35))
                        .frame(width: geo.size.width * Double(animatedValue) / 100.0, height: 5)
                }
            }
            .frame(height: 5)

            if weak {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("Holding you back")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(AppTheme.destructive)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.primaryAccent.opacity(0.25), lineWidth: 1)
        )
    }



    // MARK: - Floating Button

    private var floatingButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.accentGradient)
                .clipShape(.capsule)
                .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 24, y: 6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.9), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .opacity(phase >= 5 ? 1 : 0)
        .offset(y: phase >= 5 ? 0 : 20)
        .animation(.spring(duration: 0.5), value: phase)
    }

    // MARK: - Blurred Value Helper

    private func blurredValue(text: String, fontSize: CGFloat, isRevealed: Bool) -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(.white)
            .blur(radius: isRevealed ? 0 : 10)
            .opacity(isRevealed ? 1 : 0.7)
    }

    // MARK: - Animations

    private func runSequence() {
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation { phase = 1 }
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation { phase = 2 }
            animateOverallScore()
            withAnimation(.spring(duration: 1.2, bounce: 0.1)) {
                ringProgress = Double(scanResult.overallScore) / 100.0
            }
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation { phase = 3 }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation { phase = 4 }
            animateSubscores()
            try? await Task.sleep(for: .milliseconds(800))
            withAnimation { phase = 5 }
        }
    }

    private func animateOverallScore() {
        let target = scanResult.overallScore
        Task {
            for i in 0...target {
                displayScore = i
                try? await Task.sleep(for: .milliseconds(12))
            }
        }
    }

    private func animateSubscores() {
        for metric in allMetrics {
            let name = metric.0
            let target = metric.1
            Task {
                for i in 0...target {
                    displaySubscores[name] = i
                    try? await Task.sleep(for: .milliseconds(10))
                }
            }
        }
    }
}
