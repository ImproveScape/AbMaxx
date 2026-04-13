import SwiftUI
import AVFoundation

struct PostPaymentIntroView: View {
    let scanResult: ScanResult?
    let profile: UserProfile
    let onComplete: () -> Void

    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            switch currentPage {
            case 0:
                ScoreRevealScreen(scanResult: scanResult) {
                    withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                        currentPage = 1
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            case 1:
                RankRevealScreen(score: scanResult?.overallScore ?? 0) {
                    withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                        currentPage = 2
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            default:
                YourPlanScreen(
                    scanResult: scanResult,
                    profile: profile,
                    onComplete: onComplete
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(duration: 0.6, bounce: 0.15), value: currentPage)
        .premiumBackground()
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }
}

// MARK: - Screen 1: Score Reveal

private struct ScoreRevealScreen: View {
    let scanResult: ScanResult?
    let onContinue: () -> Void

    @State private var showHeader: Bool = false
    @State private var showRing: Bool = false
    @State private var ringProgress: Double = 0
    @State private var displayedScore: Int = 0
    @State private var scoreRevealed: Bool = false
    @State private var photoScale: Double = 0.0
    @State private var showChips: Bool = false
    @State private var revealedZones: Int = 0
    @State private var showButton: Bool = false
    @State private var glowPulse: Bool = false
    @State private var outerRingRotation: Double = 0

    private var score: Int { scanResult?.overallScore ?? 0 }
    private var tier: RankTier { RankTier.tier(for: score) }
    private var scanPhoto: UIImage? { scanResult?.loadImage() }

    private var zones: [(String, Int, String, Bool)] {
        guard let s = scanResult else { return [] }
        let regions = [
            ("Upper Abs", s.upperAbsScore, "chevron.up.2"),
            ("Lower Abs", s.lowerAbsScore, "chevron.down.2"),
            ("Obliques", s.obliquesScore, "arrow.left.and.right"),
            ("Deep Core", s.deepCoreScore, "circle.grid.cross.fill"),
            ("Symmetry", s.symmetry, "arrow.left.arrow.right"),
            ("V Taper", s.frame, "chart.bar.fill")
        ]
        let sorted = regions.sorted { $0.1 < $1.1 }
        let weakNames = Set(sorted.prefix(2).map(\.0))
        return regions.map { (name, score, icon) in
            (name, score, icon, weakNames.contains(name))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Text("YOUR SCORE")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(4)
                    .opacity(showHeader ? 1 : 0)
                    .offset(y: showHeader ? 0 : -12)

                Spacer().frame(height: 32)

                scoreRingSection
                    .padding(.bottom, 24)

                if showChips {
                    chipRow
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .padding(.bottom, 32)
                }

                if revealedZones > 0 {
                    zoneBreakdown
                        .padding(.horizontal, 4)
                }

                if showButton {
                    continueButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.top, 32)
                }

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear { runReveal() }
    }

    private var scoreRingSection: some View {
        let ringSize: CGFloat = 220
        let photoSize: CGFloat = ringSize - 20

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tier.color1.opacity(glowPulse ? 0.18 : 0.06), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 180
                        )
                    )
                    .frame(width: ringSize + 80, height: ringSize + 80)

                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 8)
                    .frame(width: ringSize, height: ringSize)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        AngularGradient(
                            colors: [tier.color1, tier.color2, tier.color1.opacity(0.6)],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [tier.color1.opacity(0.15), .clear, tier.color1.opacity(0.08), .clear],
                            center: .center
                        ),
                        lineWidth: 1
                    )
                    .frame(width: ringSize + 24, height: ringSize + 24)
                    .rotationEffect(.degrees(outerRingRotation))

                if let photo = scanPhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: photoSize, height: photoSize)
                        .clipShape(Circle())
                        .scaleEffect(photoScale)
                        .allowsHitTesting(false)
                } else {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tier.color1.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 90
                            )
                        )
                        .frame(width: photoSize, height: photoSize)
                        .overlay(
                            Image(systemName: "figure.core.training")
                                .font(.system(size: 48, weight: .ultraLight))
                                .foregroundStyle(AppTheme.muted.opacity(0.4))
                        )
                        .scaleEffect(photoScale)
                }
            }
            .opacity(showRing ? 1 : 0)
            .scaleEffect(showRing ? 1 : 0.5)

            VStack(spacing: 6) {
                Text("\(displayedScore)")
                    .font(.system(size: 72, weight: .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .opacity(scoreRevealed ? 1 : 0)
                    .scaleEffect(scoreRevealed ? 1 : 0.3)

                Text("OUT OF 100")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(3)
                    .opacity(scoreRevealed ? 1 : 0)
            }
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            if let structure = scanResult?.absStructure {
                chipPill(icon: "square.grid.2x2.fill", text: structure.rawValue)
            }
            if let bf = scanResult?.estimatedBodyFat {
                chipPill(icon: "percent", text: "\(String(format: "%.0f", bf))% BF")
            }
            chipPill(icon: "trophy.fill", text: ScanResult.ratingLabel(for: score))
        }
    }

    private func chipPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
    }

    private var zoneBreakdown: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ZONE BREAKDOWN")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(2)
                Spacer()
            }
            .padding(.bottom, 16)

            VStack(spacing: 12) {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, zone in
                    let isRevealed = index < revealedZones
                    zoneRow(
                        name: zone.0,
                        score: zone.1,
                        icon: zone.2,
                        isWeak: zone.3,
                        isRevealed: isRevealed
                    )
                    .opacity(isRevealed ? 1 : 0.12)
                    .offset(x: isRevealed ? 0 : -16)
                }
            }
        }
    }

    private func zoneRow(name: String, score: Int, icon: String, isWeak: Bool, isRevealed: Bool) -> some View {
        let barColor: Color = isWeak ? AppTheme.destructive : zoneColor(for: score)

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isWeak && isRevealed ? AppTheme.destructive.opacity(0.1) : AppTheme.primaryAccent.opacity(0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isWeak && isRevealed ? AppTheme.destructive : AppTheme.primaryAccent)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(0.5)

                    if isWeak && isRevealed {
                        Text("WEAK")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(AppTheme.destructive)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.destructive.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text(isRevealed ? "\(score)" : "--")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(isRevealed ? .white : AppTheme.muted)
                        .contentTransition(.numericText())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 4)
                        Capsule()
                            .fill(barColor)
                            .frame(width: isRevealed ? geo.size.width * Double(score) / 100.0 : 0, height: 4)
                            .animation(.spring(duration: 0.7, bounce: 0.08), value: isRevealed)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }

    private func zoneColor(for score: Int) -> Color {
        if score >= 85 { return AppTheme.success }
        if score >= 75 { return AppTheme.yellow }
        if score >= 65 { return AppTheme.caution }
        return AppTheme.destructive
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("See Your Rank")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.primaryAccent)
                .clipShape(.capsule)
                .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 20, y: 8)
        }
    }

    private func runReveal() {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.5)) { showHeader = true }

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.7, bounce: 0.2)) { showRing = true }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.9, bounce: 0.25)) { photoScale = 1.0 }

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.4)) { scoreRevealed = true }

            let target = score
            if target > 0 {
                let stepMs = max(5, 800 / target)
                for i in 0...target {
                    try? await Task.sleep(for: .milliseconds(stepMs))
                    withAnimation(.snappy(duration: 0.05)) { displayedScore = i }
                }
            }

            withAnimation(.spring(duration: 1.6, bounce: 0.05)) {
                ringProgress = Double(target) / 100.0
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            AudioServicesPlaySystemSound(1025)

            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                outerRingRotation = 360
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.5, bounce: 0.15)) { showChips = true }

            try? await Task.sleep(for: .milliseconds(400))
            for i in 0..<zones.count {
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.spring(duration: 0.4, bounce: 0.12)) {
                    revealedZones = i + 1
                }
                let isWeak = zones[i].3
                if isWeak {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.5)) { showButton = true }
        }
    }
}

