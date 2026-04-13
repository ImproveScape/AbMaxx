import SwiftUI

struct SessionCompleteView: View {
    let exercises: [Exercise]
    let completedCount: Int
    let totalElapsed: Int
    let difficulty: DifficultyLevel
    let daysUntilNextScan: Int
    let canScan: Bool
    let onDismiss: () -> Void

    @State private var phase: CompletionPhase = .burst
    @State private var checkScale: CGFloat = 0.0
    @State private var checkOpacity: Double = 0.0
    @State private var ringScale: CGFloat = 0.3
    @State private var greenWash: Double = 0.0
    @State private var greenWashScale: CGFloat = 0.5
    @State private var burstRays: Double = 0.0
    @State private var particleTrigger: Int = 0
    @State private var showOverview: Bool = false
    @State private var overviewOffset: CGFloat = 600
    @State private var pulseRing1: CGFloat = 0.5
    @State private var pulseRing2: CGFloat = 0.5
    @State private var pulseRing3: CGFloat = 0.5
    @State private var pulseOpacity1: Double = 0.8
    @State private var pulseOpacity2: Double = 0.6
    @State private var pulseOpacity3: Double = 0.4
    @State private var sparkleRotation: Double = 0
    @State private var titleOpacity: Double = 0.0
    @State private var titleScale: CGFloat = 0.5
    @State private var statsAppeared: Bool = false

    nonisolated private enum CompletionPhase: Sendable {
        case burst
        case overview
    }

    private let neonGreen = Color(red: 0.1, green: 0.95, blue: 0.4)
    private let darkGreen = Color(red: 0.05, green: 0.6, blue: 0.25)

    private var musclesWorked: [String] {
        var muscles: [String] = []
        for ex in exercises {
            for m in ex.musclesWorked {
                if !muscles.contains(m) {
                    muscles.append(m)
                }
            }
        }
        return muscles
    }

    private var regionsHit: [AbRegion] {
        var regions: [AbRegion] = []
        for ex in exercises {
            if !regions.contains(ex.region) {
                regions.append(ex.region)
            }
        }
        return regions
    }

