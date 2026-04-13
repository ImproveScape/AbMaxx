import SwiftUI
import Combine
import Charts

nonisolated enum AnalysisTab: String, CaseIterable {
    case breakdown = "Breakdown"
    case progress = "Progress"
    case volume = "Your Work"

    var icon: String {
        switch self {
        case .breakdown: return "waveform.path.ecg.rectangle"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .volume: return "flame.fill"
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
    @State private var showCountdownInfo: Bool = false

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
        if score >= 85 { return AppTheme.success }
        if score >= 75 { return AppTheme.yellow }
        if score >= 65 { return AppTheme.caution }
        return AppTheme.destructive
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
            ScrollView {
                VStack(spacing: 28) {
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
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .premiumBackground()
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

    @State private var now: Date = Date()
    private let countdownTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var headerSection: some View {
        HStack {
            Text("Analysis")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(.white)
            Spacer()
            if !vm.canScan, let nextDate = vm.nextScanDate {
                Button {
                    showCountdownInfo = true
                } label: {
                    nextScanChip(nextDate: nextDate)
                }
                .buttonStyle(.plain)
            } else if vm.canScan {
                Button {
                    showScan = true
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: 6, height: 6)
                        Text("Scan Ready")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.success.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .onReceive(countdownTimer) { _ in
            now = Date()
        }
        .sheet(isPresented: $showCountdownInfo) {
            scanCountdownSheet
                .presentationDetents([.medium])
                .presentationBackground(Color(hex: "0D0D0D"))
                .presentationDragIndicator(.visible)
        }
    }

    private var scanCountdownSheet: some View {
        let remaining = max((vm.nextScanDate ?? Date()).timeIntervalSince(now), 0)
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        let scanDay: String = {
            guard let next = vm.nextScanDate else { return "--" }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: next)
        }()

        return VStack(spacing: 0) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Image(systemName: "timer")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }

                VStack(spacing: 6) {
                    Text("Next Scan Unlocks In")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Text(scanDay)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }

                HStack(spacing: 16) {
                    countdownInfoUnit(value: days, label: "DAYS")
                    countdownInfoSeparator
                    countdownInfoUnit(value: hours, label: "HRS")
                    countdownInfoSeparator
                    countdownInfoUnit(value: minutes, label: "MIN")
                }
                .padding(.vertical, 16)

                VStack(spacing: 12) {
                    countdownInfoRow(
                        icon: "clock.arrow.circlepath",
                        text: "Scans refresh every 7 days to give your body time to show real progress."
                    )
                    countdownInfoRow(
                        icon: "camera.viewfinder",
                        text: "When the timer hits zero, your next scan unlocks automatically."
                    )
                    countdownInfoRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Weekly scans keep your scores accurate and track real changes."
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
    }

    private func countdownInfoUnit(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 36, weight: .black, design: .default))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(AppTheme.muted)
                .tracking(1.5)
        }
    }

    private var countdownInfoSeparator: some View {
        Text(":")
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(AppTheme.muted.opacity(0.3))
            .offset(y: -4)
    }

    private func countdownInfoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.primaryAccent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func nextScanChip(nextDate: Date) -> some View {
        let remaining = max(nextDate.timeIntervalSince(now), 0)
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600

        let label: String = {
            if days > 0 {
                return "\(days)d \(hours)h"
            } else {
                let mins = (Int(remaining) % 3600) / 60
                return "\(hours)h \(mins)m"
            }
        }()

        return HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.primaryAccent)
            Text(label)
                .font(.system(size: 13, weight: .heavy, design: .default))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Tab Pills

    @Namespace private var tabNamespace

    private var tabPills: some View {
        HStack(spacing: 6) {
            ForEach(AnalysisTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? .white : AppTheme.muted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            isSelected
                                ? AppTheme.primaryAccent
                                : AppTheme.card
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(
                                isSelected ? Color.clear : AppTheme.cardBorder,
                                lineWidth: 1
                            )
                        )
                }
                .buttonStyle(.plain)
            }
        }
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

    private var daysUntilNextScan: Int {
        guard let next = vm.nextScanDate else { return 0 }
        return max(Calendar.current.dateComponents([.day], from: now, to: next).day ?? 0, 0)
    }

    private var progressContent: some View {
        VStack(spacing: 14) {
            if sortedScans.isEmpty {
                progressEmptyState
            } else {
                progressWeekSelector
                    .padding(.horizontal, -6)
                progressPhotoHero
                progressScoreJourneyCard
                progressZoneProgressCard
                progressTransformationVideoCard

                if sortedScans.count >= 2 {
                    progressPhotoStrip
                }
            }
        }
        .sheet(item: $expandedScan) { scan in
            progressScanDetailSheet(scan: scan)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color(hex: "0D0D0D"))
        }
        .onAppear {
            if !sortedScans.isEmpty {
                selectedWeekIndex = sortedScans.count - 1
            }
        }
    }

    private var progressEmptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(AppTheme.primaryAccent.opacity(0.4))
            }
            VStack(spacing: 8) {
                Text("No Progress Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Complete your first scan to start\ntracking your transformation")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            Button {
                showScan = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 15, weight: .bold))
                    Text("Take First Scan")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.primaryAccent)
                .clipShape(.rect(cornerRadius: 14))
            }
            Spacer().frame(height: 40)
        }
    }

    // MARK: - Section 1: Photo Hero

    private var progressPhotoHero: some View {
        let displayScan: ScanResult? = sortedScans.indices.contains(selectedWeekIndex) ? sortedScans[selectedWeekIndex] : latestScan

        return ZStack(alignment: .bottomLeading) {
            if displayScan?.hasPhoto == true, let uiImage = displayScan?.loadImage() {
                Color(hex: "111111")
                    .frame(height: 380)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 20))
            } else {
                Color(hex: "111111")
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.rectangle")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.white.opacity(0.12))
                            Text("Take your scan to see your photo here")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "636366"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .clipShape(.rect(cornerRadius: 20))
            }

            LinearGradient(
                colors: [Color.clear, Color.clear, Color.black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .clipShape(.rect(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(displayScan?.overallScore ?? 0)")
                    .font(.system(size: 56, weight: .heavy))
                    .tracking(-0.03 * 56)
                    .foregroundStyle(.white)
                    .shadow(color: Color.white.opacity(0.15), radius: 12, x: 0, y: 0)
                Text("WEEK \(selectedWeekIndex + 1) SCORE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(1)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    // MARK: - Week Selector

    private var progressWeekSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(sortedScans.enumerated()), id: \.element.id) { index, _ in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedWeekIndex = index
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text("WK")
                                .font(.system(size: 11, weight: .bold))
                            Text("\(index + 1)")
                                .font(.system(size: 22, weight: .heavy))
                        }
                        .frame(width: 56, height: 64)
                        .foregroundStyle(index == selectedWeekIndex ? .white : Color(hex: "8E8E93"))
                        .background(index == selectedWeekIndex ? Color(hex: "0066FF") : Color.white.opacity(0.05))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    index == selectedWeekIndex ? Color.clear : Color.white.opacity(0.10),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: index == selectedWeekIndex ? Color(hex: "0066FF").opacity(0.55) : Color.clear, radius: 10, x: 0, y: 0)
                    }
                    .buttonStyle(.plain)
                }

                let futureCount = 40 - sortedScans.count
                if futureCount > 0 {
                    ForEach(0..<futureCount, id: \.self) { i in
                        let weekNum = sortedScans.count + 1 + i
                        let isNext = i == 0
                        VStack(spacing: 2) {
                            Text("WK")
                                .font(.system(size: 11, weight: .bold))
                            Text("\(weekNum)")
                                .font(.system(size: 22, weight: .heavy))
                        }
                        .frame(width: 56, height: 64)
                        .foregroundStyle(isNext ? Color(hex: "0066FF").opacity(0.45) : Color(hex: "333333"))
                        .background(isNext ? Color(hex: "0066FF").opacity(0.06) : Color.white.opacity(0.03))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    isNext ? Color(hex: "0066FF").opacity(0.22) : Color.white.opacity(0.06),
                                    style: isNext ? StrokeStyle(lineWidth: 1, dash: [4, 3]) : StrokeStyle(lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .contentMargins(.horizontal, 6)
    }

    // MARK: - Score Journey Card

    private var progressScoreJourneyCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Score Journey")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                    if sortedScans.count > 1 {
                        Text("▲ +\(scoreGain) pts across \(sortedScans.count) scans")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "32D74B"))
                            .shadow(color: Color(hex: "32D74B").opacity(0.40), radius: 6, x: 0, y: 0)
                    } else {
                        Text("Scan 2 unlocks in \(daysUntilNextScan) days")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "8E8E93"))
                    }
                }
                Spacer()
                if sortedScans.count == 1 {
                    VStack(spacing: 1) {
                        Text("1")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Color(hex: "0066FF"))
                        Text("SCAN")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(Color(hex: "636366"))
                            .tracking(0.5)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(hex: "0066FF").opacity(0.10))
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color(hex: "0066FF").opacity(0.25), lineWidth: 1)
                    )
                }
            }

            if sortedScans.count == 1 {
                singleScanChartView
                    .padding(.top, 14)
            } else {
                multiScanChartView
                    .padding(.top, 14)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    private var singleScanChartView: some View {
        let blueColor = Color(hex: "0066FF")
        let score = firstScan?.overallScore ?? 0

        return VStack(spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.75))
                    path.addLine(to: CGPoint(x: w, y: h * 0.75))
                }
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.50))
                    path.addLine(to: CGPoint(x: w, y: h * 0.50))
                }
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.25))
                    path.addLine(to: CGPoint(x: w, y: h * 0.25))
                }
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)

                let dotX: CGFloat = w * 0.15
                let dotY: CGFloat = h * 0.45

                Circle()
                    .fill(blueColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: blueColor.opacity(0.60), radius: 8, x: 0, y: 0)
                    .position(x: dotX, y: dotY)

                Text("\(score)")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                    .position(x: dotX, y: dotY - 16)
            }
            .frame(height: 130)

            HStack {
                Text("Wk 1")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(hex: "48484A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
        }
    }

    private var multiScanChartView: some View {
        let blueColor = Color(hex: "0066FF")
        let greenColor = Color(hex: "32D74B")
        let chartScans = Array(sortedScans.suffix(6))
        let baseWeek = sortedScans.count - chartScans.count + 1

        struct ChartItem: Identifiable {
            let id: Int
            let index: Int
            let score: Int
            let weekLabel: String
        }

        let chartData: [ChartItem] = chartScans.enumerated().map { i, scan in
            ChartItem(id: i, index: i, score: scan.overallScore, weekLabel: "Wk \(baseWeek + i)")
        }

        let highestIdx = chartData.enumerated().max(by: { $0.element.score < $1.element.score })?.offset
        let lastIdx = chartData.count - 1

        return VStack(spacing: 8) {
            Chart {
                RuleMark(y: .value("Grid", 60))
                    .foregroundStyle(Color.white.opacity(0.04))
                    .lineStyle(StrokeStyle(lineWidth: 0.5))
                RuleMark(y: .value("Grid", 75))
                    .foregroundStyle(Color.white.opacity(0.04))
                    .lineStyle(StrokeStyle(lineWidth: 0.5))
                RuleMark(y: .value("Grid", 90))
                    .foregroundStyle(Color.white.opacity(0.04))
                    .lineStyle(StrokeStyle(lineWidth: 0.5))

                ForEach(chartData) { item in
                    AreaMark(
                        x: .value("Week", item.index),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [blueColor.opacity(0.15), blueColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Week", item.index),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [blueColor, greenColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Week", item.index),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(item.index == lastIdx ? greenColor : blueColor)
                    .symbolSize(item.index == lastIdx ? 50 : 35)
                    .shadow(color: item.index == lastIdx ? greenColor.opacity(0.60) : Color.clear, radius: 8, x: 0, y: 0)
                    .annotation(position: .top, spacing: 4) {
                        if item.index == 0 || item.index == lastIdx || item.index == highestIdx {
                            Text("\(item.score)")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(item.index == lastIdx ? greenColor : .white)
                        }
                    }
                }
            }
            .chartYScale(domain: 45...100)
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.background(Color.clear)
            }
            .frame(height: 160)

            HStack(spacing: 0) {
                ForEach(chartData) { item in
                    Text(item.weekLabel)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color(hex: "48484A"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    // MARK: - Transformation Video Card

    @State private var showTransformationVideo: Bool = false

    private var progressTransformationVideoCard: some View {
        Button {
            showTransformationVideo = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "film.stack")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Create Transformation Video")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(sortedScans.count >= 2 ? "\(sortedScans.filter { $0.hasPhoto }.count) photos ready" : "Scan 2 to unlock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "636366"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "636366"))
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(.rect(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showTransformationVideo) {
            NavigationStack {
                TransformationVideoView(vm: vm)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showTransformationVideo = false
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Zone Progress Card

    private var progressZoneProgressCard: some View {
        let zones: [(String, KeyPath<ScanResult, Int>)] = [
            ("UPPER ABS", \.upperAbsScore),
            ("LOWER ABS", \.lowerAbsScore),
            ("OBLIQUES", \.obliquesScore),
            ("DEEP CORE", \.deepCoreScore),
            ("SYMMETRY", \.symmetry),
            ("V-TAPER", \.frame)
        ]

        return VStack(spacing: 0) {
            HStack {
                Text("Zone Progress")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
                if sortedScans.count > 1 {
                    Text("vs Week 1")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "636366"))
                } else {
                    Text("Scan 2 to unlock")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "636366"))
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 3), spacing: 7) {
                ForEach(zones, id: \.0) { zoneName, keyPath in
                    let latestScore = latestScan?[keyPath: keyPath] ?? 0
                    let firstScore = firstScan?[keyPath: keyPath] ?? 0
                    let delta = latestScore - firstScore

                    VStack(spacing: 4) {
                        Text(zoneName)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color(hex: "636366"))
                            .tracking(0.8)

                        if sortedScans.count == 1 {
                            Text("—")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "2a2a2a"))
                        } else if delta > 0 {
                            Text("▲ +\(delta)")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(Color(hex: "32D74B"))
                                .shadow(color: Color(hex: "32D74B").opacity(0.45), radius: 6, x: 0, y: 0)
                        } else if delta < 0 {
                            Text("▼ \(abs(delta))")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(Color(hex: "FF453A"))
                                .shadow(color: Color(hex: "FF453A").opacity(0.40), radius: 6, x: 0, y: 0)
                        } else {
                            Text("—")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "636366"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.white.opacity(0.04))
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                    )
                }
            }
            .padding(.top, 10)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }





    // MARK: - Section 3: Scan Photos Strip

    private var progressPhotoStrip: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Scan Photos")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(sortedScans.count) photo\(sortedScans.count == 1 ? "" : "s")")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "636366"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(sortedScans.enumerated()), id: \.element.id) { index, scan in
                        Button {
                            expandedScan = scan
                        } label: {
                            progressStripThumbnail(scan: scan, weekIndex: index + 1, isLatest: index == sortedScans.count - 1)
                        }
                        .buttonStyle(.plain)
                    }

                    let emptyCount = min(max(6 - sortedScans.count, 0), 3)
                    ForEach(0..<emptyCount, id: \.self) { i in
                        let weekNum = sortedScans.count + i + 1
                        let futureDate: String = {
                            guard let lastDate = sortedScans.last?.date else { return "" }
                            let future = Calendar.current.date(byAdding: .weekOfYear, value: i + 1, to: lastDate) ?? lastDate
                            let f = DateFormatter()
                            f.dateFormat = "MMM d"
                            return f.string(from: future)
                        }()
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                )
                            VStack(spacing: 3) {
                                Text("Wk \(weekNum)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color(hex: "48484A"))
                                Text(futureDate)
                                    .font(.system(size: 7))
                                    .foregroundStyle(Color(hex: "333333"))
                            }
                        }
                        .frame(width: 72, height: 90)
                    }
                }
                .padding(.top, 10)
            }
            .contentMargins(.horizontal, 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func progressStripThumbnail(scan: ScanResult, weekIndex: Int, isLatest: Bool) -> some View {
        ZStack {
            if scan.hasPhoto, let uiImage = scan.loadImage() {
                Color(.secondarySystemBackground)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .overlay {
                        LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.70)], startPoint: .center, endPoint: .bottom)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(alignment: .bottomLeading) {
                        Text("\(scan.overallScore)")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.60))
                            .clipShape(.rect(cornerRadius: 5))
                            .padding(4)
                    }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .overlay {
                        VStack(spacing: 2) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: "48484A"))
                            Text("\(scan.overallScore)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color(hex: "636366"))
                        }
                    }
            }
        }
        .frame(width: 72, height: 90)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isLatest ? Color(hex: "32D74B").opacity(0.60) : Color(hex: "0066FF").opacity(0.40),
                    lineWidth: 1.5
                )
        )
        .shadow(color: isLatest ? Color(hex: "32D74B").opacity(0.30) : Color.clear, radius: 8, x: 0, y: 0)
    }



    // MARK: - Scan Detail Sheet

    private func progressScanDetailSheet(scan: ScanResult) -> some View {
        let weekIdx = (sortedScans.firstIndex(where: { $0.id == scan.id }) ?? 0) + 1
        return ScrollView {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Week \(weekIdx)")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(.white)
                        Text(scan.date, format: .dateTime.month(.wide).day().year())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Button {
                        expandedScan = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                if let uiImage = scan.loadImage() {
                    Color(.secondarySystemBackground)
                        .frame(height: 260)
                        .overlay {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 20))
                        .padding(.horizontal, 20)
                }

                Text("\(scan.overallScore)")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)

                Text("Week \(weekIdx)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "636366"))
                    .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    sheetStatPill(label: "BODY FAT", value: String(format: "%.0f%%", scan.estimatedBodyFat), color: Color(hex: "32D74B"))
                    sheetStatPill(label: "STRUCTURE", value: scan.absStructure.rawValue, color: Color(hex: "0066FF"))
                }
                .padding(.horizontal, 20)

                let zoneData: [(String, Int)] = [
                    ("Upper Abs", scan.upperAbsScore),
                    ("Lower Abs", scan.lowerAbsScore),
                    ("Obliques", scan.obliquesScore),
                    ("Deep Core", scan.deepCoreScore),
                    ("Symmetry", scan.symmetry),
                    ("V Taper", scan.frame)
                ]

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(zoneData, id: \.0) { name, score in
                        HStack {
                            Text(name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text("\(score)")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(zoneColor(score))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)

                Color.clear.frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func sheetStatPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color(hex: "636366"))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
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
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.clear, lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 28) {
            Text("Your Work")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 32) {
                workStatItem(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(totalWorkouts)",
                    label: "Workouts",
                    sub: "\(weeklyWorkouts) this week"
                )

                workStatItem(
                    icon: "flame.fill",
                    value: "\(vm.profile.streakDays)",
                    label: "Day Streak",
                    sub: "Best: \(bestStreak)"
                )

                workStatItem(
                    icon: "checkmark.seal.fill",
                    value: formattedNumber(totalReps),
                    label: "Total Reps",
                    sub: "\(weeklyWorkouts * 15) this week"
                )

                workStatItem(
                    icon: "clock.fill",
                    value: "\(totalMinutes)",
                    label: "Minutes",
                    sub: "\(weeklyWorkouts * 3) this week"
                )
            }
        }
    }

    private func workStatItem(icon: String, value: String, label: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)

            Text(value)
                .font(.system(size: 38, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.top, 2)

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            Text(sub)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
