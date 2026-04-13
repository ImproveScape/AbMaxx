import SwiftUI

struct BadgeLadderView: View {
    let currentScore: Int
    @Environment(\.dismiss) private var dismiss
    @State private var appeared: Bool = false
    @State private var selectedTier: RankTier? = nil

    private var currentTierIndex: Int {
        RankTier.currentTierIndex(for: currentScore)
    }

    private var reversedTiers: [RankTier] {
        RankTier.allTiers.reversed()
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            StandardBackgroundOrbs()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(reversedTiers.enumerated()), id: \.element.id) { index, tier in
                                let isUnlocked = tier.id <= currentTierIndex
                                let isCurrent = tier.id == currentTierIndex
                                let isLast = index == reversedTiers.count - 1

                                VStack(spacing: 0) {
                                    Button {
                                        selectedTier = tier
                                    } label: {
                                        badgeRow(tier: tier, isUnlocked: isUnlocked, isCurrent: isCurrent)
                                            .id(tier.id)
                                    }
                                    .buttonStyle(.plain)

                                    if !isLast {
                                        connectorLine(isAboveUnlocked: isUnlocked, tier: tier)
                                    }
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 12)
                                .animation(
                                    .spring(duration: 0.5, bounce: 0.15).delay(Double(index) * 0.04),
                                    value: appeared
                                )
                            }

                            Color.clear.frame(height: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                    .onAppear {
                        proxy.scrollTo(currentTierIndex, anchor: .center)
                        withAnimation {
                            appeared = true
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedTier) { tier in
            let isUnlocked = tier.id <= currentTierIndex
            let isCurrent = tier.id == currentTierIndex
            BadgeDetailSheet(
                rankTier: tier,
                isUnlocked: isUnlocked,
                isCurrent: isCurrent,
                currentScore: currentScore
            )
            .presentationDetents([.medium, .large])
            .presentationBackground(AppTheme.background)
            .presentationDragIndicator(.hidden)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 5)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rank Ladder")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    let currentTier = RankTier.allTiers[currentTierIndex]
                    HStack(spacing: 6) {
                        Text("Overall \(currentScore)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("·")
                            .foregroundStyle(AppTheme.muted)
                        Text(currentTier.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [currentTier.color1, currentTier.color2],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.muted)
                }
            }
        }
    }

    private func badgeRow(tier: RankTier, isUnlocked: Bool, isCurrent: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                if isCurrent {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tier.color1.opacity(0.25), tier.color1.opacity(0.05)],
                                center: .center,
                                startRadius: 5,
                                endRadius: 28
                            )
                        )
                        .frame(width: 56, height: 56)
                } else {
                    Circle()
                        .fill(isUnlocked ? tier.color1.opacity(0.08) : AppTheme.cardSurfaceElevated)
                        .frame(width: 52, height: 52)
                }

                RankBadgeImage(tier: tier, isUnlocked: isUnlocked, size: isCurrent ? 42 : 38)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(tier.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(
                            isCurrent
                                ? AnyShapeStyle(LinearGradient(colors: [tier.color1, tier.color2], startPoint: .leading, endPoint: .trailing))
                                : (isUnlocked ? AnyShapeStyle(.white) : AnyShapeStyle(AppTheme.muted))
                        )

                    if isCurrent {
                        Text("CURRENT")
                            .font(.system(size: 9, weight: .black))
                            .tracking(1)
                            .foregroundStyle(tier.color1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tier.color1.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text("OVR \(tier.minScore)+")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isUnlocked ? AppTheme.secondaryText : AppTheme.muted.opacity(0.6))
            }

            Spacer()

            if isUnlocked && !isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(tier.color1.opacity(0.6))
            } else if !isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isCurrent
                        ? AppTheme.cardSurfaceElevated
                        : AppTheme.cardSurface
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isCurrent
                        ? LinearGradient(colors: [tier.color1.opacity(0.6), tier.color2.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [AppTheme.border.opacity(0.4), AppTheme.border.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: isCurrent ? 1.5 : 1
                )
        )
        .shadow(color: isCurrent ? tier.color1.opacity(0.15) : .clear, radius: 12)
    }

    private func connectorLine(isAboveUnlocked: Bool, tier: RankTier) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(
                isAboveUnlocked
                    ? LinearGradient(colors: [tier.color1.opacity(0.3), tier.color1.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [AppTheme.border.opacity(0.2), AppTheme.border.opacity(0.1)], startPoint: .top, endPoint: .bottom)
            )
            .frame(width: 2, height: 24)
            .padding(.leading, 45)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension RankTier: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated static func == (lhs: RankTier, rhs: RankTier) -> Bool {
        lhs.id == rhs.id
    }
}
