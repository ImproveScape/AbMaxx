import SwiftUI

struct ShardData: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let size: CGFloat
    let delay: Double
}

struct BadgeUnlockView: View {
    let oldBadge: RankTier?
    let newBadge: RankTier
    let onDismiss: () -> Void

    @State private var phase: AnimPhase = .showOld
    @State private var shatterTriggered: Bool = false
    @State private var newBadgeScale: CGFloat = 0.0
    @State private var newBadgeRotation: Double = -40
    @State private var newBadgeOpacity: Double = 0
    @State private var impactRingScale: CGFloat = 0.3
    @State private var impactRingOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var ladderOpacity: Double = 0
    @State private var ladderOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var particlesActive: Bool = false
    @State private var shimmerPhase: CGFloat = -200
    @State private var screenFlash: Double = 0
    @State private var oldBadgeScale: CGFloat = 1.0
    @State private var oldBadgeOpacity: Double = 1.0
    @State private var shakeAmount: CGFloat = 0
    @State private var crackOpacity: Double = 0
    @State private var hapticTrigger: Int = 0

    private enum AnimPhase {
        case showOld, shatter, reveal, complete
    }

    private let shards: [ShardData] = {
        var result: [ShardData] = []
        for i in 0..<20 {
            let angle = Double(i) / 20.0 * .pi * 2
            let dist = CGFloat.random(in: 180...320)
            let startDist = CGFloat.random(in: 5...20)
            result.append(ShardData(
                id: i,
                startX: cos(angle) * startDist,
                startY: sin(angle) * startDist,
                endX: cos(angle) * dist + CGFloat.random(in: -40...40),
                endY: sin(angle) * dist + CGFloat.random(in: -60...20),
                rotation: Double.random(in: -720...720),
                size: CGFloat.random(in: 4...14),
                delay: Double.random(in: 0...0.08)
            ))
        }
        return result
    }()

    private var hasOldBadge: Bool {
        oldBadge != nil
    }