    private var estimatedSets: Int {
        exercises.count * 3
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            greenBurstBackground

            expandingRings

            sparkleField

            if !showOverview {
                burstCheckmark
            }

            if showOverview {
                overviewContent
                    .offset(y: overviewOffset)
            }
        }
        .sensoryFeedback(.success, trigger: phase == .burst ? 1 : 0)
        .onAppear { startSequence() }
    }

    // MARK: - Green Burst Background

    private var greenBurstBackground: some View {
        ZStack {
            RadialGradient(
                colors: [neonGreen.opacity(0.5 * greenWash), darkGreen.opacity(0.3 * greenWash), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 500
            )
            .scaleEffect(greenWashScale)
            .ignoresSafeArea()

            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [neonGreen.opacity(0.3 * burstRays), .clear],
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 500, height: 3)
                    .rotationEffect(.degrees(Double(i) * 30))
                    .scaleEffect(x: burstRays, y: 1)
            }
            .opacity(burstRays)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Expanding Rings

    private var expandingRings: some View {
        ZStack {
            Circle()
                .stroke(neonGreen.opacity(pulseOpacity1), lineWidth: 3)
                .frame(width: 200, height: 200)
                .scaleEffect(pulseRing1)

            Circle()
                .stroke(neonGreen.opacity(pulseOpacity2), lineWidth: 2)
                .frame(width: 200, height: 200)
                .scaleEffect(pulseRing2)

            Circle()
                .stroke(neonGreen.opacity(pulseOpacity3), lineWidth: 1.5)
                .frame(width: 200, height: 200)
                .scaleEffect(pulseRing3)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Sparkle Field

    private var sparkleField: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                guard greenWash > 0.1 else { return }

                for i in 0..<60 {
                    let seed = Double(i) * 97.31
                    let angle = seed + time * (20 + seed.truncatingRemainder(dividingBy: 15))
                    let radius = (40 + seed.truncatingRemainder(dividingBy: 250)) * greenWash
                    let x = size.width / 2 + cos(angle * .pi / 180) * radius
                    let y = size.height / 2 + sin(angle * .pi / 180) * radius

                    let sparkleSize = 2 + sin(time * 3 + seed) * 1.5
                    let alpha = max(0, greenWash * (0.3 + sin(time * 4 + seed) * 0.3))

                    let colors: [Color] = [neonGreen, .white, AppTheme.success, Color(red: 0.4, green: 1.0, blue: 0.6)]
                    let color = colors[i % colors.count]

                    context.opacity = alpha
                    let rect = CGRect(x: x - sparkleSize / 2, y: y - sparkleSize / 2, width: sparkleSize, height: sparkleSize)
                    context.fill(Circle().path(in: rect), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: - Burst Checkmark

    private var burstCheckmark: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(neonGreen.opacity(0.15))
                    .frame(width: 180, height: 180)
                    .scaleEffect(ringScale)

                Circle()
                    .fill(neonGreen.opacity(0.08))
                    .frame(width: 260, height: 260)
                    .scaleEffect(ringScale * 0.85)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [neonGreen, AppTheme.success],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)

                Image(systemName: "checkmark")
                    .font(.system(size: 64, weight: .black))
                    .foregroundStyle(neonGreen)
                    .shadow(color: neonGreen.opacity(0.9), radius: 30)
                    .shadow(color: neonGreen.opacity(0.5), radius: 60)
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)
            }

            VStack(spacing: 8) {
                Text("SESSION COMPLETE")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(3)
                    .shadow(color: neonGreen.opacity(0.6), radius: 20)
                    .opacity(titleOpacity)
                    .scaleEffect(titleScale)

                Text("ALL EXERCISES CRUSHED")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(neonGreen.opacity(0.8))
                    .tracking(2)
                    .opacity(titleOpacity)
            }
        }
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(neonGreen)
                        .shadow(color: neonGreen.opacity(0.5), radius: 16)

                    Text("TODAY'S WORKOUT")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .tracking(2)

                    Text("Overview")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(.top, 50)
                .padding(.bottom, 24)

                HStack(spacing: 0) {
                    overviewStat(value: "\(completedCount)", label: "Exercises", icon: "figure.core.training", color: neonGreen)
                    overviewStat(value: formatTime(totalElapsed), label: "Duration", icon: "clock.fill", color: AppTheme.orange)
                    overviewStat(value: "\(regionsHit.count)", label: "Regions Hit", icon: "target", color: AppTheme.primaryAccent)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .opacity(statsAppeared ? 1 : 0)
                .offset(y: statsAppeared ? 0 : 20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.orange)
                        Text("MUSCLES WORKED")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AppTheme.muted)
                            .tracking(1.5)
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(musclesWorked, id: \.self) { muscle in
                            Text(muscle)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(AppTheme.success.opacity(0.12))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(AppTheme.success.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(16)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .opacity(statsAppeared ? 1 : 0)
                .offset(y: statsAppeared ? 0 : 30)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("REGIONS HIT")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AppTheme.muted)
                            .tracking(1.5)
                    }

                    HStack(spacing: 10) {
                        ForEach(regionsHit) { region in
                            VStack(spacing: 6) {
                                Image(systemName: region.icon)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(neonGreen)
                                    .frame(width: 44, height: 44)
                                    .background(neonGreen.opacity(0.1))
                                    .clipShape(Circle())

                                Text(region.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(16)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .opacity(statsAppeared ? 1 : 0)
                .offset(y: statsAppeared ? 0 : 40)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("EXERCISES")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AppTheme.muted)
                            .tracking(1.5)
                    }

                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, ex in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(ex.region.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppTheme.muted)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(neonGreen)
                        }
                        .padding(.vertical, 6)
                        .opacity(statsAppeared ? 1 : 0)
                        .offset(x: statsAppeared ? 0 : 30)
                        .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.6 + Double(index) * 0.08), value: statsAppeared)
                    }
                }
                .padding(16)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                Button { onDismiss() } label: {
                    Text("Done")
                        .font(.headline.bold())
                }
                .buttonStyle(GlowButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                .opacity(statsAppeared ? 1 : 0)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func overviewStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sequence

    private func startSequence() {
        withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
            checkScale = 1.0
            checkOpacity = 1.0
            ringScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.8)) {
            greenWash = 1.0
            greenWashScale = 1.5
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            burstRays = 1.0
        }

        withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
            pulseRing1 = 3.0
            pulseOpacity1 = 0
        }
        withAnimation(.easeOut(duration: 0.9).delay(0.25)) {
            pulseRing2 = 3.5
            pulseOpacity2 = 0
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.35)) {
            pulseRing3 = 4.0
            pulseOpacity3 = 0
        }

        withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(0.3)) {
            titleOpacity = 1.0
            titleScale = 1.0
        }

        withAnimation(.easeIn(duration: 0.5).delay(1.5)) {
            burstRays = 0
        }

        Task {
            try? await Task.sleep(for: .seconds(2.0))
            withAnimation(.easeInOut(duration: 0.5)) {
                greenWash = 0.15
                checkScale = 0.0
                checkOpacity = 0.0
                titleOpacity = 0.0
            }

            try? await Task.sleep(for: .seconds(0.3))
            showOverview = true
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                overviewOffset = 0
            }

            try? await Task.sleep(for: .seconds(0.2))
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                statsAppeared = true
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x - spacing)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
