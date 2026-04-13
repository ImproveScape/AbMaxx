import SwiftUI

nonisolated enum AnalysisTab: String, CaseIterable {
    case breakdown = "Breakdown"
    case progress = "Progress"
    case volume = "Your Work"

    var icon: String {
        switch self {
        case .breakdown: return "waveform.path.ecg"
        case .progress: return "arrow.up.right"
        case .volume: return "bolt.fill"
        }
    }
}

struct AnalysisView: View {
    @Bindable var vm: AppViewModel
    @State private var showScan: Bool = false
    @State private var animateChart: Bool = false
    @State private var selectedSubscore: SubscoreSelection? = nil
    @State private var selectedTab: AnalysisTab = .breakdown
    @State private var expandedScan: ScanResult? = nil
    @State private var selectedWeekIndex: Int = 0
    @State private var showGhostOverlay: Bool = false
    @State private var selectedChartPoint: Int? = nil

    private var sortedScans: [ScanResult] {
        vm.scanResults.sorted { $0.date < $1.date }
    }

    private var firstScan: ScanResult? { sortedScans.first }
    private var latestScan: ScanResult? { sortedScans.last }
    private var previousScan: ScanResult? {
        guard sortedScans.count >= 2 else { return nil }
        return sortedScans[sortedScans.count - 2]
    }

    private var scoreGain: Int {
        guard let first = firstScan, let latest = latestScan else { return 0 }
        return latest.overallScore - first.overallScore
    }

    private var weeksOnProgram: Int {
        max(sortedScans.count, 1)
    }

    private var projectedScore: Int {
        guard let latest = latestScan, weeksOnProgram > 1 else { return 0 }
        let rate = Double(scoreGain) / Double(weeksOnProgram)
        return min(Int(Double(latest.overallScore) + rate * 12.0), 99)
    }

    private var scanDueDay: String {
        guard let next = vm.nextScanDate else { return "now" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: next)
    }

    private var currentWeekLabel: String {
        "Week \(weeksOnProgram)"
    }

    private var zoneMetrics: [(String, Int, String, Color)] {
        guard let s = latestScan else { return [] }
        return [
            ("Upper abs", s.upperAbsScore, "chevron.up.2", zoneColor(s.upperAbsScore)),
            ("Lower abs", s.lowerAbsScore, "chevron.down.2", zoneColor(s.lowerAbsScore)),
            ("Obliques", s.obliquesScore, "arrow.left.and.right", zoneColor(s.obliquesScore)),
            ("Deep core", s.deepCoreScore, "circle.grid.cross.fill", zoneColor(s.deepCoreScore)),
            ("Symmetry", s.symmetry, "arrow.left.arrow.right", zoneColor(s.symmetry)),
            ("V taper", s.frame, "chart.bar.fill", zoneColor(s.frame))
        ]
    }

    private func zoneColor(_ score: Int) -> Color {
        if score >= 64 { return AppTheme.success }
        if score >= 63 { return AppTheme.primaryAccent }
        if score >= 59 { return AppTheme.destructive }
        return AppTheme.muted
    }

    private func zoneChange(for name: String) -> Int {
        guard let prev = previousScan, let current = latestScan else { return 0 }
        switch name {
        case "Symmetry": return current.symmetry - prev.symmetry
        case "V taper": return current.frame - prev.frame
        case "Upper abs": return current.upperAbsScore - prev.upperAbsScore
        case "Lower abs": return current.lowerAbsScore - prev.lowerAbsScore
        case "Obliques": return current.obliquesScore - prev.obliquesScore
        case "Deep core": return current.deepCoreScore - prev.deepCoreScore
        default: return 0
        }
    }

