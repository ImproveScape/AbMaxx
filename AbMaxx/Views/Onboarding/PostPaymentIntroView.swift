import SwiftUI
import AVFoundation

struct PostPaymentIntroView: View {
    let scanResult: ScanResult?
    let profile: UserProfile
    let onComplete: () -> Void

    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()
            StandardBackgroundOrbs()

            switch currentPage {
            case 0:
                ScoreRevealPage(scanResult: scanResult) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPage = 1
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case 1:
                RankLadderRevealPage(score: scanResult?.overallScore ?? 0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPage = 2
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case 2:
                AbBreakdownPage(scanResult: scanResult, profile: profile) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPage = 3
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case 3:
                CalorieRevealPage(profile: profile, scanResult: scanResult) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPage = 4
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            default:
                LeaderboardRevealPage(
                    score: scanResult?.overallScore ?? 0,
                    username: profile.displayName
                ) {
                    onComplete()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentPage)
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }
}

// MARK: - Screen 1: Score Reveal (Subscores FIRST, then Overall)

private struct ScoreRevealPage: View {
    let scanResult: ScanResult?
    let onContinue: () -> Void

    @State private var showLabel: Bool = false
    @State private var revealedSubscores: Int = 0
    @State private var subscoresDone: Bool = false
    @State private var showOverallSection: Bool = false
    @State private var showRing: Bool = false
    @State private var ringProgress: Double = 0
    @State private var displayedOverall: Int = 0
    @State private var overallRevealed: Bool = false
    @State private var photoScale: Double = 0.3
    @State private var showChips: Bool = false
    @State private var showButton: Bool = false
    @State private var glowPulse: Bool = false
    @State private var overallCountDone: Bool = false

    private var regionMetrics: [(String, Int, String)] {
        guard let s = scanResult else { return [] }
        return [
            ("Upper Abs", s.upperAbsScore, "chevron.up.2"),
            ("Lower Abs", s.lowerAbsScore, "chevron.down.2"),
            ("Obliques", s.obliquesScore, "arrow.left.and.right"),
            ("Deep Core", s.deepCoreScore, "circle.grid.cross.fill")
        ]
    }

    private var extraMetrics: [(String, Int, String)] {
        guard let s = scanResult else { return [] }
        return [
            ("Symmetry", s.symmetry, "arrow.left.arrow.right"),
            ("V Taper", s.frame, "chart.bar.fill")
        ]
    }

    private var allMetrics: [(String, Int, String)] {
        regionMetrics + extraMetrics
    }

    private var weakZoneNames: Set<String> {
        let sorted = regionMetrics.sorted { $0.1 < $1.1 }
        return Set(sorted.prefix(2).map(\.0))
    }

    private var scanPhoto: UIImage? {
        scanResult?.loadImage()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 24)

                Text("ANALYZING YOUR ABS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(4)
                    .opacity(showLabel ? 1 : 0)
                    .offset(y: showLabel ? 0 : -10)

                if revealedSubscores > 0 && !subscoresDone {
                    Text("Zone Scores")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if revealedSubscores > 0 {
                    zoneGrid
                        .padding(.horizontal, 4)
                }

                if showOverallSection {
                    overallRevealSection
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }

                if showChips {
                    chipSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if showButton {
                    continueButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.top, 4)
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .onAppear { startRevealSequence() }
    }

    private var overallRevealSection: some View {
        let score = scanResult?.overallScore ?? 0
        let tierIndex = RankTier.currentTierIndex(for: score)
        let tier = RankTier.allTiers[tierIndex]
        let circleSize: CGFloat = 190
        let photoSize: CGFloat = circleSize - 14

        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tier.color1.opacity(0.06))
                    .frame(width: circleSize + 40, height: circleSize + 40)
                    .scaleEffect(glowPulse ? 1.08 : 1.0)
                    .blur(radius: 20)

                Circle()
                    .stroke(AppTheme.muted.opacity(0.15), lineWidth: 8)
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [tier.color1, tier.color2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))

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
                                colors: [tier.color1.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: photoSize, height: photoSize)
                    Image(systemName: "figure.core.training")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(AppTheme.muted.opacity(0.5))
                        .scaleEffect(photoScale)
                }
            }
            .opacity(showRing ? 1 : 0)
            .scaleEffect(showRing ? 1 : 0.6)
            .shadow(color: tier.color1.opacity(0.25), radius: 40)

