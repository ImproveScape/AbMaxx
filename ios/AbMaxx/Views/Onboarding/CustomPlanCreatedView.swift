import SwiftUI

struct CustomPlanCreatedView: View {
    let username: String
    let scanResult: ScanResult?
    let onContinue: () -> Void

    @State private var phase: Int = 0
    @State private var ringProgress: Double = 0
    @State private var reviewScrollOffset: CGFloat = 0

    private var score: Int { scanResult?.overallScore ?? 62 }

    private var currentTierIndex: Int {
        RankTier.currentTierIndex(for: score)
    }

    private var currentTier: RankTier {
        RankTier.allTiers[currentTierIndex]
    }

    private var regionMetrics: [(name: String, score: Int, icon: String)] {
        guard let s = scanResult else {
            return [
                ("Upper Abs", 65, "star.fill"),
                ("Lower Abs", 52, "chevron.down"),
                ("Obliques", 58, "plus"),
                ("Deep Core", 55, "circle.grid.2x2.fill")
            ]
        }
        return [
            ("Upper Abs", s.upperAbsScore, "star.fill"),
            ("Lower Abs", s.lowerAbsScore, "chevron.down"),
            ("Obliques", s.obliquesScore, "plus"),
            ("Deep Core", s.deepCoreScore, "circle.grid.2x2.fill")
        ]
    }

    private var extraMetrics: [(name: String, score: Int, icon: String)] {
        guard let s = scanResult else {
            return [
                ("Symmetry", 60, "arrow.left.arrow.right"),
                ("V Taper", 58, "chart.bar.fill")
            ]
        }
        return [
            ("Symmetry", s.symmetry, "arrow.left.arrow.right"),
            ("V Taper", s.frame, "chart.bar.fill")
        ]
    }

    private var allMetrics: [(name: String, score: Int, icon: String)] {
        regionMetrics + extraMetrics
    }

    private var lowestMetricName: String {
        allMetrics.min(by: { $0.score < $1.score })?.name ?? "Lower Abs"
    }

    private let reviews: [(name: String, text: String, imageUrl: String)] = [
        ("Luca Leighton", "My abs looked better than they ever have! This app making getting in shape so fun and simple. Would definitely recommend!", "https://r2-pub.rork.com/attachments/4hmwmqwasyxfm28uixzhu.jpg"),
        ("Anthony Aureliano", "Finally comfortable taking off my shirt at the beach ever since I started to AbMaxx", "https://r2-pub.rork.com/attachments/poyw0g4265wf1btqdlx24.jpg"),
        ("Antonio George", "Absolutely love this app. My abs have been looking insane lately and my bottom 2 abs are finally starting to come in. Cant wait to see what my abs are gonna look like in 5 weeks!", "https://r2-pub.rork.com/projects/ef37pg3laezo1t2hj7mt0/assets/6b727322-5397-4f3d-a42d-c1601cd9210e.png"),
        ("Lukz Mandel", "Literally a life changer. I struggled to get abs my entire life and it always felt impossible for me to have actual abs. Now random people are asking me what my Ab routine is. LOL", "https://r2-pub.rork.com/attachments/5w7fk2fm3wxzv0wlzhe0y.jpg")
    ]

    private let planItems: [(icon: String, label: String, value: String, accent: Color)] = [
        ("figure.core.training", "Workouts", "Personalized", Color(hex: "0A84FF")),
        ("fork.knife", "Nutrition", "Calorie-matched", Color(hex: "30D158")),
        ("camera.viewfinder", "Tracking", "AI scan-based", Color(hex: "BF5AF2")),
        ("chart.line.uptrend.xyaxis", "Analytics", "Real-time", Color(hex: "FF9F0A")),
    ]