    private func barColor(for name: String) -> Color {
        guard let s = latestScan else { return AppTheme.muted }
        let score: Int
        switch name {
        case "Upper abs": score = s.upperAbsScore
        case "Lower abs": score = s.lowerAbsScore
        case "Obliques": score = s.obliquesScore
        case "Deep core": score = s.deepCoreScore
        case "Symmetry": score = s.symmetry
        case "V taper": score = s.frame
        default: score = 0
        }
        return zoneColor(score)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                StandardBackgroundOrbs()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        tabPills

                        switch selectedTab {
                        case .progress:
                            progressContent
                        case .breakdown:
                            BreakdownTabView(vm: vm)
                        case .volume:
                            VolumeTabView(vm: vm)
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
            .fullScreenCover(isPresented: $showScan) {
                ScanView(vm: vm)
            }
            .sheet(item: $selectedSubscore) { selection in
                SubscoreDetailSheet(
                    name: selection.name,
                    score: selection.score,
                    icon: selection.icon,
                    change: selection.change,
                    scan: vm.latestScan
                )
                .presentationDetents([.large])
                .presentationBackground(AppTheme.background)
                .presentationDragIndicator(.hidden)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    animateChart = true
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Analysis")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            if !vm.canScan {
                Text("Scan due \(scanDueDay)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppTheme.cardSurface)
                    )
            }
        }
    }

    // MARK: - Tab Pills

    @Namespace private var tabNamespace

