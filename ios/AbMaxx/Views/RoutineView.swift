import SwiftUI

enum RestDaySection: String, CaseIterable, Sendable {
    case recovery = "Recovery"
    case nutrition = "Nutrition"
    case posing = "Posing"

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .recovery: return "figure.cooldown"
        case .nutrition: return "fork.knife"
        case .posing: return "figure.stand"
        }
    }

    var color: Color {
        switch self {
        case .recovery: return AppTheme.success
        case .nutrition: return AppTheme.orange
        case .posing: return AppTheme.purple
        }
    }
}

private extension Array where Element == Bool {
    subscript(safe index: Int) -> Bool? {
        get { indices.contains(index) ? self[index] : nil }
        set {
            guard indices.contains(index), let val = newValue else { return }
            self[index] = val
        }
    }
}

enum SessionIntensity: String, CaseIterable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var icon: String {
        switch self {
        case .easy: return "flame"
        case .medium: return "flame.fill"
        case .hard: return "flame.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .easy: return AppTheme.success
        case .medium: return AppTheme.warning
        case .hard: return AppTheme.destructive
        }
    }

    var repMultiplierLabel: String {
        switch self {
        case .easy: return "Lighter load"
        case .medium: return "Standard sets & reps"
        case .hard: return "Extra volume + 1 bonus exercise"
        }
    }

    func adjustedReps(for original: String) -> String {
        switch self {
        case .easy:
            return reduceReps(original)
        case .medium:
            return original
        case .hard:
            return increaseReps(original)
        }
    }

    private func reduceReps(_ reps: String) -> String {
        var result = reps
        let patterns: [(String, String)] = [
            ("× 3 sets", "× 2 sets"),
            ("x 3 sets", "x 2 sets"),
            ("× 3 Sets", "× 2 Sets"),
        ]
        for (find, replace) in patterns {
            result = result.replacingOccurrences(of: find, with: replace)
        }
        if let range = result.range(of: #"\d+"#, options: .regularExpression) {
            if let num = Int(result[range]) {
                let reduced = max(Int(Double(num) * 0.7), 5)
                result = result.replacingCharacters(in: range, with: "\(reduced)")
            }
        }
        return result
    }

    private func increaseReps(_ reps: String) -> String {
        var result = reps
        let patterns: [(String, String)] = [
            ("× 3 sets", "× 4 sets"),
            ("x 3 sets", "x 4 sets"),
            ("× 2 sets", "× 3 sets"),
            ("x 2 sets", "x 3 sets"),
        ]
        for (find, replace) in patterns {
            result = result.replacingOccurrences(of: find, with: replace)
        }
        if let range = result.range(of: #"\d+"#, options: .regularExpression) {
            if let num = Int(result[range]) {
                let increased = Int(Double(num) * 1.25)
                result = result.replacingCharacters(in: range, with: "\(increased)")
            }
        }
        return result
    }
}

struct RoutineView: View {
    @Bindable var vm: AppViewModel
    var selectedTab: Int = 0
    @State private var selectedExercise: Exercise?
    @State private var showWorkoutSession: Bool = false
    @State private var selectedFeel: FeelCheck? = nil
    @State private var selectedDifficulty: DifficultyLevel? = nil
    @State private var difficultyAnimating: Bool = false
    @State private var animatedExerciseIndices: Set<Int> = []
    @State private var previousDifficulty: DifficultyLevel? = nil
    @State private var showWorkoutHistory: Bool = false
    @State private var showWeeklyPlan: Bool = false
    @State private var aiCounterActivated: Bool = false
    @State private var burstParticles: [BurstParticle] = []
    @State private var showCoachTip: Bool = false
    @State private var coachTipDismissed: Bool = false
    @State private var coachTipAppear: Bool = false
    @State private var showAICounterToast: Bool = false
    @State private var aiToastIsEnabled: Bool = false

    @State private var restChecks: [Bool] = [false, false, false, false]

    private var completedCount: Int {
        displayExercises.filter { vm.completedExercises.contains($0.id) }.count
    }

    private var totalCount: Int {
        displayExercises.count
    }

    private var allCompleted: Bool {
        totalCount > 0 && completedCount == totalCount
    }

    private var estimatedMinutes: Int {
        estimateSessionMinutes(for: displayExercises)
    }

