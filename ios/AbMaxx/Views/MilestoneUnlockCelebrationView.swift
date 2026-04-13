import SwiftUI

struct MilestoneUnlockCelebrationView: View {
    let milestone: AppMilestone
    let onDismiss: () -> Void

    @State private var phase: Int = 0
    @State private var badgeScale: CGFloat = 0.0
    @State private var badgeOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 40
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var screenFlash: Double = 0
    @State private var glowPulse: Bool = false
    @State private var particlesActive: Bool = false
    @State private var shimmerPhase: CGFloat = -300
    @State private var hapticTrigger: Int = 0
    @State private var confettiWave1: Bool = false
    @State private var confettiWave2: Bool = false
    @State private var outerRingScale: CGFloat = 0.5
    @State private var outerRingOpacity: Double = 0
    @State private var starBurstActive: Bool = false
    @State private var bgGlowScale: CGFloat = 0.3
    @State private var bgGlowOpacity: Double = 0
    @State private var labelTagScale: CGFloat = 0.5
    @State private var labelTagOpacity: Double = 0
    @State private var secondFlash: Double = 0
    @State private var badgeShadowRadius: CGFloat = 0
    @State private var continuousShimmer: Bool = false

    private let confettiWave1Pieces: [ConfettiPiece] = ConfettiPiece.generateWave(count: 50, spread: 350, yBias: -250)
    private let confettiWave2Pieces: [ConfettiPiece] = ConfettiPiece.generateWave(count: 40, spread: 300, yBias: -180)

