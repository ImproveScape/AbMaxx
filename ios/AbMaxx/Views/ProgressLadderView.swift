import SwiftUI
import Combine

struct ProgressLadderView: View {
    @Bindable var vm: AppViewModel
    @State private var showScan: Bool = false
    @State private var selectedWeekIndex: Int = 0
    @State private var showDeficitPicker: Bool = false
    @State private var now: Date = Date()

    private var sortedScans: [ScanResult] {
        vm.scanResults.sorted { $0.date < $1.date }
    }

    private let maxWeeksShown: Int = 8

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        progressHeader

                        if !sortedScans.isEmpty && !vm.canScan {
                            nextScanCountdownCard
                        }

                        if sortedScans.isEmpty {
                            emptyStateCard
                        } else {
                            weekSelectorRow
                            mainScoreCard
                            subscoreBreakdown
                            statsBar

                            if sortedScans.count >= 2 {
                                scoreGraph
                            }
                        }

                        if vm.scanResults.isEmpty || !vm.hasScannedToday {
                            scanPrompt
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showScan) {
                ScanView(vm: vm)
            }
            .sheet(isPresented: $showDeficitPicker) {
                CalorieDeficitPickerSheet(vm: vm)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                selectedWeekIndex = max(sortedScans.count - 1, 0)
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                now = Date()
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Progress")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            if !sortedScans.isEmpty {
                if vm.canScan {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: 7, height: 7)
                        Text("Scan available now")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.success)
                    }
                } else {
                    scanCountdownInline
                }
            } else {
                Text("Track your ab transformation")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scanCountdownInline: some View {
        let time = vm.timeUntilNextScan
        let totalSeconds = max((vm.nextScanDate ?? Date()).timeIntervalSince(now), 0)
        let progress = 1.0 - (totalSeconds / (7 * 24 * 60 * 60))

        return HStack(spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)

                HStack(spacing: 2) {
                    countdownDigit(value: time.days, label: "d")
                    Text("\u{2022}")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppTheme.muted.opacity(0.3))
                        .offset(y: -1)
                    countdownDigit(value: time.hours, label: "h")
                    Text("\u{2022}")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppTheme.muted.opacity(0.3))
                        .offset(y: -1)
                    countdownDigit(value: time.minutes, label: "m")
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: geo.size.width * min(max(progress, 0.03), 1.0))
                }
            }
            .frame(width: 48, height: 4)
        }
    }

    private func countdownDigit(value: Int, label: String) -> some View {
        HStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 15, weight: .heavy, design: .default))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: value)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundStyle(AppTheme.muted)
                .offset(y: 1)
        }
    }

    // MARK: - Next Scan Countdown

    private var nextScanCountdownCard: some View {
        let time = vm.timeUntilNextScan
        let totalSeconds = max((vm.nextScanDate ?? Date()).timeIntervalSince(now), 0)
        let progress = 1.0 - (totalSeconds / (7 * 24 * 60 * 60))

        return VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating)
                Text(countdownMotivation(days: time.days))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("NEXT SCAN")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(1.2)
            }

            HStack(spacing: 8) {
                countdownBlock(value: time.days, label: "DAYS")
                countdownSeparator
                countdownBlock(value: time.hours, label: "HRS")
                countdownSeparator
                countdownBlock(value: time.minutes, label: "MIN")
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.04))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primaryAccent.opacity(0.6), AppTheme.primaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(max(progress, 0.02), 1.0))
                            .animation(.easeInOut(duration: 0.5), value: progress)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text("\(Int(progress * 100))% ready")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                    Spacer()
                    if let next = vm.nextScanDate {
                        Text(next, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(AppTheme.cardSurface)
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent.opacity(0.06), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.primaryAccent.opacity(0.15), lineWidth: 1)
        )
    }

    private func countdownBlock(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 32, weight: .black, design: .default))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: value)
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(AppTheme.muted)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var countdownSeparator: some View {
        Text(":")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(AppTheme.muted.opacity(0.4))
            .offset(y: -6)
    }

    private func countdownMotivation(days: Int) -> String {
        if days <= 1 { return "Almost time — stay locked in" }
        if days <= 2 { return "Your next scan is close" }
        if days <= 4 { return "Keep grinding, scan day is coming" }
        return "Stay consistent, results are building"
    }

    // MARK: - Week Selector

    private var weekSelectorRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<maxWeeksShown, id: \.self) { index in
                        let hasScan = index < sortedScans.count
                        let isSelected = hasScan && index == selectedWeekIndex
                        let isLatest = hasScan && index == sortedScans.count - 1

                        Button {
                            guard hasScan else { return }
                            withAnimation(.spring(duration: 0.35)) {
                                selectedWeekIndex = index
                            }
                        } label: {
                            weekPill(
                                weekNumber: index + 1,
                                score: hasScan ? sortedScans[index].overallScore : nil,
                                isSelected: isSelected,
                                isLatest: isLatest,
                                hasScan: hasScan
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

    private func weekPill(weekNumber: Int, score: Int?, isSelected: Bool, isLatest: Bool, hasScan: Bool) -> some View {
        VStack(spacing: 5) {
            Text("Wk \(weekNumber)")
                .font(.system(.caption, design: .default, weight: .bold))
                .foregroundStyle(hasScan ? (isSelected ? .white : AppTheme.secondaryText) : AppTheme.muted.opacity(0.5))

            if let score {
                Text("\(score)")
                    .font(.system(size: 22, weight: .black, design: .default))
                    .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
            } else {
                Text("—")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundStyle(AppTheme.muted.opacity(0.3))
            }

            if isLatest && hasScan {
                Text("NOW")
                    .font(.system(size: 9, weight: .heavy, design: .default))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(0.5)
            } else if hasScan && !isLatest {
                Circle()
                    .fill(AppTheme.muted.opacity(0.4))
                    .frame(width: 5, height: 5)
            } else {
                Text("scan")
                    .font(.system(size: 9, weight: .medium, design: .default))
                    .foregroundStyle(AppTheme.muted.opacity(0.3))
            }
        }
        .frame(width: 68, height: 78)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? AppTheme.primaryAccent.opacity(0.12) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isSelected ? AppTheme.primaryAccent : (hasScan ? AppTheme.border : AppTheme.border.opacity(0.3)),
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }

    // MARK: - Main Score Card

    private var mainScoreCard: some View {
        let scan = sortedScans[safe: selectedWeekIndex] ?? sortedScans.last ?? ScanResult.sample
        let tier = RankTier.tier(for: scan.overallScore)

        return VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if let uiImage = scan.loadImage() {
                    Color(AppTheme.cardSurface)
                        .frame(height: 260)
                        .overlay {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(topLeadingRadius: AppTheme.cardCornerRadius, topTrailingRadius: AppTheme.cardCornerRadius))
                } else {
                    photoPlaceholder
                }

                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.yellow)
                    Text(tier.name)
                        .font(.system(.caption, design: .default, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(AppTheme.primaryAccent)
                )
                .padding(14)
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(scan.overallScore)")
                        .font(.system(size: 56, weight: .black, design: .default))
                        .foregroundStyle(.white)
                    Text("ABMAXX SCORE")
                        .font(.system(size: 11, weight: .bold, design: .default))
                        .foregroundStyle(AppTheme.muted)
                        .tracking(1.2)
                }

                Spacer()

                Text(String(format: "%.0f%%", scan.estimatedBodyFat))
                    .font(.system(size: 24, weight: .black, design: .default))
                    .foregroundStyle(AppTheme.secondaryText)
                + Text(" BF")
                    .font(.system(size: 13, weight: .bold, design: .default))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 18)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(bottomLeadingRadius: AppTheme.cardCornerRadius, bottomTrailingRadius: AppTheme.cardCornerRadius))
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
        .animation(.spring(duration: 0.35), value: selectedWeekIndex)
    }

    private var photoPlaceholder: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "camera.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.muted.opacity(0.3))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(topLeadingRadius: AppTheme.cardCornerRadius, topTrailingRadius: AppTheme.cardCornerRadius))
    }

    // MARK: - Subscore Breakdown

    private var subscoreBreakdown: some View {
        let scan = sortedScans[safe: selectedWeekIndex] ?? sortedScans.last ?? ScanResult.sample

        return VStack(spacing: 14) {
            HStack {
                Text("SUBSCORES")
                    .font(.system(size: 11, weight: .heavy, design: .default))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(1)
                Spacer()
                Text("Week \(selectedWeekIndex + 1)")
                    .font(.system(size: 11, weight: .bold, design: .default))
                    .foregroundStyle(AppTheme.primaryAccent)
            }

            VStack(spacing: 10) {
                ForEach(scan.subscores, id: \.0) { name, score, icon in
                    subscoreRow(name: name, score: score, icon: icon)
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
        .animation(.spring(duration: 0.35), value: selectedWeekIndex)
    }

    private func subscoreRow(name: String, score: Int, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.scoreColor(for: score))
                .frame(width: 16)

            Text(name)
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 72, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.scoreColor(for: score).opacity(0.7), AppTheme.scoreColor(for: score)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (Double(score) / 100.0))
                }
            }
            .frame(height: 6)

            Text("\(score)")
                .font(.system(size: 13, weight: .black, design: .default))
                .foregroundStyle(.white)
                .monospacedDigit()
                .frame(width: 28, alignment: .trailing)
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        let scan = sortedScans[safe: selectedWeekIndex] ?? sortedScans.last ?? ScanResult.sample
        let change = selectedWeekIndex > 0 ? scan.overallScore - (sortedScans.first?.overallScore ?? 0) : 0
        let deficit = vm.profile.selectedCalorieDeficit

        return VStack(spacing: 12) {
            if selectedWeekIndex > 0 {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(change >= 0 ? AppTheme.success : AppTheme.destructive)
                        Text(change >= 0 ? "+\(change) pts" : "\(change) pts")
                            .font(.system(size: 20, weight: .black, design: .default))
                            .foregroundStyle(change >= 0 ? AppTheme.success : AppTheme.destructive)
                    }
                    Text("since week 1")
                        .font(.system(.caption, design: .default, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                    Spacer()
                }

                Divider().overlay(AppTheme.border)
            }

            Button {
                showDeficitPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calorie Deficit")
                            .font(.system(.caption2, design: .default, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                        Text("-\(deficit) cal/day")
                            .font(.system(.subheadline, design: .default, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Text("Change")
                        .font(.system(.caption, design: .default, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Score Graph

    private var scoreGraph: some View {
        let scores = sortedScans.map { $0.overallScore }
        let minScore = max((scores.min() ?? 0) - 10, 0)
        let maxScore = min((scores.max() ?? 100) + 10, 100)
        let range = max(Double(maxScore - minScore), 1)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SCORE TREND")
                    .font(.system(size: 11, weight: .heavy, design: .default))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(1)
                Spacer()
                if let first = scores.first, let last = scores.last {
                    let diff = last - first
                    HStack(spacing: 4) {
                        Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                            .font(.system(size: 12, weight: .bold, design: .default))
                    }
                    .foregroundStyle(diff >= 0 ? AppTheme.success : AppTheme.destructive)
                }
            }

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let stepX = scores.count > 1 ? w / CGFloat(scores.count - 1) : w

                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        let yVal = minScore + Int(Double(i) * range / 2.0)
                        let y = h - (CGFloat(yVal - minScore) / CGFloat(range)) * h
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    }

                    Path { path in
                        for (i, score) in scores.enumerated() {
                            let x = scores.count > 1 ? stepX * CGFloat(i) : w / 2
                            let y = h - (CGFloat(score - minScore) / CGFloat(range)) * h
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent.opacity(0.6), AppTheme.primaryAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                    ForEach(0..<scores.count, id: \.self) { i in
                        let x = scores.count > 1 ? stepX * CGFloat(i) : w / 2
                        let y = h - (CGFloat(scores[i] - minScore) / CGFloat(range)) * h

                        Circle()
                            .fill(AppTheme.cardSurface)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(AppTheme.primaryAccent)
                                    .frame(width: 5, height: 5)
                            )
                            .position(x: x, y: y)
                    }

                    let lastIdx = scores.count - 1
                    let lastX = scores.count > 1 ? stepX * CGFloat(lastIdx) : w / 2
                    let lastY = h - (CGFloat(scores[lastIdx] - minScore) / CGFloat(range)) * h

                    Text("\(scores[lastIdx])")
                        .font(.system(size: 11, weight: .heavy, design: .default))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(AppTheme.primaryAccent)
                        )
                        .position(x: min(max(lastX, 20), w - 20), y: lastY - 18)
                }
            }
            .frame(height: 120)

            HStack {
                ForEach(0..<scores.count, id: \.self) { i in
                    if i == 0 || i == scores.count - 1 {
                        Text("Wk \(i + 1)")
                            .font(.system(size: 10, weight: .medium, design: .default))
                            .foregroundStyle(AppTheme.muted)
                    }
                    if i == 0 && scores.count > 1 {
                        Spacer()
                    }
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyStateCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.muted.opacity(0.4))

            VStack(spacing: 6) {
                Text("No Scans Yet")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Complete your first scan to start tracking progress")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Scan Prompt

    private var scanPrompt: some View {
        Button {
            showScan = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentGradient)
                        .frame(width: 50, height: 50)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 12)
                    Image(systemName: "camera.viewfinder")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Scan Your Abs")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Scan weekly to track progress")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
            }
            .padding(16)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.primaryAccent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct MiniStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.system(.subheadline, design: .default, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
    }
}
