import SwiftUI

struct ScaryTruthView: View {
    var onFinished: (() -> Void)? = nil
    @State private var currentPage: Int = 0
    @State private var phase: Int = 0
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding: Bool = false
    @State private var explosionTriggered: Bool = false
    @State private var displayNumber: Int = 0
    @State private var glowPulse: Bool = false
    @State private var screenShake: CGFloat = 0
    @State private var screenShakeY: CGFloat = 0
    @State private var whiteFlash: Double = 0
    @State private var contentOpacity: Double = 1
    @State private var holdPulse: Bool = false
    @State private var bgColor: Color = Color(red: 0.78, green: 0.06, blue: 0.06)

    private let totalPages = 4
    private let scaryRed = Color(red: 0.78, green: 0.06, blue: 0.06)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if explosionTriggered {
                AppTheme.background.ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentPage ? Color.white : Color.white.opacity(0.15))
                            .frame(height: 3)
                            .animation(.spring(duration: 0.4), value: currentPage)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                Group {
                    switch currentPage {
                    case 0: trapPage
                    case 1: cyclePage
                    case 2: statPage
                    case 3: breakPage
                    default: EmptyView()
                    }
                }
                .id(currentPage)
                .opacity(contentOpacity)

                Spacer()

                if currentPage < 3 {
                    Button {
                        advancePage()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.system(size: 17, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.12))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .opacity(phase >= 3 ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: phase)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }

                if currentPage == 3 {
                    breakCycleButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 50)
                        .opacity(contentOpacity)
                }
            }
            .offset(x: screenShake, y: screenShakeY)

            if explosionTriggered {
                ShatterTransitionView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            Color.white.opacity(whiteFlash)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: currentPage)
        .task(id: currentPage) { animatePhases() }
    }

    private var trapPage: some View {
        VStack(spacing: 32) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 12)
                .opacity(phase >= 1 ? 1 : 0)
                .scaleEffect(phase >= 1 ? 1 : 0.5)
                .animation(.spring(duration: 0.5, bounce: 0.15), value: phase)

            VStack(spacing: 14) {
                Text("You're trapped in")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                +
                Text("\na losing cycle.")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .opacity(phase >= 2 ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: phase)

            Text("Processed food rewires your brain's reward system.\nThe more you eat, the more you crave.\nIt's not willpower — it's chemistry.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(phase >= 3 ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: phase)

            if phase >= 3 {
                HStack(spacing: 16) {
                    statPill(value: "8x", label: "more addictive\nthan cocaine", icon: "bolt.fill")
                    statPill(value: "73%", label: "of daily calories\nare processed", icon: "chart.bar.fill")
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
    }

    private var cyclePage: some View {
        VStack(spacing: 32) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 12)
                .opacity(phase >= 1 ? 1 : 0)
                .scaleEffect(phase >= 1 ? 1 : 0.5)
                .animation(.spring(duration: 0.5, bounce: 0.15), value: phase)

            VStack(spacing: 14) {
                Text("One binge")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                +
                Text("\nresets everything.")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .opacity(phase >= 2 ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: phase)

            Text("Restrict. Crave. Binge. Repeat.\nYour brain demands more every time.\nThe fat stays. The guilt compounds.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(phase >= 3 ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: phase)

            if phase >= 3 {
                HStack(spacing: 16) {
                    statPill(value: "95%", label: "of diets fail\nwithin 1 year", icon: "chart.line.downtrend.xyaxis")
                    statPill(value: "3.6x", label: "more likely to\nbinge after restricting", icon: "arrow.uturn.backward")
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
    }

    private var statPage: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)

            ZStack {
                Text("\(displayNumber)%")
                    .font(.system(size: 140, weight: .black, design: .default))
                    .foregroundStyle(.white.opacity(0.06))
                    .scaleEffect(glowPulse ? 1.15 : 1.1)
                    .blur(radius: 20)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowPulse)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(displayNumber)")
                        .font(.system(size: 130, weight: .black, design: .default))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.04), value: displayNumber)

                    Text("%")
                        .font(.system(size: 56, weight: .black, design: .default))
                        .foregroundStyle(.white.opacity(0.6))
                        .offset(y: -8)
                }
                .shadow(color: .white.opacity(glowPulse ? 0.3 : 0), radius: glowPulse ? 30 : 0)
                .shadow(color: scaryRed.opacity(0.8), radius: 40)
            }
            .opacity(phase >= 1 ? 1 : 0)
            .scaleEffect(phase >= 1 ? 1 : 0.3)
            .animation(.spring(duration: 0.6, bounce: 0.15), value: phase >= 1)

            Text("of men will never\nhave visible abs.")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .opacity(phase >= 2 ? 1 : 0)
                .offset(y: phase >= 2 ? 0 : 12)
                .animation(.easeOut(duration: 0.5), value: phase)

            Text("You're more likely to become a millionaire\nthan to ever get a six-pack.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(phase >= 2 ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: phase)

            if phase >= 3 {
                HStack(spacing: 0) {
                    miniStat(value: "2%", label: "Will make it")
                    miniStatDivider
                    miniStat(value: "67%", label: "Are overweight")
                    miniStatDivider
                    miniStat(value: "0.1%", label: "Have a 6-pack")
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.2))
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
    }

    private var breakPage: some View {
        VStack(spacing: 32) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 12)
                .opacity(phase >= 1 ? 1 : 0)
                .scaleEffect(phase >= 1 ? 1 : 0.5)
                .animation(.spring(duration: 0.5, bounce: 0.15), value: phase)

            VStack(spacing: 12) {
                Text("Your real body")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)

                Text("is buried underneath.")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .opacity(phase >= 2 ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: phase)

            Text("Under that layer is a physique\nyou'd actually be proud of.\nEvery day you wait, the cycle wins.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(phase >= 3 ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: phase)
        }
        .padding(.horizontal, 28)
    }

    private var breakCycleButton: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.15))
                    .frame(height: 60)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15 + holdProgress * 0.25),
                                        Color.white.opacity(0.08 + holdProgress * 0.35)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * holdProgress, height: 60)

                        if holdProgress > 0.1 {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(holdPulse ? 0.08 : 0))
                                .frame(width: geo.size.width * holdProgress, height: 60)
                        }
                    }
                }
                .frame(height: 60)
                .clipShape(.rect(cornerRadius: 16))

                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color.white.opacity(holdProgress > 0 ? 0.3 + holdProgress * 0.4 : 0.15),
                        lineWidth: holdProgress > 0.8 ? 2 : 1
                    )
                    .frame(height: 60)

                HStack(spacing: 10) {
                    if holdProgress < 1 {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .symbolEffect(.pulse, isActive: holdProgress > 0)
                        Text("Hold to Break Free")
                            .font(.system(size: 17, weight: .bold))
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
            }
            .scaleEffect(1.0 + holdProgress * 0.03)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHolding && !explosionTriggered {
                            isHolding = true
                            startHoldTimer()
                        }
                    }
                    .onEnded { _ in
                        if !explosionTriggered {
                            isHolding = false
                            holdPulse = false
                            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                                holdProgress = 0
                            }
                        }
                    }
            )
            .opacity(phase >= 3 ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: phase)

            Text("HOLD UNTIL IT BREAKS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(3)
                .opacity(phase >= 3 && holdProgress == 0 ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.2), value: phase)
        }
    }

    private func statPill(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.12))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var miniStatDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 36)
    }

    private func advancePage() {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentPage += 1
            phase = 0
        }
        animatePhases()
    }

    private func animatePhases() {
        Task {
            if currentPage == 2 {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { phase = 1 }
                animateCounter()
                try? await Task.sleep(for: .milliseconds(1200))
                withAnimation { phase = 2 }
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
                try? await Task.sleep(for: .seconds(1.0))
                withAnimation(.spring(duration: 0.5)) { phase = 3 }
            } else {
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.easeOut(duration: 0.4)) { phase = 1 }
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation(.easeOut(duration: 0.4)) { phase = 2 }
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.easeOut(duration: 0.4)) { phase = 3 }
            }
        }
    }

    private func animateCounter() {
        Task {
            for i in stride(from: 0, through: 98, by: 2) {
                displayNumber = i
                try? await Task.sleep(for: .milliseconds(18))
            }
            displayNumber = 98
        }
    }

    private func startHoldTimer() {
        Task {
            let totalDuration: Double = 2.0
            let fps: Double = 60
            let totalFrames = Int(totalDuration * fps)
            let frameInterval = 1000.0 / fps

            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                holdPulse = true
            }

            for frame in 1...totalFrames {
                guard isHolding else { return }
                let progress = CGFloat(frame) / CGFloat(totalFrames)
                let eased = progress < 0.5
                    ? 2 * progress * progress
                    : 1 - pow(-2 * progress + 2, 2) / 2

                withAnimation(.linear(duration: frameInterval / 1000)) {
                    holdProgress = eased
                }

                let shakeIntensity = eased * eased * 6
                let shakeFrequency: Int = eased < 0.3 ? 12 : (eased < 0.7 ? 6 : 3)

                if frame % shakeFrequency == 0 && shakeIntensity > 0.5 {
                    let xShake = CGFloat.random(in: -shakeIntensity...shakeIntensity)
                    let yShake = CGFloat.random(in: -shakeIntensity * 0.5...shakeIntensity * 0.5)
                    withAnimation(.linear(duration: 0.03)) {
                        screenShake = xShake
                        screenShakeY = yShake
                    }
                    Task {
                        try? await Task.sleep(for: .milliseconds(30))
                        withAnimation(.linear(duration: 0.03)) {
                            screenShake = 0
                            screenShakeY = 0
                        }
                    }
                }

                try? await Task.sleep(for: .milliseconds(Int(frameInterval)))
            }

            guard isHolding else { return }
            explosionTriggered = true
            triggerExplosion()
        }
    }

    private func triggerExplosion() {
        Task {
            holdPulse = false

            rapidShake(intensity: 20, count: 8, interval: 6)
            try? await Task.sleep(for: .milliseconds(20))

            withAnimation(.linear(duration: 0.02)) { whiteFlash = 0.9 }

            withAnimation(.easeOut(duration: 0.1)) {
                contentOpacity = 0
                bgColor = .black
            }

            try? await Task.sleep(for: .milliseconds(40))
            rapidShake(intensity: 30, count: 14, interval: 6)

            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeOut(duration: 0.08)) { whiteFlash = 0.5 }
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(.linear(duration: 0.03)) { whiteFlash = 0.7 }
            try? await Task.sleep(for: .milliseconds(30))

            rapidShake(intensity: 15, count: 10, interval: 10)

            withAnimation(.easeOut(duration: 0.4)) { whiteFlash = 0.05 }
            try? await Task.sleep(for: .milliseconds(200))

            rapidShake(intensity: 5, count: 6, interval: 20)

            withAnimation(.easeOut(duration: 0.8)) { whiteFlash = 0 }

            screenShake = 0
            screenShakeY = 0

            try? await Task.sleep(for: .milliseconds(1800))
            onFinished?()
        }
    }

    private func rapidShake(intensity: CGFloat, count: Int, interval: Int) {
        Task {
            for _ in 0..<count {
                let x = CGFloat.random(in: -intensity...intensity)
                let y = CGFloat.random(in: -intensity * 0.4...intensity * 0.4)
                withAnimation(.linear(duration: Double(interval) / 1000)) {
                    screenShake = x
                    screenShakeY = y
                }
                try? await Task.sleep(for: .milliseconds(interval))
            }
            withAnimation(.linear(duration: 0.02)) {
                screenShake = 0
                screenShakeY = 0
            }
        }
    }
}