// MARK: - Screen 2: Rank Reveal

private struct RankRevealScreen: View {
    let score: Int
    let onContinue: () -> Void

    @State private var showLabel: Bool = false
    @State private var badgeScale: Double = 0
    @State private var badgeOpacity: Double = 0
    @State private var nameOffset: CGFloat = 40
    @State private var nameOpacity: Double = 0
    @State private var showPercentile: Bool = false
    @State private var showDescription: Bool = false
    @State private var showNextTier: Bool = false
    @State private var showButton: Bool = false
    @State private var glowPulse: Bool = false
    @State private var ringPulse1: Double = 0.6
    @State private var ringPulse2: Double = 0.5
    @State private var ringPulse3: Double = 0.4
    @State private var ringOpacity1: Double = 0
    @State private var ringOpacity2: Double = 0
    @State private var ringOpacity3: Double = 0
    @State private var flashOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    private var tierIndex: Int { RankTier.currentTierIndex(for: score) }
    private var tier: RankTier { RankTier.allTiers[tierIndex] }
    private var nextTier: RankTier? {
        tierIndex + 1 < RankTier.allTiers.count ? RankTier.allTiers[tierIndex + 1] : nil
    }
    private var pointsToNext: Int {
        guard let next = nextTier else { return 0 }
        return max(next.minScore - score, 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("YOUR RANK")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AppTheme.primaryAccent)
                .tracking(4)
                .opacity(showLabel ? 1 : 0)
                .offset(y: showLabel ? 0 : -10)
                .padding(.bottom, 36)

            ZStack {
                Circle()
                    .stroke(tier.color1.opacity(0.06), lineWidth: 1)
                    .frame(width: 320, height: 320)
                    .scaleEffect(ringPulse1)
                    .opacity(ringOpacity1)

                Circle()
                    .stroke(tier.color1.opacity(0.1), lineWidth: 1.5)
                    .frame(width: 260, height: 260)
                    .scaleEffect(ringPulse2)
                    .opacity(ringOpacity2)

                Circle()
                    .stroke(tier.color1.opacity(0.05), lineWidth: 1)
                    .frame(width: 200, height: 200)
                    .scaleEffect(ringPulse3)
                    .opacity(ringOpacity3)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tier.color1.opacity(glowPulse ? 0.2 : 0.08), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 170
                        )
                    )
                    .frame(width: 340, height: 340)

