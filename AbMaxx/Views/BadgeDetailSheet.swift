import SwiftUI

struct BadgeDetailSheet: View {
    let rankTier: RankTier
    let isUnlocked: Bool
    let isCurrent: Bool
    let currentScore: Int
    @Environment(\.dismiss) private var dismiss
    @State private var animateIn: Bool = false

    private var howToGet: String {
        if isUnlocked {
            return isCurrent ? "This is your current rank. Keep scanning to maintain or improve!" : "You've surpassed this rank. Keep going!"
        }
        let needed = rankTier.minScore - currentScore
        return "Score \(rankTier.minScore)+ on your AbMaxx scan to unlock. You need \(needed) more points."
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 24)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                rankTier.color1.opacity(0.18),
                                rankTier.color1.opacity(0.04),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [rankTier.color1.opacity(0.3), rankTier.color2.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateIn ? 1 : 0.85)
                    .opacity(animateIn ? 1 : 0)

                RankBadgeImage(tier: rankTier, isUnlocked: isUnlocked, size: 130)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)
            }
            .frame(height: 180)

            Text(rankTier.name)
                .font(.system(size: 28, weight: .black, design: .default))
                .foregroundStyle(
                    isUnlocked
                        ? LinearGradient(colors: [rankTier.color1, rankTier.color2], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [AppTheme.muted, AppTheme.muted.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                )
                .padding(.top, 4)

            if isCurrent {
                Text("CURRENT RANK")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(rankTier.color1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(rankTier.color1.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.top, 6)
            } else if isUnlocked {
                Text("UNLOCKED")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.primaryAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(AppTheme.primaryAccent.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.top, 6)
            } else {
                Text("LOCKED")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.muted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(AppTheme.muted.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.top, 6)
            }

            Text(rankTier.description)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: isUnlocked ? "checkmark.circle.fill" : "target")
                        .font(.subheadline.bold())
                        .foregroundStyle(isUnlocked ? AppTheme.primaryAccent : rankTier.color1)
                    Text("How to Earn")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.bottom, 10)

                Text(howToGet)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.bottom, 16)

                if !isUnlocked {
                    let progress = min(Double(currentScore) / Double(rankTier.minScore), 1.0)
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppTheme.border)
                                    .frame(height: 6)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [rankTier.color1, rankTier.color2],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("\(currentScore)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(rankTier.minScore)")
                                .font(.caption2.bold())
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                    .padding(.bottom, 16)
                }

                Divider().overlay(AppTheme.border)
                    .padding(.bottom, 14)

                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(rankTier.color1)
                    Text("Rank Perks")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(rankTier.perks, id: \.self) { perk in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(isUnlocked ? rankTier.color1 : AppTheme.muted.opacity(0.5))
                                .frame(width: 6, height: 6)
                            Text(perk)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(isUnlocked ? AppTheme.secondaryText : AppTheme.muted)
                        }
                    }
                }
            }
            .padding(18)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()
        }
        .background(AppTheme.background)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                animateIn = true
            }
        }
    }
}

struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.08))
        path.addLine(to: CGPoint(x: w, y: h * 0.55))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.85, y: h * 0.85))
        path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.55), control: CGPoint(x: w * 0.15, y: h * 0.85))
        path.addLine(to: CGPoint(x: 0, y: h * 0.08))
        path.closeSubpath()
        return path
    }
}

extension ShieldShape: InsettableShape {
    func inset(by amount: CGFloat) -> some InsettableShape {
        self
    }
}