    private func estimateSessionMinutes(for exercises: [Exercise]) -> Int {
        var totalSeconds: Double = 0
        let restBetweenSets: Double = 30
        let restBetweenExercises: Double = 45

        for exercise in exercises {
            let reps = exercise.reps
            let (setTime, sets) = parseExerciseTime(reps)
            totalSeconds += setTime * Double(sets)
            totalSeconds += restBetweenSets * Double(max(sets - 1, 0))
            totalSeconds += restBetweenExercises
        }

        return max(Int(ceil(totalSeconds / 60.0)), 1)
    }

    private func parseExerciseTime(_ reps: String) -> (Double, Int) {
        let lower = reps.lowercased()
        let sets = extractSets(from: lower)
        let isEachSide = lower.contains("each side")
        let sideMultiplier: Double = isEachSide ? 2.0 : 1.0

        if let secRange = lower.range(of: #"(\d+)\s*sec"#, options: .regularExpression) {
            let numStr = lower[secRange].filter { $0.isNumber }
            if let sec = Double(numStr) {
                return (sec * sideMultiplier, sets)
            }
        }

        if let repRange = lower.range(of: #"(\d+)"#, options: .regularExpression) {
            let numStr = lower[repRange].filter { $0.isNumber }
            if let repCount = Double(numStr) {
                let secPerRep: Double = 3.0
                return (repCount * secPerRep * sideMultiplier, sets)
            }
        }

        return (45, sets)
    }

    private func extractSets(from text: String) -> Int {
        if let range = text.range(of: #"(\d+)\s*set"#, options: .regularExpression) {
            let numStr = text[range].filter { $0.isNumber }
            if let s = Int(numStr) { return s }
        }
        return 3
    }

    private var currentWeek: Int {
        (vm.programDayNumber - 1) / 7 + 1
    }

    private var displayExercises: [Exercise] {
        let _ = vm.exerciseRefreshTrigger
        return vm.displayExercisesWithDifficulty
    }

