import SwiftUI

struct SubscoreBreakdownSelection: Identifiable {
    let name: String
    let score: Int
    let icon: String
    var id: String { name }
}

struct BreakdownTabView: View {
    let vm: AppViewModel
    @State private var selectedZone: AbRegion? = nil
    @State private var revealedSections: Int = 0
    @State private var animateRing: Bool = false
    @State private var selectedSubscoreBreakdown: SubscoreBreakdownSelection? = nil

    private var scan: ScanResult? {
        vm.scanResults.sorted { $0.date < $1.date }.last
    }

    private var upperAbs: Int { scan?.upperAbsScore ?? 0 }
    private var lowerAbs: Int { scan?.lowerAbsScore ?? 0 }
    private var obliques: Int { scan?.obliquesScore ?? 0 }
    private var deepCore: Int { scan?.deepCoreScore ?? 0 }

    private var weekNumber: Int {
        max(vm.scanResults.count, 1)
    }

    private var previousScan: ScanResult? {
        let sorted = vm.scanResults.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }
        return sorted[sorted.count - 2]
    }

    private var abMaxxScore: Int {
        scan?.overallScore ?? 0
    }

    private var currentTierIndex: Int {
        RankTier.currentTierIndex(for: abMaxxScore)
    }

    private var latestScanPhoto: UIImage? {
        guard let latestScan = scan, latestScan.hasPhoto else { return nil }
        return latestScan.loadImage()
    }

    private var regionMetrics: [(String, Int, String)] {
        guard let s = scan else {
            return [
                ("Upper Abs", 0, "star.fill"),
                ("Lower Abs", 0, "chevron.down"),
                ("Obliques", 0, "plus"),
                ("Deep Core", 0, "circle.grid.2x2.fill")
            ]
        }
        return [
            ("Upper Abs", s.upperAbsScore, "star.fill"),
            ("Lower Abs", s.lowerAbsScore, "chevron.down"),
            ("Obliques", s.obliquesScore, "plus"),
            ("Deep Core", s.deepCoreScore, "circle.grid.2x2.fill")
        ]
    }

    private var extraMetrics: [(String, Int, String)] {
        guard let s = scan else {
            return [
                ("Symmetry", 0, "arrow.left.arrow.right"),
                ("V Taper", 0, "chart.bar.fill")
            ]
        }
        return [
            ("Symmetry", s.symmetry, "arrow.left.arrow.right"),
            ("V Taper", s.frame, "chart.bar.fill")
        ]
    }

    private var weakZoneNames: Set<String> {
        let allZones = regionMetrics
        let sorted = allZones.sorted { $0.1 < $1.1 }
        return Set(sorted.prefix(2).map(\.0))
    }

    private func metricChange(for name: String) -> Int? {
        guard let prev = previousScan, let current = scan else { return nil }
        switch name {
        case "Symmetry":
            return current.symmetry - prev.symmetry
        case "V Taper":
            return current.frame - prev.frame
        default:
            guard let curVal = current.regions.first(where: { $0.0 == name })?.1,
                  let prevVal = prev.regions.first(where: { $0.0 == name })?.1 else { return nil }
            return curVal - prevVal
        }
    }

    private var weakestZone: AbRegion {
        let zones: [(AbRegion, Int)] = [
            (.upperAbs, upperAbs),
            (.lowerAbs, lowerAbs),
            (.obliques, obliques),
            (.deepCore, deepCore)
        ]
        return zones.min(by: { $0.1 < $1.1 })?.0 ?? .lowerAbs
    }

    private var strongestZone: AbRegion {
        let zones: [(AbRegion, Int)] = [
            (.upperAbs, upperAbs),
            (.lowerAbs, lowerAbs),
            (.obliques, obliques),
            (.deepCore, deepCore)
        ]
        return zones.max(by: { $0.1 < $1.1 })?.0 ?? .upperAbs
    }

    private var weakestScore: Int {
        [upperAbs, lowerAbs, obliques, deepCore].min() ?? 0
    }

    private func scoreForZone(_ zone: AbRegion) -> Int {
        switch zone {
        case .upperAbs: return upperAbs
        case .lowerAbs: return lowerAbs
        case .obliques: return obliques
        case .deepCore: return deepCore
        }
    }

    private var sortedZones: [(region: AbRegion, score: Int)] {
        let zones: [(region: AbRegion, score: Int)] = [
            (.upperAbs, upperAbs),
            (.lowerAbs, lowerAbs),
            (.obliques, obliques),
            (.deepCore, deepCore)
        ]
        return zones.sorted { $0.score > $1.score }
    }

    // MARK: - New Computed Properties

    private var allZonesData: [(name: String, score: Int)] {
        guard let s = scan else { return [] }
        return [
            ("Upper Abs", s.upperAbsScore),
            ("Lower Abs", s.lowerAbsScore),
            ("Obliques", s.obliquesScore),
            ("Deep Core", s.deepCoreScore),
            ("V-Taper", s.frame)
        ]
    }

    private var weakest: (name: String, score: Int) {
        allZonesData.min(by: { $0.score < $1.score }) ?? ("Lower Abs", 0)
    }

    private var strongest: (name: String, score: Int) {
        allZonesData.max(by: { $0.score < $1.score }) ?? ("Upper Abs", 0)
    }

    private var displayCeiling: Int {
        guard let s = scan else { return 85 }
        let motivatingFloor = s.overallScore + max(3, Int(Double(100 - s.overallScore) * 0.65))
        return min(98, max(motivatingFloor, s.geneticPotential))
    }

    private var potentialGap: Int {
        displayCeiling - abMaxxScore
    }

    private var potentialFill: CGFloat {
        guard displayCeiling > 0 else { return 0 }
        return CGFloat(abMaxxScore) / CGFloat(displayCeiling)
    }

    private var timelineParts: [String] {
        (scan?.visibilityTimeline ?? "")
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var timelineWeeks: String {
        let raw = timelineParts.first ?? "6 weeks"
        let digits = raw.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .filter { !$0.isEmpty }.first ?? "6"
        return digits
    }

    private var timelineTargetBF: String {
        timelineParts.dropFirst().first ?? "14%"
    }

    private var timelineAction: String {
        timelineParts.dropFirst(2).first ?? "Train your weakest zone consistently"
    }

    private var coachLines: [String] {
        Array((scan?.coachVerdict ?? "")
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .prefix(3))
    }

    private var coachFallback: [String] {
        [
            "Your upper abs show real development \u{2014} the muscle is building.",
            "\(weakest.name) is your gap \u{2014} it's why your midsection looks incomplete.",
            "Stay consistent this week \u{2014} your structure is already there."
        ]
    }

    private var displayCoachLines: [String] {
        coachLines.count >= 3 ? coachLines : coachFallback
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 10) {
                scoreHeroSection
                zoneScoreGrid
                extraScoreGrid
            }
            .padding(16)
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))

            if let s = scan {
                VStack(spacing: 10) {
                    swipeableVisualCard(s)
                    coachAnalysisCard(s)
                    absPotentialCard(s)
                    trainNowCard
                }
            } else {
                noScanCoachPlaceholder
            }
        }
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppTheme.primaryAccent)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.2)
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                revealedSections = 4
            }
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.spring(duration: 1.0, bounce: 0.15)) {
                    animateRing = true
                }
            }
        }
        .sheet(item: $selectedZone) { zone in
            ZoneExercisesSheet(
                zone: zone,
                score: scoreForZone(zone),
                isWeakZone: zone == weakestZone,
                weakestZoneScore: weakestScore,
                weekInfo: vm.zoneWeekInfo(for: zone),
                currentDayNumber: vm.programDayNumber
            )
        }
        .sheet(item: $selectedSubscoreBreakdown) { selection in
            SubscoreBreakdownFullView(
                zone: selection.name,
                score: selection.score,
                icon: selection.icon,
                scan: scan,
                vm: vm
            )
        }
    }

    // MARK: - Score Hero Section

    private var scoreHeroSection: some View {
        let score = abMaxxScore
        let ringProgress = animateRing ? Double(score) / 100.0 : 0
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
                    .animation(.spring(duration: 1.2, bounce: 0.1), value: ringProgress)

                if let photo = latestScanPhoto {
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
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.25), value: score)

                Text("OVERALL SCORE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(2)
            }

            if vm.profile.scanAbsStructure != nil || vm.profile.scanBodyFatEstimate != nil {
                HStack(spacing: 0) {
                    if let absStructure = vm.profile.scanAbsStructure {
                        VStack(spacing: 3) {
                            Text(absStructure)
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("ABS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .tracking(2)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if vm.profile.scanAbsStructure != nil && vm.profile.scanBodyFatEstimate != nil {
                        Rectangle()
                            .fill(AppTheme.cardBorder)
                            .frame(width: 0.5, height: 32)
                    }

                    if let bf = vm.profile.scanBodyFatEstimate {
                        VStack(spacing: 3) {
                            Text("\(String(format: "%.0f", bf))%")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("BODY FAT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .tracking(2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Zone Score Grid

    private var zoneScoreGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 8) {
            ForEach(regionMetrics, id: \.0) { metric in
                let isWeak = weakZoneNames.contains(metric.0)
                subscoreRow(metric: metric, isWeak: isWeak)
            }
        }
    }

    private var extraScoreGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 8) {
            ForEach(extraMetrics, id: \.0) { metric in
                subscoreRow(metric: metric, isWeak: false)
            }
        }
    }

    private func subscoreRow(metric: (String, Int, String), isWeak: Bool) -> some View {
        let barColor: Color = subscoreBarColor(for: metric.1)

        return Button {
            selectedSubscoreBreakdown = SubscoreBreakdownSelection(name: metric.0, score: metric.1, icon: metric.2)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(metric.0.uppercased())
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

                    Text("\(metric.1)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(subscoreBarColor(for: metric.1))
                        .contentTransition(.numericText())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.card)
                            .frame(height: 5)
                        Capsule()
                            .fill(barColor)
                            .frame(width: geo.size.width * Double(metric.1) / 100.0, height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: selectedSubscoreBreakdown?.name)
    }

    private func subscoreBarColor(for score: Int) -> Color {
        if score >= 85 {
            return AppTheme.success
        } else if score >= 75 {
            return AppTheme.yellow
        } else if score >= 65 {
            return AppTheme.caution
        } else {
            return AppTheme.destructive
        }
    }

    private var scoreGap: Int {
        max(scoreForZone(strongestZone) - scoreForZone(weakestZone), 0)
    }

    private func bfColor(_ bf: Double) -> Color {
        if bf <= 12 { return AppTheme.success }
        if bf <= 15 { return AppTheme.primaryAccent }
        if bf <= 20 { return AppTheme.caution }
        return AppTheme.destructive
    }

    // MARK: - Section 1: Abs Potential Card

    private func absPotentialCard(_ scan: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ABS POTENTIAL")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .tracking(3)
                .padding(.bottom, 14)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(scan.overallScore)")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("CURRENT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                        .tracking(2)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("+\(potentialGap)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                    Text("TO UNLOCK")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                        .tracking(1)
                }
                .padding(.bottom, 6)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(displayCeiling)")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(AppTheme.success)
                        .lineLimit(1)
                    Text("YOUR CEILING")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                        .tracking(2)
                }
            }

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .frame(maxWidth: .infinity)
                            .frame(height: 8)
                            .foregroundStyle(Color.white.opacity(0.08))

                        Capsule()
                            .frame(width: max(8, geometry.size.width * potentialFill), height: 8)
                            .foregroundStyle(AppTheme.primaryAccent)

                        Circle()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(.white)
                            .overlay(Circle().stroke(AppTheme.primaryAccent, lineWidth: 2))
                            .offset(x: max(0, geometry.size.width * potentialFill - 7))
                    }
                }
            }
            .frame(height: 14)
            .padding(.top, 12)

            HStack {
                Text("Week 1")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
                Spacer()
                Text("Genetic ceiling")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.success)
            }
            .padding(.top, 6)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
    }

    // MARK: - Section 2: Stats Row

    private func statsRow(_ scan: ScanResult) -> some View {
        HStack(spacing: 8) {
            statTile {
                Text(timelineWeeks)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(AppTheme.success)
                Text("WEEKS TO ABS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(1.5)
            }

            statTile {
                Text(timelineTargetBF)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("TARGET BF")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(1.5)
            }

            statTile {
                Text(weakest.name.uppercased().replacingOccurrences(of: " ", with: "\n"))
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AppTheme.destructive)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text("FOCUS ZONE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(1.5)
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
    }

    private func statTile<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 5) {
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Section 3: Swipeable Visual Card

    @State private var absAnalysisPage: Int = 0

    private func swipeableVisualCard(_ scan: ScanResult) -> some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("ABS ANALYSIS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(3)
                    .padding(.bottom, 10)

                TabView(selection: $absAnalysisPage) {
                    absMapPage(scan)
                        .tag(0)
                    radarChartPage(scan)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 280)
            }
            .padding(16)
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))

            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .fill(i == absAnalysisPage ? AppTheme.primaryAccent : Color.white.opacity(0.2))
                        .frame(width: 7, height: 7)
                        .animation(.easeInOut(duration: 0.2), value: absAnalysisPage)
                }
            }
        }
    }

    private func absMapPage(_ scan: ScanResult) -> some View {
        VStack(spacing: 8) {
            AnatomyScoreOverlayView(
                upperAbsScore: scan.upperAbsScore,
                lowerAbsScore: scan.lowerAbsScore,
                obliquesScore: scan.obliquesScore,
                vTaperScore: scan.frame,
                deepCoreScore: scan.deepCoreScore
            )
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            HStack(spacing: 0) {
                ForEach(allZonesData, id: \.name) { zone in
                    VStack(spacing: 3) {
                        Circle()
                            .fill(subscoreBarColor(for: zone.score))
                            .frame(width: 6, height: 6)
                        Text(String(zone.name.prefix(5)).uppercased())
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(AppTheme.muted)
                        Text("\(zone.score)")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(subscoreBarColor(for: zone.score))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 2)
        }
    }

    private var radarScores: [Int] {
        guard let s = scan else { return [0, 0, 0, 0, 0, 0] }
        return [s.upperAbsScore, s.lowerAbsScore, s.obliquesScore, s.deepCoreScore, s.symmetry, s.frame]
    }

    private var radarColors: [Color] {
        radarScores.map { subscoreBarColor(for: $0) }
    }

    private func radarChartPage(_ scan: ScanResult) -> some View {
        VStack(spacing: 10) {
            AbsRadarChartView(scores: radarScores, colors: radarColors)
                .frame(height: 240)

            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 7, height: 7)
                    Text("Your zones")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }

                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: 9, height: 9)
                        .foregroundStyle(.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        )
                    Text("Target 80")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }
        }
    }

    // MARK: - Section 4: Coach Analysis Card

    private func coachAnalysisCard(_ scan: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("COACH ANALYSIS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(3)

                Spacer()

                Text(scan.geneticPotentialLevel.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(AppTheme.primaryAccent.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.primaryAccent.opacity(0.4), lineWidth: 1))
            }
            .padding(.bottom, 14)

            ForEach(Array(displayCoachLines.enumerated()), id: \.offset) { index, line in
                VStack(spacing: 0) {
                    if index > 0 {
                        Divider()
                            .background(AppTheme.cardBorder)
                    }
                    HStack(alignment: .top, spacing: 11) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(AppTheme.primaryAccent)
                            .frame(width: 18, alignment: .leading)
                        Text(line)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 11)
                }
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
    }

    // MARK: - Section 5: Train Now Card

    private var trainNowCard: some View {
        Button {
            selectedZone = weakestZone
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Train \(weakest.name)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                    Text("Your weakest zone \u{2014} close the gap now")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    )
            }
            .padding(18)
            .background(AppTheme.primaryAccent)
            .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: selectedZone)
    }

    // MARK: - No Scan Placeholder

    private var noScanCoachPlaceholder: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(AppTheme.primaryAccent.opacity(0.5))
            }
            VStack(spacing: 6) {
                Text("Breakdown Locked")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Complete your first scan to see exactly what needs work and what to fix first.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

}