            VStack(spacing: 2) {
                Text("OVERALL SCORE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(2)
                    .opacity(overallRevealed ? 1 : 0)

                Text("\(displayedOverall)")
                    .font(.system(size: 56, weight: .black, design: .default))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .opacity(overallRevealed ? 1 : 0)
                    .scaleEffect(overallRevealed ? 1 : 0.5)
            }
        }
    }

    private var chipSection: some View {
        HStack(spacing: 8) {
            if let absStructure = scanResult?.absStructure {
                Text(absStructure.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    )
            }
            if let bf = scanResult?.estimatedBodyFat {
                Text("\(String(format: "%.0f", bf))% BF")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    )
            }
        }
    }

    private var zoneGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(Array(allMetrics.enumerated()), id: \.offset) { index, metric in
                let isRevealed = index < revealedSubscores
                let isWeak = weakZoneNames.contains(metric.0)
                let barColor: Color = isWeak ? AppTheme.destructive : zoneBarColor(for: metric.1)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: metric.2)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isWeak && isRevealed ? AppTheme.destructive : AppTheme.primaryAccent)
                        Text(metric.0)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                        if isWeak && isRevealed {
                            Text("WEAK")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AppTheme.destructive))
                        }
                    }

                    Text(isRevealed ? "\(metric.1)" : "--")
                        .font(.system(size: 28, weight: .black, design: .default))
                        .foregroundStyle(isRevealed ? .white : AppTheme.muted)
                        .contentTransition(.numericText())

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 4)
                            Capsule()
                                .fill(barColor)
                                .frame(width: isRevealed ? geo.size.width * Double(metric.1) / 100.0 : 0, height: 4)
                                .animation(.spring(duration: 0.7, bounce: 0.1), value: isRevealed)
                        }
                    }
                    .frame(height: 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isWeak && isRevealed ? AppTheme.destructive.opacity(0.25) : Color.white.opacity(0.04),
                            lineWidth: 1
                        )
                )
                .opacity(isRevealed ? 1 : 0.2)
                .scaleEffect(isRevealed ? 1 : 0.92)
            }
        }
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.primaryAccent)
                .clipShape(.capsule)
                .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 6)
        }
    }

    private func zoneBarColor(for score: Int) -> Color {
        if score >= 75 { return AppTheme.success }
        if score >= 60 { return AppTheme.primaryAccent }
        return AppTheme.warning
    }

    private func startRevealSequence() {
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.5)) { showLabel = true }

            let totalMetrics = allMetrics.count
            for i in 0..<totalMetrics {
                try? await Task.sleep(for: .milliseconds(320))
                withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                    revealedSubscores = i + 1
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }

            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.spring(duration: 0.3)) { subscoresDone = true }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) { showOverallSection = true }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) { showRing = true }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.8, bounce: 0.2)) { photoScale = 1.0 }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.5, bounce: 0.15)) { overallRevealed = true }

            let targetScore = scanResult?.overallScore ?? 0
            for i in 0...targetScore {
                try? await Task.sleep(for: .milliseconds(12))
                withAnimation(.snappy(duration: 0.08)) { displayedOverall = i }
            }

            withAnimation(.spring(duration: 1.4, bounce: 0.08)) {
                ringProgress = Double(targetScore) / 100.0
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            AudioServicesPlaySystemSound(1025)

            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.4)) { showChips = true }

            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.spring(duration: 0.4)) { showButton = true }
        }
    }
}

// MARK: - Screen 2: Rank Ladder Reveal

private struct RankLadderRevealPage: View {
    let score: Int
    let onContinue: () -> Void

