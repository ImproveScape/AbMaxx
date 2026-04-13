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

    var body: some View {
        VStack(spacing: 16) {
            scoreHeroSection
            zoneScoreGrid
            extraScoreGrid
            scanDiagnosticCard
            zoneRankingList
            verdictCard
            priorityFixCard
        }
        .onAppear {
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

    // MARK: - Score Hero

    private var scoreHeroSection: some View {
        let score = abMaxxScore
        let ringProgress = animateRing ? Double(score) / 100.0 : 0
        let currentTier = RankTier.allTiers[currentTierIndex]
        let circleSize: CGFloat = 140
        let photoSize: CGFloat = circleSize - 10

        return VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 6)
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [currentTier.color1, currentTier.color2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
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
                        .fill(
                            RadialGradient(
                                colors: [currentTier.color1.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 90
                            )
                        )
                        .frame(width: photoSize, height: photoSize)
                    Image(systemName: "figure.core.training")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(AppTheme.muted.opacity(0.4))
                }
            }
            .shadow(color: currentTier.color1.opacity(0.15), radius: 24)

            VStack(spacing: 3) {
                Text("\(score)")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.25), value: score)

                Text("OVERALL SCORE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(AppTheme.muted)
            }

            if vm.profile.scanAbsStructure != nil || vm.profile.scanBodyFatEstimate != nil {
                HStack(spacing: 0) {
                    if let absStructure = vm.profile.scanAbsStructure {
                        VStack(spacing: 3) {
                            Text(absStructure)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                            Text("ABS")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(AppTheme.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if vm.profile.scanAbsStructure != nil && vm.profile.scanBodyFatEstimate != nil {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 1, height: 22)
                    }

                    if let bf = vm.profile.scanBodyFatEstimate {
                        VStack(spacing: 3) {
                            Text("\(String(format: "%.0f", bf))%")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                            Text("BODY FAT")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(AppTheme.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Zone Score Grid

    private var zoneScoreGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
            ForEach(regionMetrics, id: \.0) { metric in
                let isWeak = weakZoneNames.contains(metric.0)
                let change = metricChange(for: metric.0)
                subscoreCard(metric: metric, isWeak: isWeak, change: change)
            }
        }
    }

    private var extraScoreGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
            ForEach(extraMetrics, id: \.0) { metric in
                let change = metricChange(for: metric.0)
                subscoreCard(metric: metric, isWeak: false, change: change)
            }
        }
    }

    private func subscoreCard(metric: (String, Int, String), isWeak: Bool, change: Int?) -> some View {
        let barColor: Color = isWeak ? AppTheme.destructive : subscoreBarColor(for: metric.1)

        return Button {
            selectedSubscoreBreakdown = SubscoreBreakdownSelection(name: metric.0, score: metric.1, icon: metric.2)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: metric.2)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(barColor)
                    Text(metric.0)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 2)
                    if isWeak {
                        Text("WEAK")
                            .font(.system(size: 8, weight: .heavy))
                            .tracking(0.5)
                            .foregroundStyle(AppTheme.destructive)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(metric.1)")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    if let change = change, change != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 8, weight: .black))
                            Text(change > 0 ? "+\(change)" : "\(change)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(change > 0 ? AppTheme.success : AppTheme.destructive)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.04))
                            .frame(height: 3)
                        Capsule()
                            .fill(barColor)
                            .frame(width: geo.size.width * Double(metric.1) / 100.0, height: 3)
                    }
                }
                .frame(height: 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: selectedSubscoreBreakdown?.name)
    }

    private func subscoreBarColor(for score: Int) -> Color {
        if score >= 75 { return AppTheme.success }
        if score >= 60 { return AppTheme.primaryAccent }
        return AppTheme.warning
    }

    // MARK: - Scan Diagnostic

    private var scanDiagnosticCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("SCAN ANALYSIS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(2)
                Spacer()
                Text("Week \(weekNumber)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }

            Text(diagnosticHeadline)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(diagnosticSubline)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.primaryAccent.opacity(0.15), lineWidth: 1)
        )
        .opacity(revealedSections >= 1 ? 1 : 0)
        .offset(y: revealedSections >= 1 ? 0 : 12)
    }

    private var diagnosticHeadline: String {
        guard scan != nil else { return "No scan data yet" }
        let strong = strongestZone.rawValue
        let weak = weakestZone.rawValue
        if weakestScore >= 75 {
            return "All zones firing. \(strong) is leading."
        }
        return "\(weak) is holding you back."
    }

    private var diagnosticSubline: String {
        guard scan != nil else { return "Complete a scan to get your personalized breakdown." }
        let gap = scoreForZone(strongestZone) - scoreForZone(weakestZone)
        if gap <= 5 {
            return "Your development is balanced — focus on overall definition now."
        }
        return "\(gap)-point gap between \(strongestZone.rawValue) and \(weakestZone.rawValue). That's where your next visual jump is."
    }

    // MARK: - Zone Ranking List

    private var zoneRankingList: some View {
        VStack(spacing: 8) {
            ForEach(sortedZones, id: \.region) { zone in
                Button {
                    selectedZone = zone.region
                } label: {
                    zoneRow(region: zone.region, score: zone.score)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .light), trigger: selectedZone)
            }
        }
        .opacity(revealedSections >= 2 ? 1 : 0)
        .offset(y: revealedSections >= 2 ? 0 : 12)
    }

    private func zoneRow(region: AbRegion, score: Int) -> some View {
        let isWeak = region == weakestZone
        let isStrong = region == strongestZone
        let statusText = muscleStatus(score: score, isWeak: isWeak, isStrong: isStrong)
        let accentColor = muscleAccent(score: score, isWeak: isWeak)

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: region.icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(region.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(statusText)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(accentColor)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.04))
                            .frame(height: 3)
                        Capsule()
                            .fill(accentColor)
                            .frame(width: geo.size.width * Double(score) / 100.0, height: 3)
                    }
                }
                .frame(height: 3)
            }

            Text("\(score)")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(accentColor)
                .frame(width: 32, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    private func muscleStatus(score: Int, isWeak: Bool, isStrong: Bool) -> String {
        if isWeak && score < 60 { return "Needs Work" }
        if isWeak { return "Weakest" }
        if isStrong && score >= 75 { return "Strongest" }
        if score >= 75 { return "Defined" }
        if score >= 60 { return "Developing" }
        return "Underdeveloped"
    }

    private func muscleAccent(score: Int, isWeak: Bool) -> Color {
        if isWeak { return AppTheme.destructive }
        if score >= 75 { return AppTheme.success }
        if score >= 60 { return AppTheme.primaryAccent }
        return AppTheme.warning
    }

    // MARK: - Verdict Card

    private var verdictCard: some View {
        guard let s = scan else {
            return AnyView(
                VStack(spacing: 16) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(AppTheme.primaryAccent.opacity(0.4))
                    VStack(spacing: 4) {
                        Text("Your Body Read")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Complete your first scan to unlock your full breakdown.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(AppTheme.border, lineWidth: 1))
                .opacity(revealedSections >= 3 ? 1 : 0)
                .offset(y: revealedSections >= 3 ? 0 : 12)
            )
        }

        let strongName = strongestZone.rawValue
        let weakName = weakestZone.rawValue
        let strongScore = scoreForZone(strongestZone)
        let weakScore = scoreForZone(weakestZone)
        let gap = strongScore - weakScore
        let bf = s.estimatedBodyFat
        let bfCategory = s.bodyFatCategory
        let aiText = s.coachVerdict
        let overall = abMaxxScore

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verdictHeadline(overall: overall, bf: bf, weakScore: weakScore))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Here's what we found in your scan.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer(minLength: 12)
                    ZStack {
                        Circle()
                            .fill(verdictHeaderColor(overall).opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: verdictHeaderIcon(overall))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(verdictHeaderColor(overall))
                    }
                }
                .padding(.bottom, 20)

                verdictFinding(
                    number: "01",
                    accent: AppTheme.success,
                    headline: "\(strongName) is leading",
                    body: strongZoneBody(strongName, strongScore),
                    stat: "\(strongScore)",
                    statLabel: "SCORE"
                )

                verdictFinding(
                    number: "02",
                    accent: AppTheme.destructive,
                    headline: "\(weakName) needs attention",
                    body: weakZoneBody(weakName, weakScore),
                    stat: "\(weakScore)",
                    statLabel: "SCORE"
                )

                verdictFinding(
                    number: "03",
                    accent: AppTheme.warning,
                    headline: gapHeadline(gap, weakName),
                    body: gapBody(gap, weakName, strongName),
                    stat: "\(gap)pt",
                    statLabel: "GAP"
                )

                verdictFinding(
                    number: "04",
                    accent: bfColor(bf),
                    headline: bfHeadline(bf, bfCategory),
                    body: bfBody(bf),
                    stat: String(format: "%.0f%%", bf),
                    statLabel: "BF"
                )

                if let structure = s.breakdownStructureNote, !structure.isEmpty {
                    verdictFinding(
                        number: "05",
                        accent: AppTheme.primaryAccent,
                        headline: "\(s.absStructure.rawValue) abs with \(s.insertionType.lowercased()) insertions",
                        body: structure,
                        stat: nil,
                        statLabel: nil
                    )
                }

                if let text = aiText, !text.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Rectangle()
                            .fill(Color.white.opacity(0.04))
                            .frame(height: 1)
                            .padding(.top, 4)

                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AppTheme.primaryAccent)
                            Text("DEEP ANALYSIS")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(AppTheme.primaryAccent)
                                .tracking(2)
                        }

                        Text(text.replacingOccurrences(of: "**", with: ""))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 1)
                    .padding(.top, 16)

                Text(verdictBottomLine(overall: overall, weakName: weakName, bf: bf))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            .padding(18)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(AppTheme.primaryAccent.opacity(0.15), lineWidth: 1)
            )
            .opacity(revealedSections >= 3 ? 1 : 0)
            .offset(y: revealedSections >= 3 ? 0 : 12)
        )
    }

    private func verdictFinding(number: String, accent: Color, headline: String, body: String, stat: String?, statLabel: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text(number)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(accent)
                    .frame(width: 24, height: 24)
                    .background(accent.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 6))

                Rectangle()
                    .fill(accent.opacity(0.1))
                    .frame(width: 1)
                    .frame(minHeight: 24)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(headline)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if let stat = stat, let statLabel = statLabel {
                        VStack(spacing: 1) {
                            Text(stat)
                                .font(.system(size: 16, weight: .black))
                                .foregroundStyle(accent)
                            Text(statLabel)
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(accent.opacity(0.5))
                                .tracking(0.5)
                        }
                    }
                }

                Text(body)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)
            }
        }
    }

    private func verdictHeadline(overall: Int, bf: Double, weakScore: Int) -> String {
        if overall >= 80 && bf <= 14 { return "You're in the top tier. Here's what separates you from elite." }
        if overall >= 65 { return "You've got real muscle showing. But there's a gap holding you back." }
        if overall >= 50 { return "The foundation is there. Here's exactly what's hiding it." }
        return "We see what's underneath. Here's the honest read."
    }

    private func verdictHeaderIcon(_ overall: Int) -> String {
        if overall >= 80 { return "bolt.fill" }
        if overall >= 65 { return "eye.fill" }
        if overall >= 50 { return "magnifyingglass" }
        return "scope"
    }

    private func verdictHeaderColor(_ overall: Int) -> Color {
        if overall >= 80 { return AppTheme.success }
        if overall >= 65 { return AppTheme.primaryAccent }
        if overall >= 50 { return AppTheme.warning }
        return AppTheme.destructive
    }

    private func strongZoneBody(_ name: String, _ score: Int) -> String {
        if score >= 80 {
            return "You can see actual muscle separation in your \(name.lowercased()) right now. That's not common — most people never get here. The fibers are visible and the definition is real."
        }
        if score >= 65 {
            return "Your \(name.lowercased()) is where people's eyes go first when they look at your midsection. The muscle bellies are forming and starting to push through the skin. This is your money zone."
        }
        return "Even though it's your strongest area, your \(name.lowercased()) still has a lot of untapped potential. The good news — it responds fastest to what we're about to show you."
    }

    private func weakZoneBody(_ name: String, _ score: Int) -> String {
        if score < 40 {
            return "Right now there's zero visible definition in your \(name.lowercased()). No separation, no contour — it's completely hidden. This single zone is why your midsection doesn't look the way you want it to."
        }
        if score < 55 {
            return "Your \(name.lowercased()) is where your physique falls apart. The muscle exists but it's buried. When someone looks at your core, this is the dead zone that makes everything else look incomplete."
        }
        if score < 65 {
            return "You can feel your \(name.lowercased()) when you flex, but you can't see it in the mirror. That gap between what you feel and what shows — that's exactly what we're going to close."
        }
        return "Your \(name.lowercased()) is trailing behind the rest. It's the one zone breaking the symmetry. Fix this and the whole picture changes."
    }

    private func gapHeadline(_ gap: Int, _ weakName: String) -> String {
        if gap >= 20 { return "There's a serious imbalance in your core" }
        if gap >= 12 { return "Your zones aren't developing evenly" }
        if gap >= 6 { return "Small imbalance, big visual impact" }
        return "Your development is well balanced"
    }

    private func gapBody(_ gap: Int, _ weakName: String, _ strongName: String) -> String {
        if gap >= 20 {
            return "A \(gap)-point spread between your \(strongName.lowercased()) and \(weakName.lowercased()) means one half of your core looks completely different from the other. People can see that asymmetry instantly. This is priority #1."
        }
        if gap >= 12 {
            return "\(gap) points separate your best and worst zones. In the mirror, this shows up as one area looking defined while the other looks soft. Closing this gap is the single fastest way to transform how your abs look."
        }
        if gap >= 6 {
            return "You're \(gap) points apart between zones. It's subtle but it's there — and it's the difference between abs that look 'okay' and abs that look complete. A few targeted weeks changes everything."
        }
        return "Your zones are tight. That balance means when you drop body fat, everything reveals at once — no weak spots dragging the look down."
    }

    private func bfHeadline(_ bf: Double, _ category: String) -> String {
        if bf <= 10 { return "You're shredded — every fiber is on display" }
        if bf <= 13 { return "You're lean enough to see real cuts" }
        if bf <= 16 { return "Some abs showing, more hiding underneath" }
        if bf <= 20 { return "Your abs are built — but covered" }
        if bf <= 25 { return "There's a six pack under there, seriously" }
        return "More muscle than you think, hidden under the surface"
    }

    private func bfBody(_ bf: Double) -> String {
        if bf <= 10 { return "At \(String(format: "%.0f", bf))% you're in rare territory. Vascularity, deep cuts between every segment, oblique striations — this is the physique most people dream about. The work now is maintaining it." }
        if bf <= 13 { return "At \(String(format: "%.0f", bf))% your upper abs are sharp and the midsection is tight. Drop 2-3 more percent and you'll unlock the deep lower ab lines and full oblique definition that makes people do a double take." }
        if bf <= 16 { return "At \(String(format: "%.0f", bf))% your top 2-4 abs are visible but the lower ones vanish. Here's the thing — each 1% you lose from here is worth more visually than the last 5% combined. You're entering the sweet spot." }
        if bf <= 20 { return "At \(String(format: "%.0f", bf))% there's a layer softening everything. Your muscle is real but nobody can see it yet. The definition you've been working for is literally millimeters below the surface." }
        if bf <= 25 { return "At \(String(format: "%.0f", bf))% the abs are fully hidden. But here's what most people don't realize — the muscle underneath is still developing with every workout. When you start cutting, it'll shock you how much is already there." }
        return "Your body fat is higher right now but that doesn't mean the work isn't happening. Every rep is building the foundation. When the fat starts coming off, you'll meet a version of yourself you didn't know existed."
    }

    private func bfColor(_ bf: Double) -> Color {
        if bf <= 12 { return AppTheme.success }
        if bf <= 18 { return AppTheme.primaryAccent }
        if bf <= 22 { return AppTheme.warning }
        return AppTheme.destructive
    }

    private func verdictBottomLine(overall: Int, weakName: String, bf: Double) -> String {
        if overall >= 75 && bf <= 14 {
            return "You're close to the finish line. Maintain the deficit, hit \(weakName.lowercased()) hard, and you'll see the final version of your physique within weeks."
        }
        if overall >= 60 {
            return "Your strongest zones prove you can build this. Now it's about bringing \(weakName.lowercased()) up and leaning out to reveal what you've already built."
        }
        return "The scan doesn't lie — the potential is real. Lock in on \(weakName.lowercased()) and nutrition this week. That's where your transformation starts."
    }

    // MARK: - Priority Fix Card

    private var priorityFixCard: some View {
        let action = scan?.breakdownWeeklyAction ?? fallbackAction

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text("YOUR #1 PRIORITY")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(1.5)
                Spacer()
            }

            Text(action)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                selectedZone = weakestZone
            } label: {
                HStack {
                    Text("See \(weakestZone.rawValue) Exercises")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(.white.opacity(0.1))
                .clipShape(.rect(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppTheme.primaryAccent)
        .clipShape(.rect(cornerRadius: 20))
        .opacity(revealedSections >= 4 ? 1 : 0)
        .offset(y: revealedSections >= 4 ? 0 : 12)
    }

    private var fallbackAction: String {
        "Hit \(weakestZone.rawValue) 3x this week with slow, controlled reps. That's the fastest path to a balanced midsection."
    }
}