struct ShatterTransitionView: View {
    @State private var startTime: Date = .now
    @State private var particles: [ExplosionParticle] = []
    @State private var sparks: [Spark] = []
    @State private var impactFlash: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                    let t = timeline.date.timeIntervalSince(startTime)

                    Canvas { ctx, size in
                        let cx = size.width / 2
                        let cy = size.height * 0.45

                        drawCoreFlash(ctx: &ctx, cx: cx, cy: cy, t: t)
                        drawParticles(ctx: &ctx, size: size, cx: cx, cy: cy, t: t)
                        drawSparks(ctx: &ctx, size: size, cx: cx, cy: cy, t: t)
                        drawFadeOut(ctx: &ctx, size: size, t: t)
                    }
                }

                Color.white
                    .opacity(Double(impactFlash))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .onAppear {
                buildScene(size: geo.size)
                startTime = .now
                fireFlash()
            }
        }
    }

    private func drawCoreFlash(ctx: inout GraphicsContext, cx: CGFloat, cy: CGFloat, t: Double) {
        guard t < 0.5 else { return }
        let intensity: Double = t < 0.04 ? t / 0.04 : max(0, 1.0 - (t - 0.04) / 0.46)
        guard intensity > 0.01 else { return }

        let r: CGFloat = 20 + CGFloat(t) * 600
        let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
        var c = ctx
        c.addFilter(.blur(radius: 40))
        c.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [
                .white.opacity(intensity),
                Color(red: 1, green: 0.3, blue: 0.1).opacity(intensity * 0.5),
                .clear
            ]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r
        ))
    }

    private func drawParticles(ctx: inout GraphicsContext, size: CGSize, cx: CGFloat, cy: CGFloat, t: Double) {
        let start: Double = 0.02
        guard t > start else { return }
        let st = t - start

        for p in particles {
            guard st > p.delay else { continue }
            let lt = st - p.delay
            let drag = exp(-p.drag * lt)
            let px = cx + p.vx * CGFloat(lt) * CGFloat(drag)
            let py = cy + p.vy * CGFloat(lt) * CGFloat(drag) + p.gravity * CGFloat(lt * lt)

            guard px > -50 && px < size.width + 50 && py > -50 && py < size.height + 50 else { continue }

            let life = lt / p.life
            guard life < 1.0 else { continue }

            let fadeIn: Double = life < 0.05 ? life / 0.05 : 1.0
            let fadeOut = pow(1.0 - life, 2.0)
            let alpha = fadeIn * fadeOut * p.opacity
            guard alpha > 0.005 else { continue }

            let sz = p.size * CGFloat(1.0 - life * 0.5)
            let rect = CGRect(x: px - sz, y: py - sz, width: sz * 2, height: sz * 2)

            var c = ctx
            c.opacity = alpha

            let hue = p.hue
            let colors: [Color]
            if hue < 0.15 {
                colors = [.white, Color(red: 1, green: 0.85, blue: 0.6).opacity(0.6), .clear]
            } else if hue < 0.4 {
                colors = [Color(red: 1, green: 0.6, blue: 0.2), Color(red: 1, green: 0.3, blue: 0.05).opacity(0.5), .clear]
            } else {
                colors = [Color(red: 1, green: 0.25, blue: 0.05), Color(red: 0.8, green: 0.1, blue: 0).opacity(0.4), .clear]
            }

            c.fill(Path(ellipseIn: rect), with: .radialGradient(
                Gradient(colors: colors),
                center: CGPoint(x: px, y: py), startRadius: 0, endRadius: sz
            ))
        }
    }

    private func drawSparks(ctx: inout GraphicsContext, size: CGSize, cx: CGFloat, cy: CGFloat, t: Double) {
        for s in sparks {
            guard t > s.delay else { continue }
            let lt = t - s.delay
            let drag = exp(-1.5 * lt)
            let px = cx + s.vx * CGFloat(lt) * CGFloat(drag)
            let py = cy + s.vy * CGFloat(lt) * CGFloat(drag) + 300 * CGFloat(lt * lt)

            guard px > -20 && px < size.width + 20 && py > -20 && py < size.height + 20 else { continue }

            let life = lt / s.life
            guard life < 1.0 else { continue }

            let flick = (1.0 + 0.5 * sin(lt * s.flicker))
            let alpha = (1.0 - life) * min(1.0, flick) * s.opacity
            guard alpha > 0.01 else { continue }

            let sz = s.size * CGFloat(max(0.2, 1.0 - life))
            let rect = CGRect(x: px - sz, y: py - sz, width: sz * 2, height: sz * 2)

            var c = ctx
            c.opacity = alpha
            c.fill(Path(ellipseIn: rect), with: .radialGradient(
                Gradient(colors: [.white, Color(red: 1, green: 0.7, blue: 0.3).opacity(0.4), .clear]),
                center: CGPoint(x: px, y: py), startRadius: 0, endRadius: sz
            ))
        }
    }

    private func drawFadeOut(ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let fadeStart: Double = 1.2
        guard t > fadeStart else { return }
        let progress = min(1.0, (t - fadeStart) / 0.6)
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(progress * progress)))
    }

    private func fireFlash() {
        Task {
            withAnimation(.linear(duration: 0.03)) { impactFlash = 1.0 }
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(.linear(duration: 0.04)) { impactFlash = 0.3 }
            try? await Task.sleep(for: .milliseconds(40))
            withAnimation(.linear(duration: 0.03)) { impactFlash = 0.7 }
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(.easeOut(duration: 0.2)) { impactFlash = 0 }
        }
    }

    private func buildScene(size: CGSize) {
        var p: [ExplosionParticle] = []
        let totalParticles = 400

        for i in 0..<totalParticles {
            let angle = Double.random(in: 0...(.pi * 2))
            let speedBase: CGFloat
            let sizeVal: CGFloat
            let lifeVal: Double
            let dragVal: Double
            let gravVal: CGFloat
            let delayVal: Double

            if i < 60 {
                speedBase = .random(in: 600...1400)
                sizeVal = .random(in: 1.5...3.5)
                lifeVal = .random(in: 0.6...1.4)
                dragVal = .random(in: 0.8...1.5)
                gravVal = .random(in: 100...400)
                delayVal = .random(in: 0...0.02)
            } else if i < 180 {
                speedBase = .random(in: 300...900)
                sizeVal = .random(in: 1.0...2.5)
                lifeVal = .random(in: 0.8...1.8)
                dragVal = .random(in: 1.0...2.0)
                gravVal = .random(in: 150...500)
                delayVal = .random(in: 0...0.05)
            } else {
                speedBase = .random(in: 100...500)
                sizeVal = .random(in: 0.5...1.8)
                lifeVal = .random(in: 1.0...2.5)
                dragVal = .random(in: 1.2...2.5)
                gravVal = .random(in: 200...600)
                delayVal = .random(in: 0...0.08)
            }

            let spread = angle + Double.random(in: -0.2...0.2)
            p.append(ExplosionParticle(
                id: i,
                vx: cos(spread) * speedBase,
                vy: sin(spread) * speedBase - .random(in: 100...300),
                size: sizeVal,
                life: lifeVal,
                delay: delayVal,
                opacity: .random(in: 0.5...1.0),
                hue: Double.random(in: 0...0.6),
                drag: dragVal,
                gravity: gravVal
            ))
        }
        particles = p

        var s: [Spark] = []
        let totalSparks = 200
        for i in 0..<totalSparks {
            let angle = Double.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: 200...1600)
            s.append(Spark(
                id: i,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed - .random(in: 50...200),
                size: .random(in: 0.8...2.5),
                life: .random(in: 0.3...1.2),
                delay: .random(in: 0...0.04),
                opacity: .random(in: 0.6...1.0),
                flicker: .random(in: 30...90)
            ))
        }
        sparks = s
    }
}

nonisolated struct ExplosionParticle: Identifiable, Sendable {
    let id: Int
    let vx: CGFloat
    let vy: CGFloat
    let size: CGFloat
    let life: Double
    let delay: Double
    let opacity: Double
    let hue: Double
    let drag: Double
    let gravity: CGFloat
}

nonisolated struct Spark: Identifiable, Sendable {
    let id: Int
    let vx: CGFloat
    let vy: CGFloat
    let size: CGFloat
    let life: Double
    let delay: Double
    let opacity: Double
    let flicker: Double
}