                RankBadgeImage(tier: tier, isUnlocked: true, size: 160)
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                    .shadow(color: tier.color1.opacity(0.5), radius: 50)
            }
            .padding(.bottom, 20)

            VStack(spacing: 10) {
                Text(tier.name)
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tier.color1, tier.color2, .white.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(nameOpacity)
                    .offset(y: nameOffset)

                if showPercentile {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(tier.color1)
                        Text("Top \(tier.topPercent) of all users")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.bottom, 16)

            if showDescription {
                Text(tier.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.ghost)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 44)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if showNextTier, let next = nextTier {
                nextTierCard(next: next)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.top, 24)
            }

            Spacer()

            if showButton {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.primaryAccent)
                        .clipShape(.capsule)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 20, y: 8)
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 28)
        }
        .overlay(
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
        .onAppear { runReveal() }
    }

    private func nextTierCard(next: RankTier) -> some View {
        HStack(spacing: 14) {
            RankBadgeImage(tier: next, isUnlocked: false, size: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text("NEXT: \(next.name.uppercased())")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(next.color1)
                    .tracking(1)
                Text("\(pointsToNext) points away")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(next.color1.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private func runReveal() {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.5)) { showLabel = true }

            try? await Task.sleep(for: .milliseconds(400))

            withAnimation(.easeOut(duration: 0.1)) { flashOpacity = 0.2 }
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation(.easeOut(duration: 0.35)) { flashOpacity = 0 }

            withAnimation(.spring(duration: 0.9, bounce: 0.3)) {
                badgeScale = 1.0
                badgeOpacity = 1.0
            }
            AudioServicesPlaySystemSound(1025)
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            withAnimation(.spring(duration: 1.0, bounce: 0.05)) {
                ringPulse1 = 1.0
                ringPulse2 = 1.0
                ringPulse3 = 1.0
                ringOpacity1 = 0.5
                ringOpacity2 = 0.4
                ringOpacity3 = 0.25
            }

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.7, bounce: 0.2)) {
                nameOffset = 0
                nameOpacity = 1
            }

            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                ringOpacity1 = 0.15
                ringOpacity2 = 0.1
                ringOpacity3 = 0.06
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.5)) { showPercentile = true }

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.5)) { showDescription = true }

            try? await Task.sleep(for: .milliseconds(300))
            if nextTier != nil {
                withAnimation(.spring(duration: 0.5)) { showNextTier = true }
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.4)) { showButton = true }
        }
    }
}