    var body: some View {
        ZStack {
            Color.black.opacity(0.96)
                .ignoresSafeArea()
                .onTapGesture { }

            backgroundGlow

            Color.white.opacity(screenFlash)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Color.white.opacity(secondFlash)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            confettiLayer(pieces: confettiWave1Pieces, active: confettiWave1)
            confettiLayer(pieces: confettiWave2Pieces, active: confettiWave2)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    outerGlowRing
                    innerSpinningRing
                    starBurst
                    burstParticles

                    badgeContent
                        .scaleEffect(badgeScale)
                        .opacity(badgeOpacity)
                        .shadow(color: milestone.badgeStyle.glowColor.opacity(0.8), radius: badgeShadowRadius)
                }
                .frame(height: 300)

                VStack(spacing: 12) {
                    Text("MILESTONE UNLOCKED")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(6)
                        .foregroundStyle(milestone.badgeStyle.glowColor)
                        .scaleEffect(labelTagScale)
                        .opacity(labelTagOpacity)

                    Text(milestone.title)
                        .font(.system(size: 40, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white] + milestone.badgeStyle.gradient + [.white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: milestone.badgeStyle.glowColor.opacity(0.5), radius: 20)
                        .overlay(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.6), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 120)
                                .offset(x: shimmerPhase)
                                .mask {
                                    Text(milestone.title)
                                        .font(.system(size: 40, weight: .black))
                                        .multilineTextAlignment(.center)
                                }
                        )

                    Text(milestone.subtitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .opacity(subtitleOpacity)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)
                .padding(.top, 24)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .symbolEffect(.bounce, value: phase >= 6)
                        Text("LET'S GO")
                            .font(.system(size: 17, weight: .black))
                            .tracking(3)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: milestone.badgeStyle.gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            if continuousShimmer {
                                TimelineView(.animation(minimumInterval: 0.03)) { timeline in
                                    let t = timeline.date.timeIntervalSinceReferenceDate
                                    let x = sin(t * 2) * 120
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.2), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 80)
                                    .offset(x: x)
                                    .blendMode(.overlay)
                                }
                            }
                        }
                    )
                    .clipShape(.capsule)
                    .shadow(color: milestone.badgeStyle.glowColor.opacity(0.7), radius: 30, y: 10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                .opacity(buttonOpacity)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: hapticTrigger)
        .onAppear {
            runCelebrationSequence()
        }
    }

    private var backgroundGlow: some View {
        ZStack {
            RadialGradient(
                colors: [
                    milestone.badgeStyle.glowColor.opacity(0.15),
                    milestone.badgeStyle.gradient.first?.opacity(0.05) ?? .clear,
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .scaleEffect(bgGlowScale)
            .opacity(bgGlowOpacity)
            .ignoresSafeArea()

            if glowPulse {
                TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let pulse = 0.8 + sin(t * 1.5) * 0.2
                    RadialGradient(
                        colors: [
                            milestone.badgeStyle.glowColor.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 350
                    )
                    .scaleEffect(pulse)
                    .ignoresSafeArea()
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var outerGlowRing: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: milestone.badgeStyle.gradient + [milestone.badgeStyle.gradient.first ?? .white],
                    center: .center
                ),
                lineWidth: 1.5
            )
            .frame(width: 220, height: 220)
            .scaleEffect(outerRingScale)
            .opacity(outerRingOpacity)
            .blur(radius: 1)
    }

    private var innerSpinningRing: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        milestone.badgeStyle.ringColor,
                        milestone.badgeStyle.innerRingColor,
                        milestone.badgeStyle.glowColor.opacity(0.4),
                        .white.opacity(0.3),
                        milestone.badgeStyle.ringColor
                    ],
                    center: .center
                ),
                lineWidth: 2.5
            )
            .frame(width: 185, height: 185)
            .rotationEffect(.degrees(ringRotation))
            .scaleEffect(ringScale)
            .opacity(ringOpacity)
    }

    @ViewBuilder
    private var badgeContent: some View {
        if let url = milestone.imageURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                } else {
                    fallbackBadgeIcon
                }
            }
        } else {
            fallbackBadgeIcon
        }
    }

    private var fallbackBadgeIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: milestone.badgeStyle.gradient + [milestone.badgeStyle.gradient.last?.opacity(0.5) ?? .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 130, height: 130)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.05), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: 130, height: 130)

            VStack(spacing: 6) {
                Image(systemName: milestone.icon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 3)

                if let num = milestone.badgeNumber {
                    Text(num)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }

    private var starBurst: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) / 8.0 * .pi * 2
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [milestone.badgeStyle.glowColor, .white.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: starBurstActive ? 60 : 0, height: 2)
                    .offset(x: starBurstActive ? cos(angle) * 110 : 0, y: starBurstActive ? sin(angle) * 110 : 0)
                    .rotationEffect(.radians(angle))
                    .opacity(starBurstActive ? 0 : 0.9)
                    .animation(.easeOut(duration: 0.6).delay(Double(i) * 0.03), value: starBurstActive)
            }
        }
    }

    private var burstParticles: some View {
        ZStack {
            ForEach(0..<24, id: \.self) { i in
                let angle = Double(i) / 24.0 * .pi * 2
                let isOuter = i % 3 == 0
                Circle()
                    .fill(
                        i % 3 == 0 ? milestone.badgeStyle.gradient[0] :
                            i % 3 == 1 ? (milestone.badgeStyle.gradient.last ?? .white) :
                            .white
                    )
                    .frame(width: particlesActive ? 2 : (isOuter ? 6 : 4), height: particlesActive ? 2 : (isOuter ? 6 : 4))
                    .offset(
                        x: particlesActive ? cos(angle) * (isOuter ? 180 : 140) : 0,
                        y: particlesActive ? sin(angle) * (isOuter ? 180 : 140) : 0
                    )
                    .opacity(particlesActive ? 0 : 0.95)
                    .animation(.easeOut(duration: isOuter ? 1.0 : 0.7).delay(Double(i) * 0.015), value: particlesActive)
            }
        }
    }

    private func confettiLayer(pieces: [ConfettiPiece], active: Bool) -> some View {
        ZStack {
            ForEach(pieces, id: \.id) { piece in
                Group {
                    if piece.shape == 0 {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(piece.color)
                            .frame(width: piece.size * 0.5, height: piece.size)
                    } else if piece.shape == 1 {
                        Circle()
                            .fill(piece.color)
                            .frame(width: piece.size * 0.7, height: piece.size * 0.7)
                    } else {
                        Capsule()
                            .fill(piece.color)
                            .frame(width: piece.size * 0.3, height: piece.size * 1.2)
                    }
                }
                .offset(
                    x: active ? piece.endX : 0,
                    y: active ? piece.endY + 500 : -30
                )
                .rotationEffect(.degrees(active ? piece.rotation : 0))
                .opacity(active ? 0 : 1)
                .animation(
                    .easeOut(duration: Double.random(in: 1.8...2.5)).delay(piece.delay),
                    value: active
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func runCelebrationSequence() {
        withAnimation(.easeOut(duration: 0.6)) {
            bgGlowScale = 1.5
            bgGlowOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            hapticTrigger += 1
            particlesActive = true
            starBurstActive = true
            confettiWave1 = true

            withAnimation(.easeOut(duration: 0.12)) {
                screenFlash = 0.5
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
            withAnimation(.easeOut(duration: 0.25)) {
                screenFlash = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) {
                badgeScale = 1.3
                badgeOpacity = 1
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                ringScale = 1.1
                ringOpacity = 1.0
                outerRingScale = 1.0
                outerRingOpacity = 0.6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            hapticTrigger += 1

            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                badgeScale = 0.9
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                badgeScale = 1.05
                ringScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.15)) {
                secondFlash = 0.2
            }
            confettiWave2 = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                badgeScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.2)) {
                secondFlash = 0
            }
            glowPulse = true
            badgeShadowRadius = 30
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                labelTagScale = 1.0
                labelTagOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            withAnimation(.linear(duration: 1.2)) {
                shimmerPhase = 300
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.4)) {
                subtitleOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                outerRingOpacity = 0.2
            }
            continuousShimmer = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                buttonOpacity = 1.0
            }
            hapticTrigger += 1
            phase = 6
        }
    }
}

nonisolated struct ConfettiPiece: Sendable {
    let id: Int
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let size: CGFloat
    let delay: Double
    let color: Color
    let shape: Int

    static func generateWave(count: Int, spread: CGFloat, yBias: CGFloat) -> [ConfettiPiece] {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.84, blue: 0.0),
            Color(red: 0.08, green: 0.39, blue: 1.0),
            Color(red: 1.0, green: 0.55, blue: 0.0),
            Color(red: 0.19, green: 0.82, blue: 0.35),
            Color(red: 0.9, green: 0.2, blue: 0.4),
            .white,
            AppTheme.purple,
            Color(red: 0.0, green: 0.85, blue: 0.9)
        ]
        return (0..<count).map { i in
            let angle = Double.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 80...spread)
            return ConfettiPiece(
                id: i,
                endX: cos(angle) * dist,
                endY: sin(angle) * dist + yBias,
                rotation: Double.random(in: -720...720),
                size: CGFloat.random(in: 4...12),
                delay: Double.random(in: 0...0.2),
                color: colors.randomElement()!,
                shape: Int.random(in: 0...2)
            )
        }
    }
}