    @State private var showTitle: Bool = false
    @State private var climbIndex: Int = -1
    @State private var showBadge: Bool = false
    @State private var badgeScale: Double = 0
    @State private var showButton: Bool = false
    @State private var glowPulse: Bool = false
    @State private var ringScale1: Double = 0.5
    @State private var ringScale2: Double = 0.5
    @State private var ringScale3: Double = 0.5
    @State private var ringOpacity1: Double = 0.8
    @State private var ringOpacity2: Double = 0.6
    @State private var ringOpacity3: Double = 0.4
    @State private var badgeNameOffset: CGFloat = 20
    @State private var showSubtext: Bool = false
    @State private var showTopPercent: Bool = false
    @State private var flashOpacity: Double = 0

    private var currentTierIndex: Int {
        RankTier.currentTierIndex(for: score)
    }

    private var tiersToShow: [RankTier] {
        let start = max(0, currentTierIndex - 3)
        let end = min(RankTier.allTiers.count - 1, currentTierIndex + 1)
        return Array(RankTier.allTiers[start...end])
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("YOUR RANK")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AppTheme.primaryAccent)
                .tracking(4)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : -10)
                .padding(.bottom, 28)

            if !showBadge {
                ladderView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if showBadge {
                badgeRevealView
                    .transition(.opacity)
            }

            Spacer()

            if showButton {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.primaryAccent)
                        .clipShape(.capsule)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 6)
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 24)
        }
        .overlay(
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
        .onAppear { startClimbSequence() }
    }

    private var ladderView: some View {
        VStack(spacing: 0) {
            ForEach(Array(tiersToShow.reversed().enumerated()), id: \.element.id) { index, tier in
                let reversedIndex = tiersToShow.count - 1 - (tiersToShow.firstIndex(where: { $0.id == tier.id }) ?? 0)
                let tierClimbed = climbIndex >= reversedIndex
                let isCurrent = tier.id == currentTierIndex && tierClimbed

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(tierClimbed ? tier.color1.opacity(0.15) : AppTheme.cardSurfaceElevated)
                            .frame(width: 48, height: 48)
                        RankBadgeImage(tier: tier, isUnlocked: tierClimbed, size: 38)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tier.name)
                            .font(.system(size: 16, weight: isCurrent ? .black : .semibold))
                            .foregroundStyle(
                                isCurrent
                                    ? AnyShapeStyle(LinearGradient(colors: [tier.color1, tier.color2], startPoint: .leading, endPoint: .trailing))
                                    : (tierClimbed ? AnyShapeStyle(.white) : AnyShapeStyle(AppTheme.muted))
                            )
                        Text("Score \(tier.minScore)+")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                    }

                    Spacer()

                    if isCurrent {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9, weight: .black))
                            Text("YOU")
                                .font(.system(size: 10, weight: .black))
                                .tracking(1.5)
                        }
                        .foregroundStyle(tier.color1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(tier.color1.opacity(0.15))
                        .clipShape(Capsule())
                    } else if tierClimbed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tier.color1.opacity(0.6))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.muted.opacity(0.4))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isCurrent ? AppTheme.cardSurfaceElevated : AppTheme.cardSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isCurrent
                                ? LinearGradient(colors: [tier.color1.opacity(0.6), tier.color2.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [AppTheme.border.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: isCurrent ? 2 : 1
                        )
                )
                .shadow(color: isCurrent ? tier.color1.opacity(0.25) : .clear, radius: 16)
                .scaleEffect(isCurrent ? 1.04 : 1.0)
                .animation(.spring(duration: 0.35, bounce: 0.2), value: climbIndex)

                if index < tiersToShow.count - 1 {
                    HStack {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(tierClimbed ? tier.color1.opacity(0.4) : AppTheme.border.opacity(0.2))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.leading, 36)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 20)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var badgeRevealView: some View {
        let tier = RankTier.allTiers[currentTierIndex]

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(tier.color1.opacity(0.15), lineWidth: 2)
                    .frame(width: 280, height: 280)
                    .scaleEffect(ringScale1)
                    .opacity(ringOpacity1)

                Circle()
                    .stroke(tier.color1.opacity(0.1), lineWidth: 1.5)
                    .frame(width: 240, height: 240)
                    .scaleEffect(ringScale2)
                    .opacity(ringOpacity2)

                Circle()
                    .stroke(tier.color1.opacity(0.08), lineWidth: 1)
                    .frame(width: 200, height: 200)
                    .scaleEffect(ringScale3)
                    .opacity(ringOpacity3)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tier.color1.opacity(glowPulse ? 0.3 : 0.15), tier.color1.opacity(0.02), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)

                RankBadgeImage(tier: tier, isUnlocked: true, size: 140)
                    .scaleEffect(badgeScale)
                    .shadow(color: tier.color1.opacity(0.5), radius: 30)
            }

            Text(tier.name)
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [tier.color1, tier.color2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(badgeScale)
                .offset(y: badgeNameOffset)

            if showTopPercent {
                Text("Top \(tier.topPercent) of all users")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if showSubtext {
                Text(tier.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func startClimbSequence() {
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.5)) { showTitle = true }

            try? await Task.sleep(for: .milliseconds(400))

            for i in 0..<tiersToShow.count {
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                    climbIndex = i
                }
                if i == tiersToShow.count - 1 {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            try? await Task.sleep(for: .milliseconds(600))

            withAnimation(.easeOut(duration: 0.15)) { flashOpacity = 0.3 }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }

            withAnimation(.easeInOut(duration: 0.4)) { showBadge = true }

            try? await Task.sleep(for: .milliseconds(200))

            withAnimation(.spring(duration: 0.7, bounce: 0.3)) {
                badgeScale = 1.0
                badgeNameOffset = 0
            }

            withAnimation(.spring(duration: 1.0, bounce: 0.1)) {
                ringScale1 = 1.0
                ringScale2 = 1.0
                ringScale3 = 1.0
            }

            AudioServicesPlaySystemSound(1025)
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                ringOpacity1 = 0.3
                ringOpacity2 = 0.2
                ringOpacity3 = 0.15
            }

            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.spring(duration: 0.4)) { showTopPercent = true }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.4)) { showSubtext = true }

            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.spring(duration: 0.4)) { showButton = true }
        }
    }
}