    private let sources: [(label: String, url: String)] = [
        ("Journal of Clinical Nutrition", "https://ajcn.nutrition.org"),
        ("American Sports Medicine", "https://www.amssm.org"),
        ("National Abs Strength Association", "https://www.muscleandstrength.com/exercises/abs"),
        ("Harvard Sports Nutrition Society", "https://www.health.harvard.edu/diet-and-weight-loss/calories-burned-in-30-minutes-for-people-of-three-different-weights")
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        topBadge
                            .padding(.top, 32)

                        titleSection
                            .padding(.top, 20)

                        scoreBreakdownCard
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        planGrid
                            .padding(.top, 28)
                            .padding(.horizontal, 24)

                        projectionSection
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        reviewsCarousel
                            .padding(.top, 24)

                        sourcesSection
                            .padding(.top, 28)
                            .padding(.horizontal, 24)

                        Spacer().frame(height: 120)
                    }
                }
            }

            VStack {
                Spacer()
                ctaButton
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { runEntrance() }
    }

    private var topBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.success)
            Text("PLAN READY")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundStyle(AppTheme.success)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppTheme.success.opacity(0.1))
                .overlay(Capsule().strokeBorder(AppTheme.success.opacity(0.2), lineWidth: 1))
        )
        .opacity(phase >= 1 ? 1 : 0)
        .scaleEffect(phase >= 1 ? 1 : 0.8)
        .animation(.spring(duration: 0.5, bounce: 0.3), value: phase)
    }

    private var titleSection: some View {
        VStack(spacing: 4) {
            Text("\(username), your custom")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
            Text("abs plan is ready")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white.opacity(0.45))
        }
        .multilineTextAlignment(.center)
        .opacity(phase >= 1 ? 1 : 0)
        .offset(y: phase >= 1 ? 0 : 12)
        .animation(.spring(duration: 0.6).delay(0.1), value: phase)
    }

    // MARK: - Score Breakdown Card (matches BreakdownTabView)

    private var scoreBreakdownCard: some View {
        VStack(spacing: 10) {
            scoreHeroSection
            bodyFatRow
            zoneScoreGrid
            extraScoreGrid
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
        .opacity(phase >= 2 ? 1 : 0)
        .scaleEffect(phase >= 2 ? 1 : 0.95)
        .animation(.spring(duration: 0.6), value: phase)
    }

    private var scoreHeroSection: some View {
        let circleSize: CGFloat = 140
        let photoSize: CGFloat = circleSize - 12

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "1C1C2E").opacity(0.5))
                    .frame(width: circleSize + 8, height: circleSize + 8)

                Circle()
                    .stroke(AppTheme.muted.opacity(0.12), lineWidth: 3.5)
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(AppTheme.primaryAccent, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))

                if let photo = scanResult?.loadImage() {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: photoSize, height: photoSize)
                        .clipShape(Circle())
                        .allowsHitTesting(false)
                } else {
                    Circle()
                        .fill(AppTheme.card)
                        .frame(width: photoSize, height: photoSize)
                    Image(systemName: "figure.core.training")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(AppTheme.muted.opacity(0.5))
                }
            }
            .shadow(color: AppTheme.primaryAccent.opacity(0.18), radius: 40)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .blur(radius: 10)
                    .opacity(0.7)

                Text("OVERALL SCORE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(2)
            }
        }
        .padding(.top, 2)
    }

    private var bodyFatRow: some View {
        HStack(spacing: 0) {
            VStack(spacing: 3) {
                Text(scanResult?.absStructure.rawValue ?? "4-Pack")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .blur(radius: 8)
                    .opacity(0.7)
                Text("ABS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(2)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(AppTheme.cardBorder)
                .frame(width: 0.5, height: 32)

            VStack(spacing: 3) {
                Text(String(format: "%.0f%%", scanResult?.estimatedBodyFat ?? 17.0))
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .blur(radius: 8)
                    .opacity(0.7)
                Text("BODY FAT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(2)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Zone Score Grids (matching BreakdownTabView exactly)

    private var zoneScoreGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 8) {
            ForEach(regionMetrics, id: \.name) { metric in
                let isWeak = metric.name == lowestMetricName
                subscoreRow(name: metric.name, score: metric.score, isWeak: isWeak)
            }
        }
    }

    private var extraScoreGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 8) {
            ForEach(extraMetrics, id: \.name) { metric in
                subscoreRow(name: metric.name, score: metric.score, isWeak: false)
            }
        }
    }

    private func subscoreRow(name: String, score: Int, isWeak: Bool) -> some View {
        let isLowest = name == lowestMetricName
        let barColor = subscoreBarColor(for: score)

        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(name.uppercased())
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.3)
                    .lineLimit(1)

                if isWeak {
                    Circle()
                        .fill(AppTheme.destructive)
                        .frame(width: 6, height: 6)
                        .offset(y: -1)
                }

                Spacer()

                if isLowest {
                    Text("\(score)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(barColor)
                } else {
                    Text("\(score)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                        .blur(radius: 10)
                        .opacity(0.7)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.card)
                        .frame(height: 5)
                    Capsule()
                        .fill(isLowest ? barColor : Color.gray.opacity(0.3))
                        .frame(width: geo.size.width * Double(score) / 100.0, height: 5)
                }
            }
            .frame(height: 5)
        }
    }

    private func subscoreBarColor(for score: Int) -> Color {
        if score >= 85 { return AppTheme.success }
        if score >= 75 { return AppTheme.yellow }
        if score >= 65 { return AppTheme.caution }
        return AppTheme.destructive
    }

    // MARK: - Plan Grid

    private var planGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YOUR PLAN INCLUDES")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(AppTheme.secondaryText)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Array(planItems.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(item.accent)
                            .frame(width: 34, height: 34)
                            .background(item.accent.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 9))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.label)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                            Text(item.value)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.cardSurface)
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )
                }
            }
        }
        .opacity(phase >= 4 ? 1 : 0)
        .offset(y: phase >= 4 ? 0 : 16)
        .animation(.spring(duration: 0.5), value: phase)
    }

    // MARK: - Projection

    private var projectionSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Your projection")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            projectionChart
                .frame(height: 130)

            HStack(spacing: 20) {
                legendDot(color: AppTheme.primaryAccent, label: "With AbMaxx")
                legendDot(color: Color.white.opacity(0.2), label: "Without")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.cardSurface)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(AppTheme.border, lineWidth: 1))
        )
        .opacity(phase >= 5 ? 1 : 0)
        .offset(y: phase >= 5 ? 0 : 16)
        .animation(.spring(duration: 0.5), value: phase)
    }

    private var projectionChart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    let y = h - (h * CGFloat(i) / 3)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                }

                let withPoints: [(CGFloat, CGFloat)] = [
                    (0.0, 0.0), (0.25, 0.25), (0.5, 0.52), (0.75, 0.78), (1.0, 0.95)
                ]
                let withoutPoints: [(CGFloat, CGFloat)] = [
                    (0.0, 0.0), (0.25, 0.12), (0.5, 0.18), (0.75, 0.15), (1.0, 0.17)
                ]

                buildFillPath(points: withPoints, width: w, height: h)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent.opacity(0.15), AppTheme.primaryAccent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(
                        Rectangle()
                            .scaleEffect(x: phase >= 6 ? 1 : 0, anchor: .leading)
                            .animation(.easeOut(duration: 0.6), value: phase)
                    )

                buildCurvePath(points: withPoints, width: w, height: h)
                    .trim(from: 0, to: phase >= 6 ? 1 : 0)
                    .stroke(AppTheme.primaryAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .animation(.easeOut(duration: 0.6), value: phase)

                buildCurvePath(points: withoutPoints, width: w, height: h)
                    .trim(from: 0, to: phase >= 6 ? 1 : 0)
                    .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                    .animation(.easeOut(duration: 0.6), value: phase)

                let labels = ["Now", "Month 1", "Month 2", "Month 3"]
                ForEach(0..<4, id: \.self) { i in
                    let x = w * CGFloat(i) / 3
                    Text(labels[i])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .position(x: x, y: h + 14)
                }
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    // MARK: - Reviews Carousel

    private var reviewsCarousel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.3))
                    }
                }
                Text("4.9")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text("from 12K+ users")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
            }
            .padding(.horizontal, 24)

            AutoScrollingReviewsView(reviews: reviews)
                .frame(height: 120)
        }
        .opacity(phase >= 5 ? 1 : 0)
        .animation(.spring(duration: 0.5).delay(0.1), value: phase)
    }

    // MARK: - Sources

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Plan based on the following sources, among other peer-reviewed medical studies:")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(sources, id: \.label) { source in
                    Button {
                        if let url = URL(string: source.url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.primaryAccent)
                            Text(source.label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.primaryAccent)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }

                    if source.label != sources.last?.label {
                        Divider()
                            .background(Color.white.opacity(0.06))
                    }
                }
            }
            .padding(14)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppTheme.border, lineWidth: 1)
            )
        }
        .opacity(phase >= 6 ? 1 : 0)
        .animation(.spring(duration: 0.5), value: phase)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 8) {
                Text("Let's Get Started!")
                    .font(.system(size: 17, weight: .bold))
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
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.9), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .opacity(phase >= 4 ? 1 : 0)
        .offset(y: phase >= 4 ? 0 : 24)
        .animation(.spring(duration: 0.5), value: phase)
    }

    // MARK: - Path Builders

    private func buildCurvePath(points: [(CGFloat, CGFloat)], width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            for (i, pt) in points.enumerated() {
                let x = width * pt.0
                let y = height - height * pt.1
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    let prev = points[i - 1]
                    let px = width * prev.0
                    let py = height - height * prev.1
                    let cp1 = CGPoint(x: px + (x - px) * 0.4, y: py)
                    let cp2 = CGPoint(x: px + (x - px) * 0.6, y: y)
                    path.addCurve(to: CGPoint(x: x, y: y), control1: cp1, control2: cp2)
                }
            }
        }
    }

    private func buildFillPath(points: [(CGFloat, CGFloat)], width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            guard !points.isEmpty else { return }
            path.move(to: CGPoint(x: width * points[0].0, y: height))
            for (i, pt) in points.enumerated() {
                let x = width * pt.0
                let y = height - height * pt.1
                if i == 0 {
                    path.addLine(to: CGPoint(x: x, y: y))
                } else {
                    let prev = points[i - 1]
                    let px = width * prev.0
                    let py = height - height * prev.1
                    let cp1 = CGPoint(x: px + (x - px) * 0.4, y: py)
                    let cp2 = CGPoint(x: px + (x - px) * 0.6, y: y)
                    path.addCurve(to: CGPoint(x: x, y: y), control1: cp1, control2: cp2)
                }
            }
            if let last = points.last {
                path.addLine(to: CGPoint(x: width * last.0, y: height))
            }
            path.closeSubpath()
        }
    }

    // MARK: - Animation

    private func runEntrance() {
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation { phase = 1 }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation { phase = 2 }
            withAnimation(.spring(duration: 1.2, bounce: 0.1)) {
                ringProgress = Double(score) / 100.0
            }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation { phase = 3 }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation { phase = 4 }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation { phase = 5 }
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation { phase = 6 }
        }
    }
}