    private var sortedExercises: [Exercise] {
        let exercises = displayExercises
        let incomplete = exercises.filter { !vm.completedExercises.contains($0.id) }
        let completed = exercises.filter { vm.completedExercises.contains($0.id) }
        return incomplete + completed
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    if vm.missedYesterday && !vm.streakRecoveredToday {
                        streakRecoveryBanner
                            .padding(.horizontal, 20)
                    }

                    if vm.isTodayRestDay {
                        RestDayFullView(vm: vm)
                    } else {
                        difficultySelector
                            .padding(.horizontal, 20)

                        sessionCard
                            .padding(.horizontal, 20)

                        aiCounterToggle
                            .padding(.horizontal, 20)

                        exercisesList
                            .padding(.horizontal, 20)
                    }

                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .premiumBackground()
            .safeAreaInset(edge: .bottom) {
                if showCoachTip && !allCompleted && !coachTipDismissed && !vm.isTodayRestDay {
                    coachTipBanner
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedFeel = vm.todayFeelCheck
                selectedDifficulty = vm.currentDifficulty
                restChecks = vm.restDayCheckboxes()
                triggerCoachTip()
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == 0 {
                    triggerCoachTip()
                }
            }
            .onChange(of: allCompleted) { _, completed in
                if completed {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCoachTip = false
                    }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailSheet(
                    exercise: exercise,
                    isCompleted: vm.completedExercises.contains(exercise.id),
                    onComplete: {
                        vm.completeExercise(exercise.id)
                    },
                    onSwap: {
                        if let idx = vm.todaysExercises.firstIndex(where: { $0.id == exercise.id }) {
                            vm.swapExercise(at: idx)
                            selectedExercise = nil
                        }
                    },
                    regionScore: vm.zoneScoreForRegion(exercise.region)
                )
            }
            .sheet(isPresented: $showWorkoutHistory) {
                WorkoutHistoryView(vm: vm)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(hex: "0D0D0D"))
            }
            .sheet(isPresented: $showWeeklyPlan) {
                WeeklyPlanSheet(vm: vm, currentWeek: currentWeek)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(hex: "0D0D0D"))
            }
            .overlay(alignment: .top) {
                if showAICounterToast {
                    HStack(spacing: 8) {
                        Image(systemName: aiToastIsEnabled ? "camera.fill" : "camera.slash.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(aiToastIsEnabled ? AppTheme.primaryAccent : AppTheme.muted)
                        Text(aiToastIsEnabled ? "AI Rep Counter On" : "AI Rep Counter Off")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(aiToastIsEnabled ? .white : AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(AppTheme.cardSurfaceElevated)
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        aiToastIsEnabled ? AppTheme.primaryAccent.opacity(0.45) : AppTheme.border,
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: aiToastIsEnabled ? AppTheme.primaryAccent.opacity(0.25) : .black.opacity(0.4), radius: 16, y: 4)
                    )
                    .padding(.top, 12)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                        removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9))
                    ))
                }
            }
            .fullScreenCover(isPresented: $showWorkoutSession) {
                WorkoutSessionView(
                    exercises: displayExercises,
                    completedExercises: vm.completedExercises,
                    onComplete: { id in
                        vm.completeExercise(id)
                    },
                    daysUntilNextScan: vm.daysUntilNextScan,
                    hoursUntilNextScan: vm.timeUntilNextScan.hours,
                    canScan: vm.canScan,
                    currentScore: vm.latestScan?.overallScore ?? 0,
                    difficulty: vm.currentDifficulty ?? .medium,
                    weakestZone: vm.weakestZoneFromScan,
                    initialAICounterEnabled: vm.aiCounterEnabled,
                    zoneScores: [
                        .upperAbs: vm.zoneScoreForRegion(.upperAbs),
                        .lowerAbs: vm.zoneScoreForRegion(.lowerAbs),
                        .obliques: vm.zoneScoreForRegion(.obliques),
                        .deepCore: vm.zoneScoreForRegion(.deepCore)
                    ]
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Routine")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 8) {
                Button { showWorkoutHistory = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.card)
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                }

                Button { showWeeklyPlan = true } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.card)
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Difficulty Selector

    @State private var difficultyBounce: Bool = false
    @State private var selectedPulse: Bool = false

    private var difficultySelector: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    let isSelected = selectedDifficulty == level
                    let color = difficultyColor(level)
                    Button {
                        guard !vm.difficultyLockedForToday else { return }
                        guard selectedDifficulty != level else { return }
                        previousDifficulty = selectedDifficulty
                        withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                            selectedDifficulty = level
                            vm.saveDifficulty(level)
                            difficultyBounce.toggle()
                        }
                        withAnimation(.easeInOut(duration: 0.8).repeatCount(2, autoreverses: true)) {
                            selectedPulse = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            selectedPulse = false
                        }
                        triggerRippleAnimation()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.04))
                                    .frame(width: 42, height: 42)
                                Circle()
                                    .strokeBorder(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                    .frame(width: 42, height: 42)
                                Image(systemName: difficultyIcon(level))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(isSelected ? color : AppTheme.muted)
                                    .symbolEffect(.bounce, value: isSelected ? difficultyBounce : false)
                            }

                            Text(level.rawValue)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)

                            Text(difficultyRepsLabel(level))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isSelected ? color : AppTheme.muted.opacity(0.7))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 4)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isSelected ? color.opacity(0.08) : Color.white.opacity(0.03))
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        isSelected ? color.opacity(0.4) : AppTheme.border,
                                        lineWidth: isSelected ? 1.5 : 0.5
                                    )
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(color.opacity(selectedPulse ? 0.12 : 0.04))
                                }
                            }
                        )
                        .scaleEffect(isSelected ? 1.03 : 0.97)
                        .shadow(color: isSelected ? color.opacity(0.25) : .clear, radius: 12, y: 4)
                    }
                    .disabled(vm.difficultyLockedForToday)
                    .opacity(vm.difficultyLockedForToday && selectedDifficulty != level ? 0.35 : 1.0)
                    .sensoryFeedback(.impact(weight: level == .hard ? .heavy : .light), trigger: selectedDifficulty)
                }
            }

            if let sel = selectedDifficulty {
                HStack(spacing: 0) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        let isCurrent = sel == level
                        let isPast = DifficultyLevel.allCases.firstIndex(of: level)! < DifficultyLevel.allCases.firstIndex(of: sel)!
                        Rectangle()
                            .fill(isCurrent ? difficultyColor(sel) : (isPast ? difficultyColor(sel).opacity(0.3) : Color.white.opacity(0.06)))
                            .frame(height: 3)
                    }
                }
                .clipShape(Capsule())
                .padding(.horizontal, 4)
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.2), value: selectedDifficulty)
    }



    // MARK: - Session Card

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.todayTargetLabel)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    HStack(spacing: 12) {
                        Label("~\(estimatedMinutes) min", systemImage: "clock")
                        Label("\(totalCount) exercises", systemImage: "dumbbell.fill")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Text("\(completedCount)/\(totalCount)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Button {
                showWorkoutSession = true
            } label: {
                HStack {
                    Text(allCompleted ? "Session Complete" : "Start Session")
                        .font(.system(size: 19, weight: .bold))
                    Spacer()
                    Image(systemName: allCompleted ? "checkmark" : "play.fill")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(allCompleted ? AppTheme.success : AppTheme.primaryAccent)
                .clipShape(.rect(cornerRadius: 14))
            }
            .disabled(allCompleted)
            .sensoryFeedback(.impact(weight: .medium), trigger: showWorkoutSession)
        }
        .padding(16)
        .background(AppTheme.card, in: .rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
    }

    private var regionTags: some View {
        let (r1, r2) = vm.todayTargetRegions
        let regions = [r1, r2]
        return HStack(spacing: 6) {
            ForEach(regions, id: \.self) { region in
                Text(region.rawValue)
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .foregroundStyle(regionColor(region))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(regionColor(region).opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Coach Tip Trigger

    private func triggerCoachTip() {
        coachTipDismissed = false
        showCoachTip = false
        coachTipAppear = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.spring(duration: 0.6, bounce: 0.25)) {
                showCoachTip = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    coachTipAppear = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    coachTipAppear = false
                    showCoachTip = false
                }
            }
        }
    }

    // MARK: - Coach Note

    private var coachNoteCard: some View {
        EmptyView()
    }

    private var coachTipBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.primaryAccent)

            Text(vm.coachTip)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.cardSurfaceElevated
                .shadow(.drop(color: AppTheme.primaryAccent.opacity(0.15), radius: 12, y: 4))
        )
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.primaryAccent.opacity(0.2), lineWidth: 0.5)
        )
        .scaleEffect(coachTipAppear ? 1.0 : 0.92)
        .opacity(coachTipAppear ? 1.0 : 0)
        .sensoryFeedback(.impact(weight: .light), trigger: showCoachTip)
    }

    // MARK: - Streak Recovery Banner

    private var streakRecoveryBanner: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "flame.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.orange)
                    .symbolEffect(.pulse, options: .repeating)

                VStack(alignment: .leading, spacing: 3) {
                    Text("You missed yesterday")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Your \(vm.previousStreakDays)-day streak is at risk")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.orange)
                }

                Spacer()
            }

            Button {
                vm.recoverStreak()
                showWorkoutSession = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Quick 5-min session to save your streak")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.orange)
                .clipShape(.rect(cornerRadius: 12))
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showWorkoutSession)
        }
        .padding(20)
        .background(AppTheme.orange.opacity(0.08), in: .rect(cornerRadius: 18))
    }

    // MARK: - Dead code removed (restDayCard was unused - RestDayFullView is used instead)

    // MARK: - AI Counter Toggle

    private var aiCounterToggle: some View {
        Button {
            let wasEnabled = vm.aiCounterEnabled
            vm.toggleAICounter()
            if !wasEnabled {
                triggerBurstAnimation()
            }
            aiToastIsEnabled = !wasEnabled
            withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                showAICounterToast = true
            }
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(.easeOut(duration: 0.3)) {
                    showAICounterToast = false
                }
            }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Image(systemName: vm.aiCounterEnabled ? "camera.fill" : "camera")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(vm.aiCounterEnabled ? AppTheme.primaryAccent : AppTheme.muted)
                        .symbolEffect(.bounce, value: aiCounterActivated)
                }

                Text("AI Rep Counter")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(vm.aiCounterEnabled ? .white : AppTheme.secondaryText)

                Spacer()

                ZStack {
                    Capsule()
                        .fill(vm.aiCounterEnabled ? AppTheme.primaryAccent : Color.white.opacity(0.08))
                        .frame(width: 40, height: 24)
                    Circle()
                        .fill(.white)
                        .frame(width: 18, height: 18)
                        .offset(x: vm.aiCounterEnabled ? 8 : -8)
                        .animation(.spring(duration: 0.3, bounce: 0.25), value: vm.aiCounterEnabled)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(vm.aiCounterEnabled ? AppTheme.primaryAccent.opacity(0.08) : Color.white.opacity(0.03))
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(vm.aiCounterEnabled ? AppTheme.primaryAccent.opacity(0.25) : AppTheme.border, lineWidth: 0.5)
                }
            )
            .overlay {
                if !burstParticles.isEmpty {
                    GeometryReader { geo in
                        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                        ForEach(burstParticles) { particle in
                            Circle()
                                .fill(particle.color)
                                .frame(width: particle.size, height: particle.size)
                                .scaleEffect(particle.active ? 0.01 : 1)
                                .opacity(particle.active ? 0 : 1)
                                .offset(
                                    x: center.x + (particle.active ? particle.endX : 0) - particle.size / 2,
                                    y: center.y + (particle.active ? particle.endY : 0) - particle.size / 2
                                )
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: vm.aiCounterEnabled)
    }

    private func triggerBurstAnimation() {
        let colors: [Color] = [
            AppTheme.primaryAccent,
            AppTheme.primaryAccent.opacity(0.7),
            Color.white,
            AppTheme.primaryAccent.opacity(0.5),
        ]
        var particles: [BurstParticle] = []
        for i in 0..<12 {
            let angle = Double(i) * (360.0 / 12.0) * .pi / 180.0
            let distance = Double.random(in: 40...80)
            particles.append(BurstParticle(
                endX: cos(angle) * distance,
                endY: sin(angle) * distance,
                size: CGFloat.random(in: 3...6),
                color: colors[i % colors.count],
                active: false
            ))
        }
        burstParticles = particles
        aiCounterActivated.toggle()

        withAnimation(.easeOut(duration: 0.5)) {
            for i in burstParticles.indices {
                burstParticles[i].active = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            burstParticles = []
        }
    }

    // MARK: - Exercises List

    private var exercisesList: some View {
        VStack(spacing: 14) {
            ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                let isCompleted = vm.completedExercises.contains(exercise.id)
                Button {
                    selectedExercise = exercise
                } label: {
                    exerciseRow(exercise: exercise, isCompleted: isCompleted, index: index)
                }
            }
            .animation(.spring(duration: 0.4, bounce: 0.15), value: vm.completedExercises)
        }
    }

    private func triggerRippleAnimation() {
        animatedExerciseIndices = []
        difficultyAnimating = true
        let count = sortedExercises.count
        for i in 0..<count {
            let delay = Double(i) * 0.06
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + delay) {
                withAnimation(.spring(duration: 0.55, bounce: 0.35)) {
                    _ = animatedExerciseIndices.insert(i)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(count) * 0.06 + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                difficultyAnimating = false
                animatedExerciseIndices = []
            }
        }
    }

    private func exerciseRow(exercise: Exercise, isCompleted: Bool, index: Int = 0) -> some View {
        let isAnimating = animatedExerciseIndices.contains(index)
        let accentColor = difficultyColor(selectedDifficulty ?? .medium)
        let stripeColor = exerciseStripeColor(exercise.region)

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(stripeColor)
                .frame(width: 3, height: 38)

            ExerciseImageView(exercise: exercise, size: 38, regionScore: vm.zoneScoreForRegion(exercise.region))
                .clipShape(.rect(cornerRadius: 10))
                .scaleEffect(isAnimating ? 1.08 : 1.0)

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(vm.progressiveRepsString(for: exercise))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        isAnimating ? accentColor : AppTheme.muted
                    )
                    .contentTransition(.numericText())
            }

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.success)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "333333"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            isAnimating
                ? accentColor.opacity(0.06)
                : AppTheme.cardSolid
        )
        .clipShape(.rect(cornerRadius: AppTheme.nestedCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.nestedCornerRadius)
                .strokeBorder(isAnimating ? accentColor.opacity(0.3) : AppTheme.cardBorderSolid, lineWidth: 1)
        )
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .contentShape(Rectangle())
    }

    private func exerciseStripeColor(_ region: AbRegion) -> Color {
        AppTheme.subscoreColor(for: vm.zoneScoreForRegion(region))
    }


    // MARK: - Helpers

    private func regionColor(_ region: AbRegion) -> Color {
        AppTheme.subscoreColor(for: vm.zoneScoreForRegion(region))
    }

    private func difficultyIcon(_ level: DifficultyLevel) -> String {
        switch level {
        case .easy: return "hare"
        case .medium: return "flame.fill"
        case .hard: return "bolt.fill"
        }
    }

    private func difficultyColor(_ level: DifficultyLevel) -> Color {
        switch level {
        case .easy: return AppTheme.success
        case .medium: return AppTheme.primaryAccent
        case .hard: return AppTheme.destructive
        }
    }

    private func difficultyRepsLabel(_ level: DifficultyLevel) -> String {
        switch level {
        case .easy: return "−3 reps · −1 set"
        case .medium: return "Standard"
        case .hard: return "+3 reps · +1 set"
        }
    }

    private func difficultySubtitle(_ level: DifficultyLevel) -> String {
        switch level {
        case .easy: return "Lighter load — fewer sets & reps"
        case .medium: return "Standard sets & reps"
        case .hard: return "Extra volume + bonus exercise"
        }
    }


}

