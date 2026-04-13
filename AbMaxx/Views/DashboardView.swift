import SwiftUI
import Combine

struct DashboardView: View {
    @Bindable var vm: AppViewModel
    @Binding var selectedTab: Int
    @State private var animateScore: Bool = false
    @State private var badgePulse: Bool = false
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var showScan: Bool = false
    @State private var showBadgeLadder: Bool = false
    @State private var showWhyYouStarted: Bool = false
    @State private var showDailyMotivation: Bool = false
    @State private var showGuidedWorkout: Bool = false
    @State private var showCompare: Bool = false
    @State private var showBodyFat: Bool = false
    @State private var showRecovery: Bool = false
    @State private var countdownText: String = ""
    @State private var scanCountdown: (days: Int, hours: Int, minutes: Int) = (0, 0, 0)
    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var hypePhase: Bool = false
    @State private var animateChart: Bool = false
    @State private var animateRing: Bool = false
    @State private var selectedSubscore: SubscoreSelection? = nil
    @State private var selectedFeeling: String = ""

    private var abMaxxScore: Int {
        vm.latestScan?.overallScore ?? 0
    }

    private var previousScan: ScanResult? {
        let sorted = vm.scanResults.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }
        return sorted[sorted.count - 2]
    }

    private var regionMetrics: [(String, Int, String)] {
        guard let s = vm.latestScan else {
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
        guard let s = vm.latestScan else {
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

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                backgroundOrbs

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 14) {
                            headerSection
                            if vm.missedYesterday && !vm.streakRecoveredToday {
                                dashboardStreakBanner
                            }
                            badgeRingSection
                            WeeklyStreakView(
                                workoutHistory: vm.workoutHistory,
                                streakDays: vm.profile.streakDays,
                                transformationStartDate: vm.profile.transformationStartDate
                            )
                            todaysSessionCard
                            scanCountdownHypeSection
                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showScan) {
                ScanView(vm: vm)
            }
            .fullScreenCover(isPresented: $showDailyMotivation) {
                DailyMotivationView()
            }
            .fullScreenCover(isPresented: $showGuidedWorkout) {
                WorkoutSessionView(
                    exercises: vm.todaysExercises,
                    completedExercises: vm.completedExercises,
                    onComplete: { id, xp in
                        vm.completeExercise(id, xp: xp)
                    },
                    daysUntilNextScan: vm.daysUntilNextScan,
                    hoursUntilNextScan: vm.timeUntilNextScan.hours,
                    canScan: vm.canScan,
                    currentScore: vm.latestScan?.overallScore ?? 0,
                    difficulty: vm.currentDifficulty ?? .medium
                )
            }
            .sheet(isPresented: $showCompare) {
                BeforeAfterCompareView(vm: vm)
                    .presentationDetents([.large])
                    .presentationBackground(AppTheme.background)
            }
            .sheet(isPresented: $showBodyFat) {
                BodyFatTrackerView(vm: vm)
                    .presentationDetents([.large])
                    .presentationBackground(AppTheme.background)
            }
            .sheet(isPresented: $showRecovery) {
                RecoveryView(vm: vm)
                    .presentationDetents([.large])
                    .presentationBackground(AppTheme.background)
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
            .sheet(isPresented: $showBadgeLadder) {
                BadgeLadderView(currentScore: abMaxxScore)
                    .presentationDetents([.large])
                    .presentationBackground(AppTheme.background)
                    .presentationDragIndicator(.hidden)
            }
            .onAppear {
                updateCountdown()
                scanCountdown = vm.timeUntilNextScan
                loadFeeling()
                withAnimation(.easeOut(duration: 1.2)) { animateScore = true }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    badgePulse = true
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    withAnimation(.spring(duration: 1.0, bounce: 0.15)) {
                        animateRing = true
                    }
                }
            }
            .onReceive(countdownTimer) { _ in
                scanCountdown = vm.timeUntilNextScan
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        let currentTier = RankTier.allTiers[currentTierIndex]
        return HStack {
            Text("AbMaxx")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Spacer()

            HStack(spacing: 10) {
                Button {
                    showBadgeLadder = true
                } label: {
                    Text("Rank: \(currentTier.name)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [currentTier.color1, currentTier.color2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(currentTier.color1.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [currentTier.color1.opacity(0.35), currentTier.color2.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)

                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.orange)
                    Text("\(vm.profile.streakDays)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(AppTheme.orange.opacity(0.08))
                        .overlay(Capsule().strokeBorder(AppTheme.orange.opacity(0.2), lineWidth: 1))
                )
            }
        }
    }

    private var currentTierIndex: Int {
        RankTier.currentTierIndex(for: abMaxxScore)
    }

    // MARK: - Badge Ring

    private var badgeRingSection: some View {
        let score = abMaxxScore
        let ringProgress = animateRing ? Double(score) / 100.0 : 0
        let currentTier = RankTier.allTiers[currentTierIndex]
        let circleSize: CGFloat = 190
        let badgeSize: CGFloat = circleSize * 0.45

        return Button {
            showBadgeLadder = true
        } label: {
            ZStack {
                Circle()
                    .stroke(
                        AppTheme.muted.opacity(0.25),
                        lineWidth: 7
                    )
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [currentTier.color1, currentTier.color2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1.2, bounce: 0.1), value: ringProgress)


                VStack(spacing: 6) {
                    RankBadgeImage(tier: currentTier, isUnlocked: true, size: badgeSize)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(.white)
                        Text("/100")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.25), value: score)
                }
                .offset(y: 10)
            }

            .padding(.top, 6)
        }
        .buttonStyle(.plain)
    }

    private func statHighlight(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(AppTheme.muted)
            }
        }
    }

    private var latestScanPhoto: UIImage? {
        guard let latestScan = vm.latestScan, latestScan.hasPhoto else { return nil }
        return latestScan.loadImage()
    }

    // MARK: - Today's Progress

    private var todayProgressSection: some View {
        let exerciseTotal = vm.isTodayRestDay ? 0 : vm.todaysExercises.count
        let exerciseDone = vm.isTodayRestDay ? 0 : vm.todaysExercises.filter { vm.completedExercises.contains($0.id) }.count
        let nutritionTotal = vm.todaysNutrition.count
        let nutritionDone = vm.todaysNutrition.filter { vm.completedNutrition.contains($0.id) }.count
        let mindsetTotal = vm.todaysMindset.count
        let mindsetDone = vm.todaysMindset.filter { vm.completedMindset.contains($0.id) }.count

        return TodayProgressRingsView(
            exerciseDone: exerciseDone,
            exerciseTotal: exerciseTotal,
            nutritionDone: nutritionDone,
            nutritionTotal: nutritionTotal,
            mindsetDone: mindsetDone,
            mindsetTotal: mindsetTotal,
            caloriesEaten: vm.totalCaloriesToday,
            calorieGoal: vm.dailyNutrition.calorieGoal,
            proteinEaten: vm.totalProteinToday,
            proteinGoal: vm.dailyNutrition.proteinGoal,
            waterGlasses: vm.waterGlasses,
            waterGoal: vm.dailyNutrition.waterGoal
        )
    }

    private func zoneCard(metric: (String, Int, String), isWeak: Bool, change: Int?) -> some View {
        let barColor: Color = isWeak ? AppTheme.destructive : zoneBarColor(for: metric.1)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: metric.2)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text(metric.0)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if isWeak {
                    Text("Weak")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(AppTheme.destructive)
                        )
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(metric.1)")
                    .font(.system(size: 30, weight: .black, design: .default))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if let change = change, change != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .black))
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
                        .frame(height: 5)
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * Double(metric.1) / 100.0, height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardSurface)
                .shadow(color: isWeak ? AppTheme.destructive.opacity(0.12) : Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private func zoneBarColor(for score: Int) -> Color {
        if score >= 75 {
            return AppTheme.success
        } else if score >= 60 {
            return AppTheme.primaryAccent
        } else {
            return AppTheme.warning
        }
    }

    private func metricChange(for name: String) -> Int? {
        guard let prev = previousScan, let current = vm.latestScan else { return nil }
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

    // MARK: - Daily Check-In

    private var dailyCheckInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty Level")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                feelingPill(label: "Feeling good", icon: "bolt.fill", value: "good")
                feelingPill(label: "Feeling okay", icon: "hand.thumbsup.fill", value: "okay")
                feelingPill(label: "Feeling dead", icon: "battery.0percent", value: "dead")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private func feelingPill(label: String, icon: String, value: String) -> some View {
        let isSelected = selectedFeeling == value
        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedFeeling = value
            }
            saveFeeling(value)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(label.replacingOccurrences(of: "Feeling ", with: ""))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.primaryAccent : AppTheme.cardSurface)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedFeeling)
    }

    private func saveFeeling(_ value: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = "dailyFeeling_\(formatter.string(from: Date()))"
        UserDefaults.standard.set(value, forKey: key)
    }

    private func loadFeeling() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = "dailyFeeling_\(formatter.string(from: Date()))"
        selectedFeeling = UserDefaults.standard.string(forKey: key) ?? ""
    }

    // MARK: - Today's Session Card

    private var todaysSessionCard: some View {
        VStack(spacing: 0) {
            if vm.isTodayRestDay {
                restDayCard
            } else {
                activeSessionCard
            }
        }
    }

    private var activeSessionCard: some View {
        let exerciseCount = vm.todaysExercises.count
        let estimatedMinutes = exerciseCount * 2 + 1

        return Button {
            showGuidedWorkout = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(vm.programDayNumber)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text(vm.todayTargetLabel)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "figure.core.training")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(AppTheme.primaryAccent.opacity(0.6))
                }

                HStack(spacing: 16) {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.muted)
                        Text("~\(estimatedMinutes) min")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    HStack(spacing: 5) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.muted)
                        Text("\(exerciseCount) exercises")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                HStack {
                    Text("Start Session")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
                .background(
                    Capsule().fill(AppTheme.primaryAccent)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 12, y: 4)
                )
            }
            .padding(18)
            .background(
                ZStack {
                    AppTheme.cardSurface
                    RadialGradient(
                        colors: [AppTheme.primaryAccent.opacity(0.08), Color.clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 200
                    )
                }
            )
            .clipShape(.rect(cornerRadius: 18))
            .shadow(color: AppTheme.primaryAccent.opacity(0.12), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var restDayCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Rest Day")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("Recovery is part of the process. Your muscles grow while you rest.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    // MARK: - Scan Cards

    private var scanCooldownCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.primaryAccent.opacity(0.08))
                    .frame(width: 48, height: 48)
                Image(systemName: "viewfinder")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Next Scan")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text("Progress scan available soon")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
            }

            Spacer()

            HStack(spacing: 4) {
                countdownPill(value: scanCountdown.days, label: "d")
                countdownPill(value: scanCountdown.hours, label: "h")
                countdownPill(value: scanCountdown.minutes, label: "m")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private func countdownPill(value: Int, label: String) -> some View {
        HStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 16, weight: .black, design: .default))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func updateCountdown() {
        guard vm.hasScannedToday else {
            countdownText = ""
            return
        }
        let now = Date()
        let tomorrow = Calendar.current.startOfDay(for: now).addingTimeInterval(86400)
        let diff = tomorrow.timeIntervalSince(now)
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        countdownText = "\(hours)h \(minutes)m"
    }

    private var dailyScanCard: some View {
        Button {
            showScan = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 10)
                    Image(systemName: "viewfinder")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Scan Your Abs")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Ready to scan")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.success)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(AppTheme.primaryAccent.opacity(0.1))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardSurface)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.1), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background

    // MARK: - Scan Countdown Hype

    private var scanHypeMessage: String {
        if vm.canScan {
            return ["Your abs are waiting. Scan now.", "Time's up. Show your progress.", "Scan unlocked. Let's see those gains."].randomElement() ?? "Scan ready."
        }
        let d = scanCountdown.days
        if d <= 0 {
            let h = scanCountdown.hours
            if h <= 1 {
                return "Almost there. Your next scan drops any minute."
            }
            return "Hours away. Your abs have been putting in work."
        } else if d == 1 {
            return "Tomorrow you scan. Train hard today."
        } else if d <= 3 {
            return "\(d) days out. Every rep counts right now."
        } else {
            return "\(d) days until you prove your progress."
        }
    }

    private var scanCountdownHypeSection: some View {
        Group {
            if vm.scanResults.isEmpty {
                Button {
                    showScan = true
                } label: {
                    firstScanHypeCard
                }
                .buttonStyle(.plain)
            } else if vm.canScan {
                Button {
                    showScan = true
                } label: {
                    scanReadyHypeCard
                }
                .buttonStyle(.plain)
            } else {
                countdownHypeCard
            }
        }
    }

    private var firstScanHypeCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .symbolEffect(.pulse, options: .repeating)
                Text("Take Your First Scan")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
            }
            Text("Scan your abs to unlock your personalized plan")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            ZStack {
                AppTheme.cardSurface
                RadialGradient(
                    colors: [AppTheme.primaryAccent.opacity(0.1), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 250
                )
            }
        )
        .clipShape(.rect(cornerRadius: 18))
        .shadow(color: AppTheme.primaryAccent.opacity(0.1), radius: 8, y: 4)
    }

    private var scanReadyHypeCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: 8, height: 8)
                            .shadow(color: AppTheme.success.opacity(0.8), radius: 6)
                        Text("SCAN READY")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AppTheme.success)
                            .tracking(1.5)
                    }
                    Text("Your abs have leveled up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: 48, height: 48)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 16)
                    Image(systemName: "viewfinder")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(hypePhase ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: hypePhase)
            }

            Text("7 days of work. Time to see results.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            ZStack {
                AppTheme.cardSurface
                RadialGradient(
                    colors: [AppTheme.success.opacity(0.08), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 250
                )
            }
        )
        .clipShape(.rect(cornerRadius: 18))
        .shadow(color: AppTheme.success.opacity(0.1), radius: 8, y: 4)
        .onAppear { hypePhase = true }
    }

    private var countdownHypeCard: some View {
        let d = scanCountdown.days
        let h = scanCountdown.hours
        let m = scanCountdown.minutes
        let totalSeconds = d * 86400 + h * 3600 + m * 60
        let progress = max(0, min(1.0, 1.0 - Double(totalSeconds) / (7.0 * 86400.0)))

        return VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT SCAN")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .tracking(1.5)
                    Text(scanHypeMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                countdownUnit(value: d, label: "DAYS")
                countdownDivider
                countdownUnit(value: h, label: "HRS")
                countdownDivider
                countdownUnit(value: m, label: "MIN")
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.03))

            )

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.border)
                        .frame(height: 4)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private func countdownUnit(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .black, design: .default))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.3), value: value)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.muted)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var countdownDivider: some View {
        Text(":")
            .font(.system(size: 24, weight: .bold, design: .default))
            .foregroundStyle(AppTheme.muted.opacity(0.5))
    }

    private var dashboardStreakBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.orange)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("You missed yesterday")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text("Your \(vm.previousStreakDays)-day streak is at risk. Go to Routine to save it.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.orange)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.orange.opacity(0.6))
        }
        .padding(16)
        .background(
            ZStack {
                AppTheme.cardSurface
                RadialGradient(
                    colors: [AppTheme.orange.opacity(0.08), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 200
                )
            }
        )
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: AppTheme.orange.opacity(0.1), radius: 8, y: 4)
        .onTapGesture {
            selectedTab = 0
        }
    }


    private var backgroundOrbs: some View {
        StandardBackgroundOrbs()
    }
}

nonisolated struct BadgeTierSelection: Identifiable {
    let index: Int
    var id: Int { index }
}

struct SubscoreSelection: Identifiable {
    let name: String
    let score: Int
    let icon: String
    let change: Int?
    var id: String { name }
}

struct DashboardStatCard: View {
    let icon: String
    let label: String
    let value: String
    let borderColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 22, weight: .black, design: .default))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }
}

struct ActionCircleButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 60, height: 60)
                    .shadow(color: color.opacity(0.15), radius: 8, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProgressMiniRow: View {
    let icon: String
    let label: String
    let done: Int
    let total: Int
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i < done ? color : AppTheme.border)
                        .frame(width: 6, height: 6)
                }
            }
            Text("\(done)/\(total)")
                .font(.caption.bold())
                .foregroundStyle(done == total ? AppTheme.success : .white)
        }
    }
}