// MARK: - Auto-Scrolling Reviews

struct AutoScrollingReviewsView: View {
    let reviews: [(name: String, text: String, imageUrl: String)]

    @State private var scrollOffset: CGFloat = 0
    private let cardWidth: CGFloat = 260
    private let cardSpacing: CGFloat = 12
    private let speed: CGFloat = 30

    private var totalWidth: CGFloat {
        CGFloat(reviews.count) * (cardWidth + cardSpacing)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let offset = CGFloat(elapsed.truncatingRemainder(dividingBy: Double(totalWidth) / Double(speed))) * speed

            GeometryReader { geo in
                let visibleWidth = geo.size.width
                let repeats = Int(ceil((visibleWidth + totalWidth) / totalWidth)) + 1

                HStack(spacing: cardSpacing) {
                    ForEach(0..<repeats, id: \.self) { rep in
                        ForEach(Array(reviews.enumerated()), id: \.offset) { idx, review in
                            reviewCardCompact(name: review.name, text: review.text, imageUrl: review.imageUrl)
                                .frame(width: cardWidth)
                        }
                    }
                }
                .offset(x: -offset.truncatingRemainder(dividingBy: totalWidth))
            }
        }
    }

    private func reviewCardCompact(name: String, text: String, imageUrl: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                PreloadedImage(urlString: imageUrl, contentMode: .fill)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())

                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 1) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }

            Text(text)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(2)
                .lineLimit(3)
        }
        .padding(14)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }
}