struct BurstParticle: Identifiable {
    let id: UUID = UUID()
    let endX: Double
    let endY: Double
    let size: CGFloat
    let color: Color
    var active: Bool
}

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    let isCompleted: Bool
    let onComplete: () -> Void
    var onSwap: (() -> Void)? = nil
    var regionScore: Int = 0
    @Environment(\.dismiss) private var dismiss

    private var detailInfo: ExerciseDetailInfo {
        ExerciseDetailData.info(for: exercise.id)
    }

    private var regionColor: Color {
        AppTheme.subscoreColor(for: regionScore)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    headerImageSection
                    titleAndTagsSection
                    whyThisExerciseSection
                    howToDoItSection
                    musclesWorkedSection
                    completeButton
                    Color.clear.frame(height: 40)
                }
            }
            .scrollIndicators(.hidden)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .padding(.top, 12)
            .padding(.trailing, 20)
        }
        .background(AppTheme.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color(hex: "0D0D0D"))
        .presentationContentInteraction(.scrolls)
    }

    private var headerImageSection: some View {
        VStack(spacing: 0) {
            ExerciseFormGuideView(exercise: exercise, showFullGuide: true, regionScore: regionScore)
                .frame(height: 340)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            HStack(spacing: 8) {
                Text(exercise.region.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(regionColor)
                    .clipShape(Capsule())

                if exercise.equipment != .none {
                    HStack(spacing: 4) {
                        Image(systemName: exercise.equipment == .gym ? "dumbbell.fill" : "figure.strengthtraining.traditional")
                            .font(.system(size: 11, weight: .bold))
                        Text(exercise.equipmentLabel)
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.warning)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.warning.opacity(0.12))
                    .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }

    private var exercisePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: exercise.region.icon)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(AppTheme.primaryAccent.opacity(0.5))
            Text(exercise.name)
                .font(.headline)
                .foregroundStyle(AppTheme.muted)
        }
    }

    private var titleAndTagsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(exercise.name)
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                Text(exercise.reps)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                    )

                Text(exercise.region.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(regionColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(
                        Capsule()
                            .strokeBorder(regionColor.opacity(0.4), lineWidth: 1)
                    )

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("AI Selected")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(AppTheme.primaryAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    Capsule()
                        .strokeBorder(AppTheme.primaryAccent.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var whyThisExerciseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("WHY THIS EXERCISE")
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(1)

                Spacer()

                if let onSwap {
                    Button {
                        onSwap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Swap")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.04))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(AppTheme.border, lineWidth: 1)
                        )
                    }
                }
            }

            Text(exercise.instructions)
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(5)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var howToDoItSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("HOW TO DO IT")
                .font(.caption.weight(.black))
                .foregroundStyle(AppTheme.muted)
                .tracking(1)

            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.primaryAccent)
                            .clipShape(Circle())

                        Text(step)
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }

    private var musclesWorkedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MUSCLES WORKED")
                .font(.caption.weight(.black))
                .foregroundStyle(AppTheme.muted)
                .tracking(1)

            let primaryNames = Set(detailInfo.focusMuscles.filter(\.isPrimary).map(\.name))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], alignment: .leading, spacing: 10) {
                ForEach(exercise.musclesWorked, id: \.self) { muscle in
                    let isPrimary = primaryNames.contains(muscle)
                    HStack(spacing: 6) {
                        Text(muscle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(isPrimary ? 1 : 0.6))
                        if isPrimary {
                            Circle()
                                .fill(AppTheme.success)
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isPrimary ? Color.white.opacity(0.04) : AppTheme.cardSurface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isPrimary ? AppTheme.border.opacity(0.3) : AppTheme.border.opacity(0.15),
                                lineWidth: 1
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }

    private var completeButton: some View {
        Button {
            onComplete()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Text(isCompleted ? "Completed" : "Mark Complete")
                    .font(.headline.weight(.bold))
                if !isCompleted {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                }
            }
            .foregroundStyle(isCompleted ? AppTheme.muted : AppTheme.success)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                isCompleted
                    ? AppTheme.muted.opacity(0.15)
                    : AppTheme.success.opacity(0.08)
            )
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isCompleted ? AppTheme.muted.opacity(0.3) : AppTheme.success.opacity(0.4),
                        lineWidth: 1.5
                    )
            )
        }
        .disabled(isCompleted)
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }
}