// MARK: - Screen 3: Ab Breakdown (Personalized Targeting Plan)

private struct AbBreakdownPage: View {
    let scanResult: ScanResult?
    let profile: UserProfile
    let onContinue: () -> Void

    @State private var showHeader: Bool = false
    @State private var revealedZones: Int = 0
    @State private var showPlan: Bool = false
    @State private var showButton: Bool = false
    @State private var pulseWeak: Bool = false
    @State private var generatedPlanText: String = ""
    @State private var isGenerating: Bool = false

    private var sortedZones: [(name: String, score: Int, icon: String, status: ZoneStatus)] {
        guard let s = scanResult else { return [] }
        let zones: [(String, Int, String)] = [
            ("Upper Abs", s.upperAbsScore, "chevron.up.2"),
            ("Lower Abs", s.lowerAbsScore, "chevron.down.2"),
            ("Obliques", s.obliquesScore, "arrow.left.and.right"),
            ("Deep Core", s.deepCoreScore, "circle.grid.cross.fill"),
            ("Symmetry", s.symmetry, "arrow.left.arrow.right"),
            ("V Taper", s.frame, "chart.bar.fill")
        ]
        let sorted = zones.sorted { $0.1 < $1.1 }
        return sorted.map { zone in
            let status: ZoneStatus
            if zone.1 < 55 { status = .critical }
            else if zone.1 < 68 { status = .needsWork }
            else { status = .strong }
            return (zone.0, zone.1, zone.2, status)
        }
    }

    private var weakestZone: String {
        sortedZones.first?.name ?? "Lower Abs"
    }

    private var secondWeakest: String {
        sortedZones.count > 1 ? sortedZones[1].name : "Obliques"
    }

    private var strongestZone: String {
        sortedZones.last?.name ?? "Upper Abs"
    }

    private var personalizedPlan: String {
        if !generatedPlanText.isEmpty { return generatedPlanText }
        return buildFallbackPlan()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)

