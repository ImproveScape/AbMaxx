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
    @State private var showLeaderboard: Bool = false
    @State private var countdownText: String = ""
    @State private var scanCountdown: (days: Int, hours: Int, minutes: Int) = (0, 0, 0)
    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var hypePhase: Bool = false
    @State private var animateChart: Bool = false
    @State private var animateRing: Bool = false
    @State private var selectedSubscore: SubscoreSelection? = nil
    @State private var selectedFeeling: String = ""
    @State private var showScanToast: Bool = false
    @State private var showMilestones: Bool = false
    @State private var showAbsCoach: Bool = false
    @State private var liveLeaderboardTop3: [LeaderboardMember] = []
    @State private var liveUserRank: Int? = nil

    private var abMaxxScore: Int {
        vm.latestScan?.overallScore ?? 0
    }

    private var leaderboardPreviewMembers: [LeaderboardMember] {
        liveLeaderboardTop3.isEmpty ? LeaderboardMember.celebrities.sorted(by: { $0.score > $1.score }) : liveLeaderboardTop3
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
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                        .padding(.horizontal, 20)

                    WeeklyStreakView(
                        workoutHistory: vm.workoutHistory,
                        streakDays: vm.profile.streakDays,
                        transformationStartDate: vm.profile.transformationStartDate
                    )
                    .padding(.horizontal, 20)

                    scoreSection

                    todaysSessionCard
                        .padding(.horizontal, 20)

                    scanCountdownHypeSection
                        .padding(.horizontal, 20)

                    leaderboardSection
                        .padding(.horizontal, 20)

                    Color.clear.frame(height: 100)
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .premiumBackground()
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
                    onComplete: { id in
                        vm.completeExercise(id)
                    },
                    daysUntilNextScan: vm.daysUntilNextScan,
                    hoursUntilNextScan: vm.timeUntilNextScan.hours,
                    canScan: vm.canScan,
                    currentScore: vm.latestScan?.overallScore ?? 0,
                    difficulty: vm.currentDifficulty ?? .medium,
                    zoneScores: [
                        .upperAbs: vm.zoneScoreForRegion(.upperAbs),
                        .lowerAbs: vm.zoneScoreForRegion(.lowerAbs),
                        .obliques: vm.zoneScoreForRegion(.obliques),
                        .deepCore: vm.zoneScoreForRegion(.deepCore)
                    ]
                )
            }
            .sheet(isPresented: $showCompare) {
                BeforeAfterCompareView(vm: vm)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showBodyFat) {
                BodyFatTrackerView(vm: vm)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showRecovery) {
                RecoveryView(vm: vm)
                    .presentationDetents([.large])
            }
            .navigationDestination(isPresented: $showLeaderboard) {
                LeaderboardView(vm: vm)
            }
            .navigationDestination(isPresented: $showMilestones) {
                StreakMilestonesView(vm: vm)
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
            .sheet(isPresented: $showBadgeLadder) {
                BadgeLadderView(currentScore: abMaxxScore)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showAbsCoach = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primaryAccent)
                            .frame(width: 64, height: 64)
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 27, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 10, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .sensoryFeedback(.impact(weight: .light), trigger: showAbsCoach)
            }
            .sheet(isPresented: $showAbsCoach) {
                AbsCoachChatView(vm: vm)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .overlay(alignment: .topTrailing) {
                if showScanToast && !vm.canScan {
                    ScanReminderToast(days: scanCountdown.days) {
                        withAnimation(.spring(duration: 0.3)) {
                            showScanToast = false
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .padding(.trailing, 16)
                    .padding(.top, 60)
                }
            }
            .onAppear {
                updateCountdown()
                scanCountdown = vm.timeUntilNextScan
                loadFeeling()
                Task { await loadLeaderboardPreview() }
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
                Task {
                    try? await Task.sleep(for: .seconds(5))
                    withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                        showScanToast = true
                    }
                    try? await Task.sleep(for: .seconds(6))
                    withAnimation(.spring(duration: 0.3)) {
                        showScanToast = false
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                ABMAXXWordmark(size: .large)
            }
            Spacer()

            Button {
                showMilestones = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.orange)
                    Text("\(vm.profile.streakDays)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.orange.opacity(0.15), in: Capsule())
            }
        }
    }

    private var currentTierIndex: Int {
        RankTier.currentTierIndex(for: abMaxxScore)
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        let score = abMaxxScore
        let ringProgress = animateRing ? Double(score) / 100.0 : 0
        let currentTier = RankTier.allTiers[currentTierIndex]
        let circleSize: CGFloat = 210
        let badgeSize: CGFloat = circleSize * 0.55

        return Button {
            showBadgeLadder = true
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    currentTier.color1.opacity(0.25),
                                    currentTier.color2.opacity(0.12),
                                    currentTier.color1.opacity(0.08),
                                    currentTier.color2.opacity(0.18),
                                    currentTier.color1.opacity(0.25)
                                ],
                                center: .center
                            ),
                            lineWidth: 8
                        )
                        .frame(width: circleSize, height: circleSize)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                colors: [currentTier.color1, currentTier.color2, currentTier.color1],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: circleSize, height: circleSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 1.2, bounce: 0.1), value: ringProgress)

                    RankBadgeImage(tier: currentTier, isUnlocked: true, size: badgeSize)
                        .shadow(color: currentTier.color1.opacity(0.25), radius: 12, x: 0, y: 0)
                        .shadow(color: currentTier.color2.opacity(0.12), radius: 24, x: 0, y: 2)
                }

                VStack(spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("/100")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }

                    Text(currentTier.name.uppercased())
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2.5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [currentTier.color1, currentTier.color2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(currentTier.color1.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [currentTier.color1.opacity(0.4), currentTier.color2.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                }
            }
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text(metric.0)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if isWeak {
                    Text("Weak")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppTheme.destructive, in: Capsule())
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(metric.1)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if let change = change, change != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                        Text(change > 0 ? "+\(change)" : "\(change)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(change > 0 ? AppTheme.success : AppTheme.destructive)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 4)
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * Double(metric.1) / 100.0, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardSurface, in: .rect(cornerRadius: AppTheme.cardCornerRadius))
    }

    private func zoneBarColor(for score: Int) -> Color {
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
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                feelingPill(label: "Feeling good", icon: "bolt.fill", value: "good")
                feelingPill(label: "Feeling okay", icon: "hand.thumbsup.fill", value: "okay")
                feelingPill(label: "Feeling dead", icon: "battery.0percent", value: "dead")
            }
        }
        .padding(16)
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
                    .font(.system(size: 11, weight: .semibold))
                Text(label.replacingOccurrences(of: "Feeling ", with: ""))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(isSelected ? AppTheme.primaryAccent : Color.white.opacity(0.06), in: Capsule())
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
        let completedCount = vm.todaysExercises.filter { vm.completedExercises.contains($0.id) }.count
        let estimatedMinutes = exerciseCount * 2 + 1

        let allCompleted = completedCount == exerciseCount && exerciseCount > 0

        return Button {
            if !allCompleted {
                showGuidedWorkout = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(vm.programDayNumber)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text(vm.todayTargetLabel)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("\(completedCount)/\(exerciseCount)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                HStack(spacing: 16) {
                    Label("~\(estimatedMinutes) min", systemImage: "clock")
                    Label("\(exerciseCount) exercises", systemImage: "dumbbell.fill")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)

                HStack {
                    Text(allCompleted ? "Session Complete" : "Start Session")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: allCompleted ? "checkmark" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(allCompleted ? AppTheme.success : AppTheme.primaryAccent)
                .clipShape(.rect(cornerRadius: 14))
            }
            .padding(20)
            .background(AppTheme.cardSurface, in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!allCompleted)
        .sensoryFeedback(.impact(weight: .medium), trigger: showGuidedWorkout)
    }

    private var restDayCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.purple)

            VStack(alignment: .leading, spacing: 3) {
                Text("Rest Day")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Recovery is part of the process.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()
        }
        .padding(20)
    }

    // MARK: - Scan Cards

    private var scanCooldownCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "viewfinder")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.primaryAccent)

            VStack(alignment: .leading, spacing: 3) {
                Text("Next Scan")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Progress scan available soon")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
            }

            Spacer()

            HStack(spacing: 4) {
                countdownPill(value: scanCountdown.days, label: "d")
                countdownPill(value: scanCountdown.hours, label: "h")
                countdownPill(value: scanCountdown.minutes, label: "m")
            }
        }
        .padding(20)
    }

    private func countdownPill(value: Int, label: String) -> some View {
        HStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 8))
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
                Image(systemName: "viewfinder")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.primaryAccent, in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Scan Your Abs")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Ready to scan")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.success)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(20)
        }
        .buttonStyle(.plain)
    }

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
            return "Hours away. Keep pushing."
        } else if d == 1 {
            return "Tomorrow you scan. Train hard today."
        } else if d <= 3 {
            return "\(d) days out. Every rep counts."
        } else {
            return "\(d) days until your next scan."
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
        HStack(spacing: 14) {
            Image(systemName: "viewfinder")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.primaryAccent)
                .symbolEffect(.pulse, options: .repeating)

            VStack(alignment: .leading, spacing: 3) {
                Text("Take Your First Scan")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("Scan your abs to unlock your plan")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(20)
        .background(AppTheme.cardSurface, in: .rect(cornerRadius: 16))
    }

    private var scanReadyHypeCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: 44, height: 44)
                Image(systemName: "viewfinder")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Scan Ready")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("See your progress")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.success)
            }

            Spacer()

            Text("SCAN")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(AppTheme.primaryAccent, in: Capsule())
        }
        .padding(20)
        .background(AppTheme.cardSurface, in: .rect(cornerRadius: 16))
        .onAppear { hypePhase = true }
    }

    private var countdownHypeCard: some View {
        let d = scanCountdown.days
        let h = scanCountdown.hours
        let m = scanCountdown.minutes
        let totalSeconds = d * 86400 + h * 3600 + m * 60
        let progress = max(0, min(1.0, 1.0 - Double(totalSeconds) / (7.0 * 86400.0)))

        return VStack(spacing: 16) {
            HStack {
                Text("NEXT SCAN")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(1)
                Spacer()
                Text(scanHypeMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                countdownUnit(value: d, label: "DAYS")
                Text(":")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                countdownUnit(value: h, label: "HRS")
                Text(":")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                countdownUnit(value: m, label: "MIN")
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 4)
                    Capsule()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(20)
        .background(AppTheme.cardSurface, in: .rect(cornerRadius: 16))
    }

    private func countdownUnit(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.5)
        }
    }

    private var countdownDivider: some View {
        Text(":")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(AppTheme.muted)
    }

    private var dashboardStreakBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.badge.plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.orange)
                .symbolEffect(.pulse, options: .repeating)

            VStack(alignment: .leading, spacing: 3) {
                Text("You missed yesterday")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Your \(vm.previousStreakDays)-day streak is at risk. Go to Routine to save it.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.orange)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.orange.opacity(0.08), in: .rect(cornerRadius: AppTheme.cardCornerRadius))
        .onTapGesture {
            selectedTab = 0
        }
    }


    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        Button {
            showLeaderboard = true
        } label: {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("Leaderboard")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.muted)
                }
                .padding(.bottom, 18)

                VStack(spacing: 0) {
                    ForEach(Array(leaderboardPreviewMembers.prefix(3).enumerated()), id: \.element.id) { index, member in
                        HStack(spacing: 14) {
                            Text(leaderboardMedalEmoji(index))
                                .font(.system(size: 22))
                                .frame(width: 36, height: 36)

                            Text("#\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(leaderboardMedalColor(index))
                                .frame(width: 28)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.primaryAccent)
                                Text("\(member.score)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.vertical, 10)

                        if index < 2 {
                            Rectangle()
                                .fill(Color.white.opacity(0.04))
                                .frame(height: 1)
                        }
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 1)
                    .padding(.top, 4)

                HStack(spacing: 12) {
                    Text("#\(formatUserRank())")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.primaryAccent, in: Capsule())

                    if let profileImage = vm.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                    }

                    Text("You")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("\(abMaxxScore)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 14)
            }
            .padding(20)
            .background(AppTheme.cardSurface, in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func leaderboardMedalColor(_ index: Int) -> Color {
        switch index {
        case 0: return AppTheme.warning
        case 1: return Color(red: 0.7, green: 0.72, blue: 0.78)
        case 2: return AppTheme.orange
        default: return AppTheme.muted
        }
    }

    private func leaderboardMedalEmoji(_ index: Int) -> String {
        switch index {
        case 0: return "\u{1F451}"
        case 1: return "\u{1F948}"
        case 2: return "\u{1F949}"
        default: return ""
        }
    }

    private func formatUserRank() -> String {
        if let serverRank = liveUserRank {
            if serverRank >= 1000 {
                return String(format: "%.1fk", Double(serverRank) / 1000.0)
            }
            return "\(serverRank)"
        }
        let userScore = abMaxxScore
        let source = liveLeaderboardTop3.isEmpty ? LeaderboardMember.celebrities : liveLeaderboardTop3
        let higherCount = source.filter { $0.score > userScore }.count
        let rank = higherCount + 1
        if rank >= 1000 {
            return String(format: "%.1fk", Double(rank) / 1000.0)
        }
        return "\(rank)"
    }

    private func loadLeaderboardPreview() async {
        let members = await LeaderboardService.shared.fetchLeaderboard(limit: 3)
        liveLeaderboardTop3 = members
        let deviceId = DeviceIdentityService.shared.deviceId
        liveUserRank = await LeaderboardService.shared.fetchUserRank(deviceId: deviceId)
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
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct ActionCircleButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.1), in: Circle())
            Text(label)
                .font(.system(size: 12, weight: .medium))
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
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i < done ? color : Color.white.opacity(0.06))
                        .frame(width: 6, height: 6)
                }
            }
            Text("\(done)/\(total)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(done == total ? AppTheme.success : .white)
        }
    }
}