    private var tabPills: some View {
        HStack(spacing: 4) {
            ForEach(AnalysisTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(AppTheme.primaryAccent)
                                    .matchedGeometryEffect(id: "activeTab", in: tabNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
        )
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    // MARK: - Empty Tab

    private func emptyTabPlaceholder(title: String, icon: String, description: String) -> some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.muted.opacity(0.4))
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
            Text(description)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Progress Content

    private var progressContent: some View {
        VStack(spacing: 20) {
            if sortedScans.count >= 2 {
                scoreOverTimeSection
            }

            progressWeekSlider
            progressPhotoCard

            if sortedScans.count >= 2 {
                bodyFatTrendSection
                zoneImprovementSection
            }

            if vm.canScan {
                progressScanBanner
            }

            TransformationVideoView(vm: vm)
        }
        .fullScreenCover(item: $expandedScan) { scan in
            ExpandedPhotoView(scan: scan, weekIndex: (sortedScans.firstIndex(where: { $0.id == scan.id }) ?? 0) + 1)
        }
        .onAppear {
            if !sortedScans.isEmpty {
                selectedWeekIndex = sortedScans.count - 1
            }
        }
    }

    // MARK: - Score Over Time

    private var scoreOverTimeSection: some View {
        let chartData = sortedScans.map { (date: $0.date, score: $0.overallScore) }
        let firstScore = sortedScans.first?.overallScore ?? 0
        let latestScore = sortedScans.last?.overallScore ?? 0
        let totalChange = latestScore - firstScore

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("SCORE TREND")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(AppTheme.primaryAccent)
                            .tracking(2)
                    }
                    Text("\(latestScore)")
                        .font(.system(size: 36, weight: .black, design: .default))
                        .foregroundStyle(.white)
                }
                Spacer()
                if totalChange != 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: totalChange > 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 11, weight: .bold))
                            Text(totalChange > 0 ? "+\(totalChange)" : "\(totalChange)")
                                .font(.system(size: 16, weight: .black, design: .default))
                        }
                        .foregroundStyle(totalChange > 0 ? AppTheme.success : AppTheme.destructive)
                        Text("since start")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }

            OverallScoreChartView(
                data: chartData,
                selectedPoint: $selectedChartPoint
            )
            .frame(height: 200)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    // MARK: - Body Fat Trend

    private var bodyFatTrendSection: some View {
        let entries = sortedScans.map { (date: $0.date, bf: $0.estimatedBodyFat) }
        let firstBF = entries.first?.bf ?? 0
        let latestBF = entries.last?.bf ?? 0
        let change = latestBF - firstBF

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "percent")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.orange)
                        Text("BODY FAT TREND")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(AppTheme.orange)
                            .tracking(2)
                    }
                    Text(String(format: "%.1f%%", latestBF))
                        .font(.system(size: 32, weight: .black, design: .default))
                        .foregroundStyle(.white)
                }
                Spacer()
                if abs(change) > 0.1 {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: change < 0 ? "arrow.down.right" : "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                            Text(String(format: "%+.1f%%", change))
                                .font(.system(size: 15, weight: .black, design: .default))
                        }
                        .foregroundStyle(change < 0 ? AppTheme.success : AppTheme.destructive)
                        Text("since start")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }

            bodyFatMiniChart(entries: entries)

            HStack(spacing: 12) {
                bodyFatStatPill(label: "Start", value: String(format: "%.1f%%", firstBF))
                bodyFatStatPill(label: "Current", value: String(format: "%.1f%%", latestBF))
                bodyFatStatPill(label: "Category", value: sortedScans.last?.bodyFatCategory ?? "--")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private func bodyFatStatPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .default))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
        .clipShape(.rect(cornerRadius: 10))
    }

    private func bodyFatMiniChart(entries: [(date: Date, bf: Double)]) -> some View {
        let bfValues = entries.map(\.bf)
        let minBF = (bfValues.min() ?? 5) - 1
        let maxBF = (bfValues.max() ?? 30) + 1
        let range = max(maxBF - minBF, 2)

        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let points: [CGPoint] = entries.enumerated().map { i, entry in
                let x = entries.count > 1 ? w * CGFloat(i) / CGFloat(entries.count - 1) : w / 2
                let y = h * (1 - CGFloat(entry.bf - minBF) / CGFloat(range))
                return CGPoint(x: x, y: y)
            }

            if points.count >= 2 {
                Path { path in
                    path.move(to: points[0])
                    for i in 1..<points.count {
                        let prev = points[i - 1]
                        let curr = points[i]
                        let midX = (prev.x + curr.x) / 2
                        path.addCurve(
                            to: curr,
                            control1: CGPoint(x: midX, y: prev.y),
                            control2: CGPoint(x: midX, y: curr.y)
                        )
                    }
                }
                .stroke(AppTheme.orange, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                Path { path in
                    path.move(to: CGPoint(x: points[0].x, y: h))
                    path.addLine(to: points[0])
                    for i in 1..<points.count {
                        let prev = points[i - 1]
                        let curr = points[i]
                        let midX = (prev.x + curr.x) / 2
                        path.addCurve(
                            to: curr,
                            control1: CGPoint(x: midX, y: prev.y),
                            control2: CGPoint(x: midX, y: curr.y)
                        )
                    }
                    path.addLine(to: CGPoint(x: points.last!.x, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [AppTheme.orange.opacity(0.2), AppTheme.orange.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(AppTheme.orange)
                        .frame(width: 6, height: 6)
                        .position(point)
                }
            }
        }
        .frame(height: 100)
    }

    // MARK: - Zone Improvement

    private var zoneImprovementSection: some View {
        let zones: [(name: String, icon: String, current: Int, first: Int)] = {
            guard let first = sortedScans.first, let latest = sortedScans.last else { return [] }
            return [
                ("Upper Abs", "star.fill", latest.upperAbsScore, first.upperAbsScore),
                ("Lower Abs", "chevron.down", latest.lowerAbsScore, first.lowerAbsScore),
                ("Obliques", "plus", latest.obliquesScore, first.obliquesScore),
                ("Deep Core", "circle.grid.2x2.fill", latest.deepCoreScore, first.deepCoreScore),
                ("Symmetry", "arrow.left.arrow.right", latest.symmetry, first.symmetry),
                ("V Taper", "chart.bar.fill", latest.frame, first.frame)
            ]
        }()

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.forward.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.success)
                Text("ZONE IMPROVEMENTS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AppTheme.success)
                    .tracking(2)
                Spacer()
                Text("\(sortedScans.count) scans")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }

            ForEach(zones, id: \.name) { zone in
                zoneImprovementRow(zone: zone)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private func zoneImprovementRow(zone: (name: String, icon: String, current: Int, first: Int)) -> some View {
        let change = zone.current - zone.first
        let barColor: Color = zone.current >= 75 ? AppTheme.success : (zone.current >= 60 ? AppTheme.primaryAccent : AppTheme.warning)

        return HStack(spacing: 12) {
            Image(systemName: zone.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(barColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(zone.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(zone.current)")
                        .font(.system(size: 15, weight: .black, design: .default))
                        .foregroundStyle(.white)
                    if change != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 8, weight: .black))
                            Text(change > 0 ? "+\(change)" : "\(change)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(change > 0 ? AppTheme.success : AppTheme.destructive)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.border)
                            .frame(height: 4)
                        Capsule()
                            .fill(barColor)
                            .frame(width: geo.size.width * Double(zone.current) / 100.0, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Week Slider

    @State private var timelineScrollID: Int? = nil

    private var selectedProgressScan: ScanResult? {
        guard selectedWeekIndex >= 0, selectedWeekIndex < sortedScans.count else { return nil }
        return sortedScans[selectedWeekIndex]
    }

    private var progressWeekSlider: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<max(sortedScans.count, 8), id: \.self) { index in
                        let hasScan = index < sortedScans.count
                        let isSelected = index == selectedWeekIndex
                        let isLatest = hasScan && index == sortedScans.count - 1

                        Button {
                            guard hasScan else { return }
                            withAnimation(.spring(duration: 0.3)) {
                                selectedWeekIndex = index
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text("WK")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(isSelected ? .white : AppTheme.muted)
                                    .tracking(0.5)

                                Text("\(index + 1)")
                                    .font(.system(size: 24, weight: .black, design: .default))
                                    .foregroundStyle(isSelected ? .white : (hasScan ? AppTheme.secondaryText : AppTheme.muted.opacity(0.3)))

                                if isLatest {
                                    Text("NOW")
                                        .font(.system(size: 9, weight: .heavy, design: .default))
                                        .foregroundStyle(AppTheme.primaryAccent)
                                        .tracking(0.5)
                                } else if hasScan {
                                    Text("\(sortedScans[index].overallScore)")
                                        .font(.system(size: 11, weight: .bold, design: .default))
                                        .foregroundStyle(isSelected ? .white.opacity(0.7) : AppTheme.muted)
                                } else {
                                    Text("--")
                                        .font(.system(size: 11, weight: .bold, design: .default))
                                        .foregroundStyle(AppTheme.muted.opacity(0.2))
                                }
                            }
                            .frame(width: 56, height: 72)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? AppTheme.primaryAccent : AppTheme.cardSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        isSelected ? AppTheme.primaryAccent : (hasScan ? AppTheme.border : AppTheme.border.opacity(0.3)),
                                        lineWidth: isSelected ? 0 : 1
                                    )
                            )
                        }
                        .disabled(!hasScan)
                        .id(index)
                    }
                }
                .padding(.horizontal, 2)
            }
            .contentMargins(.horizontal, 0)
            .onChange(of: selectedWeekIndex) { _, newValue in
                withAnimation(.spring(duration: 0.3)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    // MARK: - Photo Card

    private var firstScanImage: UIImage? {
        sortedScans.first?.loadImage()
    }

    private var canShowGhost: Bool {
        selectedWeekIndex > 0 && firstScanImage != nil
    }

    private var progressPhotoCard: some View {
        let scan = selectedProgressScan
        let score = scan?.overallScore ?? 0
        let change = scan.flatMap { s in firstScan.map { s.overallScore - $0.overallScore } } ?? 0

        return VStack(spacing: 0) {
            if let scan = scan, let uiImage = scan.loadImage() {
                Button {
                    expandedScan = scan
                } label: {
                    Color(AppTheme.cardSurface)
                        .frame(height: 420)
                        .overlay {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .overlay {
                            if showGhostOverlay, let ghostImage = firstScanImage, selectedWeekIndex > 0 {
                                Image(uiImage: ghostImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(0.3)
                                    .allowsHitTesting(false)
                                    .transition(.opacity)
                            }
                        }
                        .overlay {
                            LinearGradient(
                                colors: [
                                    .clear, .clear,
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.85)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 24))
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text("\(score)")
                                        .font(.system(size: 80, weight: .black, design: .default))
                                        .foregroundStyle(.white)

                                    if selectedWeekIndex > 0 {
                                        HStack(spacing: 3) {
                                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                                .font(.system(size: 12, weight: .bold))
                                            Text("\(abs(change))")
                                                .font(.system(size: 18, weight: .black, design: .default))
                                        }
                                        .foregroundStyle(change >= 0 ? AppTheme.success : AppTheme.destructive)
                                    }
                                }

                                Text("WEEK \(selectedWeekIndex + 1) SCORE")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .tracking(1.5)
                            }
                            .padding(24)
                        }
                        .overlay(alignment: .topTrailing) {
                            HStack(spacing: 8) {
                                if canShowGhost {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showGhostOverlay.toggle()
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: showGhostOverlay ? "person.2.fill" : "person.2")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("Ghost")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .foregroundStyle(showGhostOverlay ? AppTheme.primaryAccent : .white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(
                                            showGhostOverlay
                                                ? AnyShapeStyle(AppTheme.primaryAccent.opacity(0.3))
                                                : AnyShapeStyle(.ultraThinMaterial)
                                        )
                                        .clipShape(Capsule())
                                    }
                                    .sensoryFeedback(.impact(weight: .light), trigger: showGhostOverlay)
                                }

                                let tier = RankTier.tier(for: score)
                                HStack(spacing: 5) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.yellow)
                                    Text(tier.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial, in: Capsule())
                            }
                            .padding(16)
                        }
                }
                .buttonStyle(.plain)

                if showGhostOverlay && canShowGhost {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("Week 1 ghost overlay active — see how far you've come")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryAccent.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 10))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                progressEmptyPhotoCard
            }

            if let scan = scan {
                progressBodyFatBar(scan: scan)
            }
        }
        .animation(.spring(duration: 0.35), value: selectedWeekIndex)
    }

    private func progressNextTargetBanner(for structure: AbsStructure) -> some View {
        let nextTarget = progressNextStructure(for: structure)
        return Group {
            if let next = nextTarget {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                    Text(next)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(AppTheme.success.opacity(0.08))
                .clipShape(.rect(cornerRadius: 14))
            }
        }
    }

    private var progressEmptyPhotoCard: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.primaryAccent.opacity(0.3))
            Text("No scan photo yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
            Text("Complete your first scan to see your progress here")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.muted.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 350)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private func progressBodyFatBar(scan: ScanResult) -> some View {
        let bodyFat = scan.estimatedBodyFat
        let structure = scan.absStructure

        return VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: "%.1f%%", bodyFat))
                        .font(.system(size: 26, weight: .black, design: .default))
                        .foregroundStyle(.white)
                    Text("BODY FAT")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(AppTheme.muted)
                        .tracking(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(structure.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardSurface)
                    .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
            )

            progressNextTargetBanner(for: structure)
        }
        .padding(.top, 10)
    }

    private func progressNextStructure(for structure: AbsStructure) -> String? {
        switch structure {
        case .flat: return "Next: 2-Pack \u{2192} ~\(vm.profile.scanUpperAbsWeeks ?? 12) wks"
        case .twoPack: return "Next: 4-Pack \u{2192} ~\(vm.profile.scanObliquesWeeks ?? 16) wks"
        case .fourPack: return "Next: 6-Pack \u{2192} ~\(vm.profile.scanLowerAbsWeeks ?? 20) wks"
        case .sixPack: return "Next: 8-Pack \u{2192} ~\(vm.profile.scanVtaperWeeks ?? 24) wks"
        case .eightPack: return nil
        case .asymmetric: return "Symmetry \u{2192} ~\(vm.profile.scanLowerAbsWeeks ?? 16) wks"
        }
    }

    // MARK: - Stats Row

    private var progressStatsRow: some View {
        let scan = selectedProgressScan

        return HStack(spacing: 10) {
            progressStatBox(
                value: scan != nil ? "\(scan!.overallScore)" : "--",
                label: "SCORE",
                color: .white
            )
            progressStatBox(
                value: scan != nil ? String(format: "%.0f%%", scan!.estimatedBodyFat) : "--",
                label: "BODY FAT",
                color: AppTheme.primaryAccent
            )
            progressStatBox(
                value: scan?.absStructure.rawValue ?? "--",
                label: "STRUCTURE",
                color: AppTheme.success
            )
        }
    }

    private func progressStatBox(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .default))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    // MARK: - Scan Banner

    private var progressScanBanner: some View {
        Button {
            showScan = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: 44, height: 44)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 12)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Week \(weeksOnProgram) Scan Ready")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Takes 30 sec")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer()

                Text("SCAN")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.primaryAccent)
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardSurface)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.1), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: showScan)
    }

    // MARK: - Zone Breakdown

    private var zoneBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Zone Breakdown")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(zoneMetrics, id: \.0) { metric in
                    zoneCard(name: metric.0, score: metric.1, color: metric.3)
                }
            }
        }
    }

    private func zoneCard(name: String, score: Int, color: Color) -> some View {
        let change = zoneChange(for: name)
        let bColor = barColor(for: name)
        let badgeColor = zoneColor(score)

        return Button {
            let iconMap: [String: String] = [
                "Upper abs": "chevron.up.2",
                "Lower abs": "chevron.down.2",
                "Obliques": "arrow.left.and.right",
                "Deep core": "circle.grid.cross.fill",
                "Symmetry": "arrow.left.arrow.right",
                "V taper": "chart.bar.fill"
            ]
            selectedSubscore = SubscoreSelection(
                name: name,
                score: score,
                icon: iconMap[name] ?? "circle",
                change: change != 0 ? change : nil
            )
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(score)")
                        .font(.system(size: 28, weight: .black, design: .default))
                        .foregroundStyle(color)

                    if change != 0 {
                        Text("+\(change)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(badgeColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(badgeColor.opacity(0.15))
                            )
                    } else {
                        Text("+0")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.muted.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(AppTheme.muted.opacity(0.1))
                            )
                    }
                }

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 3)
                    GeometryReader { geo in
                        Capsule()
                            .fill(bColor)
                            .frame(width: max(geo.size.width * Double(score) / 100.0, 4), height: 3)
                    }
                }
                .frame(height: 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.cardSurface)
                    .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Your Work

    private var totalWorkouts: Int {
        vm.totalExercisesCompleted
    }

    private var weeklyWorkouts: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        var count = 0
        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let key = "completedExercises_\(formatter.string(from: day))"
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
                count += decoded.count
            }
        }
        return count
    }

    private var bestStreak: Int {
        max(vm.profile.streakDays, 1)
    }

    private var totalReps: Int {
        vm.totalExercisesCompleted * 15
    }

    private var totalMinutes: Int {
        vm.totalExercisesCompleted * 3
    }

    private var yourWorkSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Work")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                workStatCard(
                    icon: "chart.bar.fill",
                    iconColor: Color(red: 0.4, green: 0.35, blue: 1.0),
                    iconBg: Color(red: 0.4, green: 0.35, blue: 1.0).opacity(0.15),
                    value: "\(totalWorkouts)",
                    label: "Workouts done",
                    subLabel: "\(weeklyWorkouts) this week",
                    subColor: AppTheme.primaryAccent
                )

                workStatCard(
                    icon: "flame.fill",
                    iconColor: AppTheme.orange,
                    iconBg: AppTheme.orange.opacity(0.15),
                    value: "\(vm.profile.streakDays)",
                    label: "Day streak",
                    subLabel: "Best: \(bestStreak) days",
                    subColor: AppTheme.success
                )

                workStatCard(
                    icon: "checkmark.circle.fill",
                    iconColor: AppTheme.success,
                    iconBg: AppTheme.success.opacity(0.15),
                    value: formattedNumber(totalReps),
                    label: "AI counted reps",
                    subLabel: "\(weeklyWorkouts * 15) this week",
                    subColor: AppTheme.success
                )

                workStatCard(
                    icon: "clock.fill",
                    iconColor: AppTheme.warning,
                    iconBg: AppTheme.warning.opacity(0.15),
                    value: "\(totalMinutes)",
                    label: "Mins trained",
                    subLabel: "\(weeklyWorkouts * 3) this week",
                    subColor: AppTheme.warning
                )
            }
        }
    }

    private func workStatCard(icon: String, iconColor: Color, iconBg: Color, value: String, label: String, subLabel: String, subColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBg)
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(.system(size: 34, weight: .black, design: .default))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)

            Text(subLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(subColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private func formattedNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