                VStack(spacing: 10) {
                    Text("YOUR AB BLUEPRINT")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .tracking(4)

                    Text("Here's What We're\nTargeting First")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : 15)
                .padding(.bottom, 28)

                VStack(spacing: 8) {
                    ForEach(Array(sortedZones.enumerated()), id: \.offset) { index, zone in
                        let isRevealed = index < revealedZones

                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(zone.status.color.opacity(0.12))
                                    .frame(width: 44, height: 44)

                                Image(systemName: zone.icon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(zone.status.color)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(zone.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text(zone.status.label)
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(zone.status.color))
                                }

                                Text(zoneAdvice(for: zone.name, score: zone.score))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Text("\(zone.score)")
                                .font(.system(size: 22, weight: .black, design: .default))
                                .foregroundStyle(zone.status.color)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    zone.status == .critical && isRevealed
                                        ? zone.status.color.opacity(pulseWeak ? 0.4 : 0.15)
                                        : Color.white.opacity(0.04),
                                    lineWidth: zone.status == .critical ? 1.5 : 1
                                )
                        )
                        .opacity(isRevealed ? 1 : 0)
                        .offset(x: isRevealed ? 0 : -30)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

                if showPlan {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.primaryAccent)
                            Text("YOUR GAME PLAN")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(AppTheme.primaryAccent)
                                .tracking(2)
                        }

                        TypewriterText(
                            personalizedPlan,
                            font: .system(size: 14, weight: .medium),
                            color: .white.opacity(0.85),
                            speed: 0.025
                        )
                        .lineSpacing(4)
                    }
                    .padding(18)
                    .background(AppTheme.cardSurface)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppTheme.primaryAccent.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if showButton {
                    Button(action: onContinue) {
                        Text("Let's Build This")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.primaryAccent)
                            .clipShape(.capsule)
                            .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear { startBreakdownSequence() }
    }

    private func zoneAdvice(for zone: String, score: Int) -> String {
        if score >= 75 {
            switch zone {
            case "Upper Abs": return "Strong separation visible — maintain with progressive overload"
            case "Lower Abs": return "Solid lower definition — keep the deficit to reveal more"
            case "Obliques": return "Clean oblique lines forming — great foundation"
            case "Deep Core": return "Core stability is strong — supports everything else"
            case "Symmetry": return "Balanced development — rare and impressive"
            case "V Taper": return "Frame ratio looks excellent — keep building"
            default: return "Looking solid here"
            }
        } else if score >= 60 {
            switch zone {
            case "Upper Abs": return "Separation starting — heavier weighted crunches will accelerate this"
            case "Lower Abs": return "Needs more reverse crunch work and strict pelvic tilt"
            case "Obliques": return "Developing — targeted woodchops and side planks needed"
            case "Deep Core": return "Stabilization weak — dead bugs and pallof presses are key"
            case "Symmetry": return "Slight imbalance — unilateral movements will fix this"
            case "V Taper": return "Needs shoulder width or waist tightening for better ratio"
            default: return "Room for improvement"
            }
        } else {
            switch zone {
            case "Upper Abs": return "Priority target — no visible separation yet, heavy focus needed"
            case "Lower Abs": return "Critical weak point — reverse crunches + hanging leg raises daily"
            case "Obliques": return "Lacking definition — oblique-specific training 3x per week minimum"
            case "Deep Core": return "Foundation weakness — vacuum holds and TVA activation needed first"
            case "Symmetry": return "Noticeable imbalance — single-arm/leg work every session"
            case "V Taper": return "Frame needs work — lat development and waist control are priorities"
            default: return "Needs serious attention"
            }
        }
    }

    private func buildFallbackPlan() -> String {
        let name = profile.displayName
        let bf = String(format: "%.0f", scanResult?.estimatedBodyFat ?? 15)
        return "\(name), your \(weakestZone.lowercased()) scored the lowest and that's exactly where we're starting. At \(bf)% body fat, dropping even 2% will make your \(strongestZone.lowercased()) pop dramatically — but your \(weakestZone.lowercased()) and \(secondWeakest.lowercased()) need targeted volume to catch up. Your program is built around hitting those weak zones 3x per week with progressive overload while keeping your strong zones maintained. This is how we close the gap fast."
    }

    private func generateAIPlan() async {
        guard let scan = scanResult else { return }
        isGenerating = true
        let bf = String(format: "%.1f", scan.estimatedBodyFat)
        let systemPrompt = """
        You are an elite ab coach giving a personalized 3-4 sentence game plan to \(profile.displayName). \
        Their scores: Upper Abs \(scan.upperAbsScore), Lower Abs \(scan.lowerAbsScore), \
        Obliques \(scan.obliquesScore), Deep Core \(scan.deepCoreScore), \
        V-Taper \(scan.frame), Symmetry \(scan.symmetry). Overall \(scan.overallScore). \
        Body fat: \(bf)%. Structure: \(scan.absStructure.rawValue). \
        Address them by name. Tell them exactly which zones we're targeting first and why. \
        Be specific about what exercises will fix their weak points. \
        End with one motivating line about the transformation timeline. \
        No fluff, no generic advice. Talk like their personal trainer reading their scan results.
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Give me my personalized ab plan."]
        ]

        do {
            let text = try await AnthropicService.shared.chat(
                systemPrompt: systemPrompt,
                messages: [["role": "user", "content": "Give me my personalized ab plan."]],
                model: "claude-sonnet-4-20250514",
                maxTokens: 512,
                temperature: 0.7
            )

            if !text.isEmpty {
                generatedPlanText = text
            }
        } catch {
            // fallback plan is already used
        }

        isGenerating = false
    }

    private func startBreakdownSequence() {
        Task {
            async let _ = generateAIPlan()

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.6)) { showHeader = true }

            try? await Task.sleep(for: .milliseconds(500))

            for i in 0..<sortedZones.count {
                try? await Task.sleep(for: .milliseconds(260))
                withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                    revealedZones = i + 1
                }
                let zone = sortedZones[i]
                if zone.status == .critical {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseWeak = true
            }

            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.spring(duration: 0.5)) { showPlan = true }

            try? await Task.sleep(for: .milliseconds(800))
            withAnimation(.spring(duration: 0.4)) { showButton = true }
        }
    }
}

private enum ZoneStatus {
    case critical, needsWork, strong

    var label: String {
        switch self {
        case .critical: return "PRIORITY"
        case .needsWork: return "TARGET"
        case .strong: return "STRONG"
        }
    }

    var color: Color {
        switch self {
        case .critical: return AppTheme.destructive
        case .needsWork: return AppTheme.warning
        case .strong: return AppTheme.success
        }
    }
}

// MARK: - Screen 4: Calorie Reveal

private struct CalorieRevealPage: View {
    let profile: UserProfile
    let scanResult: ScanResult?
    let onContinue: () -> Void

    @State private var showHeader: Bool = false
    @State private var displayedCalories: Int = 0
    @State private var showCalorieRing: Bool = false
    @State private var showMacros: Bool = false
    @State private var showStats: Bool = false
    @State private var showButton: Bool = false
    @State private var ringProgress: Double = 0
    @State private var glowPulse: Bool = false

    private var bodyFat: Double {
        scanResult?.estimatedBodyFat ?? 15.0
    }

    private var deficit: Int {
        profile.scanDeficit ?? 400
    }

    private var calorieGoal: Int {
        profile.calculatedCalorieGoal
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                VStack(spacing: 10) {
                    Text("YOUR NUTRITION PLAN")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .tracking(4)

                    Text("Based on your \(String(format: "%.0f", bodyFat))% body fat")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Text("we placed you on a **\(deficit) calorie deficit**\nto reach your goals the fastest")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : 15)
                .padding(.bottom, 36)

                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(glowPulse ? 0.08 : 0.03))
                        .frame(width: 220, height: 220)
                        .blur(radius: 30)

                    Circle()
                        .stroke(AppTheme.border, lineWidth: 10)
                        .frame(width: 170, height: 170)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 170, height: 170)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(displayedCalories)")
                            .font(.system(size: 44, weight: .black, design: .default))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        Text("KCAL / DAY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.muted)
                            .tracking(1)
                    }
                }
                .opacity(showCalorieRing ? 1 : 0)
                .scaleEffect(showCalorieRing ? 1 : 0.7)
                .shadow(color: AppTheme.primaryAccent.opacity(0.2), radius: 30)
                .padding(.bottom, 32)

                if showMacros {
                    HStack(spacing: 10) {
                        macroChip(label: "Protein", value: "\(Int(profile.calculatedProteinGoal))g", color: Color(red: 0.95, green: 0.35, blue: 0.4), icon: "fish.fill")
                        macroChip(label: "Carbs", value: "\(Int(profile.calculatedCarbsGoal))g", color: AppTheme.orange, icon: "leaf.fill")
                        macroChip(label: "Fat", value: "\(Int(profile.calculatedFatGoal))g", color: AppTheme.primaryAccent, icon: "drop.fill")
                    }
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if showStats {
                    HStack(spacing: 12) {
                        deficitStat(value: "\(deficit)", label: "Deficit", icon: "flame.fill", color: AppTheme.orange)
                        deficitStat(value: "\(Int(profile.tdee))", label: "TDEE", icon: "bolt.fill", color: AppTheme.success)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if showButton {
                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.primaryAccent)
                            .clipShape(.capsule)
                            .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear { startCalorieSequence() }
    }

    private func macroChip(label: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 16, weight: .black, design: .default))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    private func deficitStat(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .black, design: .default))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    private func startCalorieSequence() {
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.6)) { showHeader = true }

            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.spring(duration: 0.5, bounce: 0.15)) { showCalorieRing = true }

            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { glowPulse = true }

            try? await Task.sleep(for: .milliseconds(300))

            let target = calorieGoal
            let steps = 45
            for i in 0...steps {
                let value = Int(Double(target) * Double(i) / Double(steps))
                try? await Task.sleep(for: .milliseconds(18))
                withAnimation(.snappy(duration: 0.05)) { displayedCalories = value }
            }
            displayedCalories = target

            withAnimation(.spring(duration: 1.2, bounce: 0.08)) { ringProgress = 1.0 }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.spring(duration: 0.5)) { showMacros = true }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.4)) { showStats = true }

            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.spring(duration: 0.4)) { showButton = true }
        }
    }
}

// MARK: - Screen 5: Leaderboard Reveal

private struct LeaderboardRevealPage: View {
    let score: Int
    let username: String
    let onContinue: () -> Void

    @State private var showTitle: Bool = false
    @State private var appeared: Bool = false
    @State private var scrolledToUser: Bool = false
    @State private var spotlightUser: Bool = false
    @State private var showButton: Bool = false
    @State private var spotlightScale: Double = 1.0
    @State private var spotlightGlow: Bool = false

    private let members = LeaderboardMember.celebrities

    private var allRows: [(rank: Int, name: String, rowScore: Int, isUser: Bool)] {
        var rows: [(rank: Int, name: String, rowScore: Int, isUser: Bool)] = []
        var userInserted = false
        for member in members {
            if !userInserted && score >= member.score {
                rows.append((rank: rows.count + 1, name: username, rowScore: score, isUser: true))
                userInserted = true
            }
            rows.append((rank: rows.count + 1, name: "AbMaxx Member", rowScore: member.score, isUser: false))
        }
        if !userInserted {
            rows.append((rank: rows.count + 1, name: username, rowScore: score, isUser: true))
        }
        return rows
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 36)

            VStack(spacing: 8) {
                Text("LEADERBOARD")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(4)

                Text("Where You Stand")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            .opacity(showTitle ? 1 : 0)
            .offset(y: showTitle ? 0 : -10)
            .padding(.bottom, 20)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(Array(allRows.enumerated()), id: \.offset) { index, row in
                            leaderboardRow(rank: row.rank, name: row.name, rowScore: row.rowScore, isUser: row.isUser)
                                .id(row.isUser ? "user" : "member_\(index)")
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(
                                    .spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.05),
                                    value: appeared
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        withAnimation(.spring(duration: 0.5)) { showTitle = true }

                        try? await Task.sleep(for: .milliseconds(400))
                        appeared = true

                        let rowCount = allRows.count
                        let scrollDelay = Double(rowCount) * 0.05 + 0.6
                        try? await Task.sleep(for: .milliseconds(Int(scrollDelay * 1000)))

                        withAnimation(.spring(duration: 0.8, bounce: 0.1)) {
                            proxy.scrollTo("user", anchor: .center)
                            scrolledToUser = true
                        }

                        try? await Task.sleep(for: .milliseconds(600))

                        withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                            spotlightUser = true
                            spotlightScale = 1.06
                        }
                        AudioServicesPlaySystemSound(1025)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)

                        try? await Task.sleep(for: .milliseconds(300))
                        withAnimation(.spring(duration: 0.3)) { spotlightScale = 1.0 }

                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            spotlightGlow = true
                        }

                        try? await Task.sleep(for: .milliseconds(500))
                        withAnimation(.spring(duration: 0.4)) { showButton = true }
                    }
                }
            }

            if showButton {
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Let's Go")
                            .font(.headline.weight(.bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.primaryAccent)
                    .clipShape(.capsule)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 6)
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 24)
        }
    }

    private func leaderboardRow(rank: Int, name: String, rowScore: Int, isUser: Bool) -> some View {
        let isSpotlit = isUser && spotlightUser
        let tierIndex = RankTier.currentTierIndex(for: rowScore)
        let tier = RankTier.allTiers[tierIndex]

        return HStack(spacing: 12) {
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(
                            rank == 1 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.15) :
                            rank == 2 ? Color(red: 0.75, green: 0.75, blue: 0.80).opacity(0.15) :
                            Color(red: 0.80, green: 0.50, blue: 0.20).opacity(0.15)
                        )
                        .frame(width: 32, height: 32)
                }
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundStyle(rankColor(rank: rank, isUser: isUser))
            }
            .frame(width: 36)

            Circle()
                .fill(
                    isUser
                        ? LinearGradient(colors: [AppTheme.primaryAccent.opacity(0.4), AppTheme.primaryAccent.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [AppTheme.cardSurfaceElevated, AppTheme.cardSurfaceElevated], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 38, height: 38)
                .overlay(
                    Group {
                        if isUser {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.muted.opacity(0.5))
                        }
                    }
                )
                .overlay(
                    Circle()
                        .strokeBorder(isUser ? AppTheme.primaryAccent.opacity(0.5) : AppTheme.border, lineWidth: isUser ? 2 : 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: isUser ? .bold : .medium))
                    .foregroundStyle(isUser ? .white : AppTheme.secondaryText)
                Text(tier.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tier.color1.opacity(0.7))
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isUser ? AppTheme.primaryAccent : AppTheme.muted)
                Text("\(rowScore)")
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundStyle(isUser ? .white : AppTheme.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isUser ? AppTheme.primaryAccent.opacity(0.15) : AppTheme.cardSurfaceElevated)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isUser ? AppTheme.primaryAccent.opacity(0.3) : AppTheme.border, lineWidth: 1)
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isUser ? AppTheme.cardSurfaceElevated : AppTheme.cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isSpotlit
                        ? AppTheme.primaryAccent.opacity(0.7)
                        : (isUser ? AppTheme.primaryAccent.opacity(0.25) : AppTheme.border.opacity(0.4)),
                    lineWidth: isSpotlit ? 2 : 1
                )
        )
        .shadow(color: isSpotlit ? AppTheme.primaryAccent.opacity(spotlightGlow ? 0.4 : 0.25) : .clear, radius: isSpotlit ? 20 : 0)
        .scaleEffect(isUser ? spotlightScale : 1.0)
        .animation(.spring(duration: 0.4, bounce: 0.2), value: spotlightUser)
        .animation(.easeInOut(duration: 1.5), value: spotlightGlow)
    }

    private func rankColor(rank: Int, isUser: Bool) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.80)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return isUser ? AppTheme.primaryAccent : AppTheme.secondaryText
        }
    }
}
