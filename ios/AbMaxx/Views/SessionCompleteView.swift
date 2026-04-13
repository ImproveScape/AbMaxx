import SwiftUI

struct SessionCompleteView: View {
    let exercises: [Exercise]
    let completedCount: Int
    let totalElapsed: Int
    let difficulty: DifficultyLevel
    let daysUntilNextScan: Int
    let canScan: Bool
    let onDismiss: () -> Void

    @State private var checkScale: CGFloat = 0.0
    @State private var checkOpacity: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var titleOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 20
    @State private var contentOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 30
    @State private var showContent: Bool = false
    @State private var statsAppeared: Bool = false

    private var regionsHit: [AbRegion] {
        var seen: [AbRegion] = []
        for ex in exercises where !seen.contains(ex.region) { seen.append(ex.region) }
        return seen
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()
            StandardBackgroundOrbs()

            topGlow

            VStack(spacing: 0) {
                if !showContent {
                    burstPhase
                        .transition(.opacity)
                } else {
                    summaryPhase
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showContent)
        }
        .onAppear { startSequence() }
    }

    // MARK: - Background glow

    private var topGlow: some View {
        RadialGradient(
            colors: [AppTheme.primaryAccent.opacity(0.18 * glowOpacity), .clear],
            center: .top,
            startRadius: 50,
            endRadius: 420
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Burst Phase

    private var burstPhase: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.06))
                    .frame(width: 220, height: 220)
                    .scaleEffect(checkScale)

                Circle()
                    .fill(AppTheme.success.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .scaleEffect(checkScale)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.success, AppTheme.primaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)

                Image(systemName: "checkmark")
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: AppTheme.success.opacity(0.8), radius: 24)
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)
            }

            VStack(spacing: 6) {
                Text("SESSION COMPLETE")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(2)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Text(formattedDate.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent.opacity(0.8))
                    .tracking(1.5)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Summary Phase

    private var summaryPhase: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Hero header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.success.opacity(0.08))
                                .frame(width: 80, height: 80)

                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(AppTheme.success)
                                .shadow(color: AppTheme.success.opacity(0.5), radius: 16)
                        }

                        Text("Workout Complete")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)

                        Text(formattedDate)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .opacity(contentOpacity)

                    // Big stat row
                    HStack(spacing: 12) {
                        bigStat(
                            value: formatTime(totalElapsed),
                            label: "Duration",
                            icon: "timer",
                            color: AppTheme.primaryAccent
                        )
                        bigStat(
                            value: "\(completedCount)",
                            label: "Exercises",
                            icon: "bolt.fill",
                            color: AppTheme.success
                        )
                        bigStat(
                            value: "\(regionsHit.count)",
                            label: "Zones Hit",
                            icon: "target",
                            color: AppTheme.orange
                        )
                    }
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)

                    // Exercise list
                    exercisesCard
                        .opacity(statsAppeared ? 1 : 0)
                        .offset(y: statsAppeared ? 0 : 20)
                        .animation(.spring(duration: 0.5, bounce: 0.1).delay(0.15), value: statsAppeared)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)

            doneButton
        }
    }

    private func bigStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
        )
    }

    private var exercisesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("EXERCISES COMPLETED")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(1)
                Spacer()
                Text("\(completedCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
            }
            .padding(.bottom, 14)

            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, ex in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.success.opacity(0.1))
                            .frame(width: 34, height: 34)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.success)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(ex.region.rawValue)
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.muted)
                    }

                    Spacer()

                    Text(ex.reps)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(.vertical, 10)
                .opacity(statsAppeared ? 1 : 0)
                .offset(x: statsAppeared ? 0 : 16)
                .animation(
                    .spring(duration: 0.45, bounce: 0.15).delay(0.25 + Double(index) * 0.055),
                    value: statsAppeared
                )

                if index < exercises.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.05))
                        .padding(.leading, 46)
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
    }

    private var doneButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [AppTheme.background.opacity(0), AppTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            Button(action: onDismiss) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primaryAccent)
                    .clipShape(.rect(cornerRadius: AppTheme.buttonCornerRadius))
                    .shadow(color: AppTheme.primaryAccent.opacity(0.45), radius: 16, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background)
        .opacity(statsAppeared ? 1 : 0)
        .animation(.easeIn(duration: 0.4).delay(0.5), value: statsAppeared)
    }

    // MARK: - Sequence

    private func startSequence() {
        withAnimation(.spring(duration: 0.55, bounce: 0.45)) {
            checkScale = 1.0
            checkOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
            glowOpacity = 1.0
        }

        withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.35)) {
            titleOpacity = 1.0
            titleOffset = 0
        }

        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.3)) {
                glowOpacity = 0.4
            }
            try? await Task.sleep(for: .seconds(0.1))
            showContent = true
            withAnimation(.easeOut(duration: 0.45)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
            try? await Task.sleep(for: .seconds(0.15))
            statsAppeared = true
        }
    }
}

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