// MARK: - Screen 3: Your Plan

private struct YourPlanScreen: View {
    let scanResult: ScanResult?
    let profile: UserProfile
    let onComplete: () -> Void

    @State private var showTitle: Bool = false
    @State private var showSubtitle: Bool = false
    @State private var revealedFeatures: Int = 0
    @State private var showButton: Bool = false
    @State private var buttonPulse: Bool = false

    private var features: [(String, String, String, Color)] {
        [
            ("AI-Powered Scan Analysis", "Detailed breakdown of every ab region with AI precision", "viewfinder", AppTheme.primaryAccent),
            ("Personalized Workouts", "Custom exercises targeting your weak zones for faster growth", "figure.core.training", AppTheme.success),
            ("Smart Nutrition Tracking", "Hit your macros with barcode scanning and AI food logging", "fork.knife", AppTheme.caution),
            ("Progress Tracking", "Weekly scans to measure real changes in definition and symmetry", "chart.line.uptrend.xyaxis", AppTheme.purple),
            ("Rank Progression", "Climb the ladder from \(RankTier.tier(for: scanResult?.overallScore ?? 0).name) to the top", "trophy.fill", Color(red: 0.85, green: 0.75, blue: 0.45))
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            VStack(spacing: 10) {
                Text("YOU'RE ALL SET")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(4)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : -10)

                Text("Here's What\nYou Unlock")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 15)
            }
            .padding(.bottom, 40)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        let isRevealed = index < revealedFeatures
                        featureCard(
                            title: feature.0,
                            subtitle: feature.1,
                            icon: feature.2,
                            color: feature.3,
                            index: index
                        )
                        .opacity(isRevealed ? 1 : 0)
                        .offset(y: isRevealed ? 0 : 30)
                        .scaleEffect(isRevealed ? 1 : 0.95)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)

            Spacer()

            if showButton {
                Button(action: onComplete) {
                    HStack(spacing: 10) {
                        Text("Start My Journey")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.primaryAccent)
                    .clipShape(.capsule)
                    .shadow(color: AppTheme.primaryAccent.opacity(buttonPulse ? 0.5 : 0.25), radius: buttonPulse ? 30 : 15, y: 8)
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 28)
        }
        .onAppear { runReveal() }
    }

    private func featureCard(title: String, subtitle: String, icon: String, color: Color, index: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(color.opacity(0.1), lineWidth: 1)
        )
    }

    private func runReveal() {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.5)) { showTitle = true }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) { showSubtitle = true }

            try? await Task.sleep(for: .milliseconds(400))
            for i in 0..<features.count {
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.spring(duration: 0.5, bounce: 0.12)) {
                    revealedFeatures = i + 1
                }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.5)) { showButton = true }

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                buttonPulse = true
            }
        }
    }
}