    var body: some View {
        ZStack {
            AppTheme.background.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture { }

            Color.white.opacity(screenFlash)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    impactRing
                    shatterParticles
                    burstParticles

                    if hasOldBadge, let old = oldBadge {
                        RankBadgeImage(tier: old, isUnlocked: true, size: 100)
                            .scaleEffect(oldBadgeScale)
                            .opacity(oldBadgeOpacity)
                            .offset(x: shakeAmount)
                            .overlay(
                                ZStack {
                                    ForEach(0..<4) { i in
                                        Rectangle()
                                            .fill(Color.white.opacity(crackOpacity * 0.8))
                                            .frame(width: 2, height: CGFloat.random(in: 20...50))
                                            .rotationEffect(.degrees(Double(i) * 45 + Double.random(in: -15...15)))
                                            .offset(
                                                x: CGFloat.random(in: -15...15),
                                                y: CGFloat.random(in: -15...15)
                                            )
                                    }
                                }
                                .opacity(crackOpacity)
                            )
                    }

                    RankBadgeImage(tier: newBadge, isUnlocked: true, size: 110)
                        .scaleEffect(newBadgeScale)
                        .rotationEffect(.degrees(newBadgeRotation))
                        .opacity(newBadgeOpacity)
                        .shadow(color: newBadge.color1.opacity(glowRadius > 0 ? 0.8 : 0), radius: 50)
                }
                .frame(height: 240)

                VStack(spacing: 8) {
                    Text("RANK UP")
                        .font(.system(size: 13, weight: .black))
                        .tracking(6)
                        .foregroundStyle(newBadge.color1.opacity(0.9))

                    Text(newBadge.name)
                        .font(.system(size: 42, weight: .black, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [newBadge.color1, newBadge.color2, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.5), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerPhase)
                                .mask {
                                    Text(newBadge.name)
                                        .font(.system(size: 42, weight: .black, design: .default))
                                }
                        )
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)
                .padding(.top, 20)

                if hasOldBadge, let old = oldBadge {
                    rankLadderTransition(from: old, to: newBadge)
                        .opacity(ladderOpacity)
                        .offset(y: ladderOffset)
                        .padding(.top, 28)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("LET'S GO")
                        .font(.system(size: 17, weight: .black))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [newBadge.color1, newBadge.color2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(.capsule)
                        .shadow(color: newBadge.color1.opacity(0.6), radius: 24, y: 8)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                .opacity(buttonOpacity)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: hapticTrigger)
        .onAppear {
            if hasOldBadge {
                runUpgradeSequence()
            } else {
                runFirstBadgeSequence()
            }
        }
    }

    private var impactRing: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [newBadge.color1, newBadge.color2, newBadge.color1.opacity(0.3), newBadge.color1],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 200, height: 200)
                .scaleEffect(impactRingScale)
                .opacity(impactRingOpacity)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [newBadge.color1.opacity(0.2), newBadge.color2.opacity(0.05), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(impactRingScale)
                .opacity(impactRingOpacity)

            Circle()
                .stroke(newBadge.color1.opacity(0.15), lineWidth: 1.5)
                .frame(width: 260, height: 260)
                .scaleEffect(impactRingScale * 0.9)
                .opacity(impactRingOpacity * 0.5)
        }
    }

    private var shatterParticles: some View {
        ZStack {
            ForEach(shards) { shard in
                ShardView(
                    shard: shard,
                    color: oldBadge?.color1 ?? newBadge.color1,
                    isShattered: shatterTriggered
                )
            }
        }
    }

    private var burstParticles: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                let angle = Double(i) / 16.0 * .pi * 2
                Circle()
                    .fill(
                        i % 2 == 0
                        ? newBadge.color1
                        : newBadge.color2
                    )
                    .frame(width: particlesActive ? 3 : 6, height: particlesActive ? 3 : 6)
                    .offset(
                        x: particlesActive ? cos(angle) * 140 : 0,
                        y: particlesActive ? sin(angle) * 140 : 0
                    )
                    .opacity(particlesActive ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 0.8).delay(Double(i) * 0.02),
                        value: particlesActive
                    )
            }
        }
    }

    private func rankLadderTransition(from old: RankTier, to new: RankTier) -> some View {
        let oldIdx = old.id
        let newIdx = new.id
        let tiersBetween = Array(RankTier.allTiers.filter { $0.id >= oldIdx && $0.id <= newIdx })

        return VStack(spacing: 0) {
            ForEach(tiersBetween.reversed()) { tier in
                let isCurrent = tier.id == newIdx
                let isOld = tier.id == oldIdx
                let isMiddle = !isCurrent && !isOld

                HStack(spacing: 12) {
                    RankBadgeImage(tier: tier, isUnlocked: true, size: isCurrent ? 36 : 26)
                        .opacity(isOld ? 0.3 : (isMiddle ? 0.5 : 1.0))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tier.name.uppercased())
                            .font(.system(size: isCurrent ? 14 : 11, weight: .black, design: .default))
                            .tracking(1.5)
                            .foregroundStyle(
                                isCurrent
                                ? AnyShapeStyle(LinearGradient(colors: [tier.color1, tier.color2], startPoint: .leading, endPoint: .trailing))
                                : (isOld ? AnyShapeStyle(AppTheme.muted.opacity(0.5)) : AnyShapeStyle(AppTheme.secondaryText))
                            )

                        if isCurrent {
                            Text("NEW RANK")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(tier.color1)
                        }
                        if isOld {
                            Text("PREVIOUS")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(AppTheme.muted.opacity(0.4))
                        }
                    }

                    Spacer()

                    if isCurrent {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(tier.color1)
                            .symbolEffect(.bounce, value: ladderOpacity)
                    } else if isOld {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.muted.opacity(0.3))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, isCurrent ? 14 : 10)
                .background(
                    isCurrent
                    ? AnyShapeStyle(tier.color1.opacity(0.08))
                    : AnyShapeStyle(Color.clear)
                )

                if tier.id != oldIdx {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(
                                isCurrent || isMiddle
                                ? LinearGradient(colors: [new.color1.opacity(0.4), new.color1.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [AppTheme.muted.opacity(0.15), AppTheme.muted.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: 2, height: 16)
                            .padding(.leading, 30)
                        Spacer()
                    }
                }
            }
        }
        .background(AppTheme.cardSurface.opacity(0.6))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [new.color1.opacity(0.3), new.color2.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 32)
    }

    private func runUpgradeSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.08).repeatCount(6, autoreverses: true)) {
                shakeAmount = 8
            }
            withAnimation(.easeIn(duration: 0.4)) {
                crackOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            hapticTrigger += 1
            shatterTriggered = true

            withAnimation(.easeOut(duration: 0.2)) {
                oldBadgeScale = 0.0
                oldBadgeOpacity = 0.0
                shakeAmount = 0
                screenFlash = 0.6
            }

            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                screenFlash = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            hapticTrigger += 1
            particlesActive = true

            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                newBadgeScale = 1.15
                newBadgeRotation = 5
                newBadgeOpacity = 1
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                impactRingScale = 1.0
                impactRingOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 1.0)) {
                glowRadius = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                newBadgeScale = 1.0
                newBadgeRotation = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeOut(duration: 0.6)) {
                impactRingOpacity = 0.4
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            withAnimation(.linear(duration: 1.0).delay(0.2)) {
                shimmerPhase = 200
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                ladderOpacity = 1.0
                ladderOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                buttonOpacity = 1.0
            }
        }
    }

    private func runFirstBadgeSequence() {
        oldBadgeOpacity = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            hapticTrigger += 1
            particlesActive = true

            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                newBadgeScale = 1.15
                newBadgeRotation = 5
                newBadgeOpacity = 1
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                impactRingScale = 1.0
                impactRingOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.8)) {
                glowRadius = 1.0
                screenFlash = 0.3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                screenFlash = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                newBadgeScale = 1.0
                newBadgeRotation = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            withAnimation(.linear(duration: 1.0).delay(0.2)) {
                shimmerPhase = 200
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                buttonOpacity = 1.0
            }
        }
    }
}

struct ShardView: View {
    let shard: ShardData
    let color: Color
    let isShattered: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: shard.size > 10 ? 3 : 1.5)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(
                width: shard.size * (shard.id % 3 == 0 ? 1.5 : 1.0),
                height: shard.size
            )
            .shadow(color: color.opacity(0.6), radius: 4)
            .offset(
                x: isShattered ? shard.endX : shard.startX,
                y: isShattered ? shard.endY : shard.startY
            )
            .rotationEffect(.degrees(isShattered ? shard.rotation : 0))
            .opacity(isShattered ? 0 : 0.9)
            .animation(
                .easeOut(duration: 0.7).delay(shard.delay),
                value: isShattered
            )
    }
}
