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
        case .posing: return Color(red: 0.6, green: 0.4, blue: 1.0)
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
    @State private var selectedExercise: Exercise?
    @State private var showWorkoutSession: Bool = false
    @State private var selectedFeel: FeelCheck? = nil
    @State private var selectedDifficulty: DifficultyLevel? = nil
    @State private var difficultyAnimating: Bool = false
    @State private var animatedExerciseIndices: Set<Int> = []
    @State private var previousDifficulty: DifficultyLevel? = nil
    @State private var showWorkoutHistory: Bool = false
    @State private var showWeeklyPlan: Bool = false

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
        vm.displayExercisesWithDifficulty
    }

    private var sortedExercises: [Exercise] {
        let exercises = displayExercises
        let incomplete = exercises.filter { !vm.completedExercises.contains($0.id) }
        let completed = exercises.filter { vm.completedExercises.contains($0.id) }
        return incomplete + completed
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        if vm.missedYesterday && !vm.streakRecoveredToday {
                            streakRecoveryBanner
                                .padding(.horizontal, 16)
                        }

                        if vm.isTodayRestDay {
                            RestDayFullView(vm: vm)
                        } else {
                            difficultySelector
                                .padding(.horizontal, 16)

                            sessionCard
                                .padding(.horizontal, 16)

                            coachNoteCard
                                .padding(.horizontal, 16)

                            exercisesList
                                .padding(.horizontal, 16)
                        }

                    }
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedFeel = vm.todayFeelCheck
                selectedDifficulty = vm.currentDifficulty
                restChecks = vm.restDayCheckboxes()
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailSheet(
                    exercise: exercise,
                    isCompleted: vm.completedExercises.contains(exercise.id),
                    onComplete: {
                        vm.completeExercise(exercise.id, xp: exercise.xp)
                    },
                    onSwap: {
                        if let idx = vm.todaysExercises.firstIndex(where: { $0.id == exercise.id }) {
                            vm.swapExercise(at: idx)
                            selectedExercise = nil
                        }
                    }
                )
            }
            .sheet(isPresented: $showWorkoutHistory) {
                WorkoutHistoryView(vm: vm)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppTheme.background)
            }
            .sheet(isPresented: $showWeeklyPlan) {
                WeeklyPlanSheet(vm: vm, currentWeek: currentWeek)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppTheme.background)
            }
            .fullScreenCover(isPresented: $showWorkoutSession) {
                WorkoutSessionView(
                    exercises: displayExercises,
                    completedExercises: vm.completedExercises,
                    onComplete: { id, xp in
                        vm.completeExercise(id, xp: xp)
                    },
                    daysUntilNextScan: vm.daysUntilNextScan,
                    hoursUntilNextScan: vm.timeUntilNextScan.hours,
                    canScan: vm.canScan,
                    currentScore: vm.latestScan?.overallScore ?? 0,
                    difficulty: vm.currentDifficulty ?? .medium,
                    weakestZone: vm.weakestZoneFromScan
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Your Routine")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Button { showWorkoutHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.cardSurfaceElevated)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1))
            }

            Button { showWeeklyPlan = true } label: {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.primaryAccent.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(AppTheme.primaryAccent.opacity(0.25), lineWidth: 1))
            }
        }
    }

    // MARK: - Difficulty Selector

    private var difficultySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DIFFICULTY LEVEL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(1)

                Spacer()

                if vm.difficultyLockedForToday {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("LOCKED")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.cardSurfaceElevated)
                    .clipShape(Capsule())
                }
            }

            HStack(spacing: 8) {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    Button {
                        guard !vm.difficultyLockedForToday else { return }
                        guard selectedDifficulty != level else { return }
                        previousDifficulty = selectedDifficulty
                        withAnimation(.spring(duration: 0.4, bounce: 0.25)) {
                            selectedDifficulty = level
                            vm.saveDifficulty(level)
                        }
                        triggerRippleAnimation()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: difficultyIcon(level))
                                .font(.system(size: 13, weight: .bold))
                                .symbolEffect(.bounce, value: selectedDifficulty == level)
                            Text(level.rawValue)
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(selectedDifficulty == level ? .white : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            selectedDifficulty == level
                                ? AnyShapeStyle(difficultyColor(level).opacity(0.25))
                                : AnyShapeStyle(AppTheme.cardSurface)
                        )
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    selectedDifficulty == level ? difficultyColor(level).opacity(0.6) : AppTheme.border,
                                    lineWidth: selectedDifficulty == level ? 1.5 : 1
                                )
                        )
                        .scaleEffect(selectedDifficulty == level ? 1.02 : 1.0)
                    }
                    .disabled(vm.difficultyLockedForToday)
                    .opacity(vm.difficultyLockedForToday && selectedDifficulty != level ? 0.4 : 1.0)
                    .sensoryFeedback(.impact(weight: level == .hard ? .heavy : .light), trigger: selectedDifficulty)
                }
            }

            if let level = selectedDifficulty {
                Text(difficultySubtitle(level))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(difficultyColor(level))
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.35), value: selectedDifficulty)

    }



    // MARK: - Session Card

    private var sessionCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("TODAY'S SESSION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .tracking(1)
                    Spacer()
                    Text("\(completedCount)/\(totalCount) done")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Text(vm.todayTargetLabel)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Label("\(estimatedMinutes) min", systemImage: "clock")
                    Label("\(totalCount) exercises", systemImage: "figure.core.training")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)

                regionTags
            }
            .padding(16)

            Button {
                showWorkoutSession = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: allCompleted ? "checkmark.circle.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(allCompleted ? "Session Complete" : "Start Session")
                        .font(.system(size: 16, weight: .bold))
                    if !allCompleted {
                        Text("AI reps")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    allCompleted
                        ? AnyShapeStyle(AppTheme.success)
                        : AnyShapeStyle(AppTheme.primaryAccent)
                )
            }
            .disabled(allCompleted)
            .sensoryFeedback(.impact(weight: .medium), trigger: showWorkoutSession)
        }
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.primaryAccent.opacity(0.15), lineWidth: 1)
        )
    }

    private var regionTags: some View {
        let (r1, r2) = vm.todayTargetRegions
        let regions = [r1, r2]
        return HStack(spacing: 6) {
            ForEach(regions, id: \.self) { region in
                Text(region.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(regionColor(region))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(regionColor(region).opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Coach Note

    private var coachNoteCard: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppTheme.success)
                .frame(width: 4)

            Text(vm.coachNote)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Streak Recovery Banner

    private var streakRecoveryBanner: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
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
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Your \(vm.previousStreakDays)-day streak is at risk")
                        .font(.system(size: 13, weight: .medium))
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
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.orange)
                .clipShape(.rect(cornerRadius: 12))
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showWorkoutSession)
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
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppTheme.orange.opacity(0.3), lineWidth: 1.5)
        )
    }

    // MARK: - Rest Day

    @State private var restDaySection: RestDaySection = .recovery

    private var restDayCard: some View {
        VStack(spacing: 0) {
            restDayHeader
            restDaySectionPicker
                .padding(.top, 16)

            switch restDaySection {
            case .recovery:
                activeRecoverySection
                    .padding(.top, 16)
            case .nutrition:
                nutritionFocusSection
                    .padding(.top, 16)
            case .posing:
                posingGuideSection
                    .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    private var restDayHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.success)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Rest Day")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Abs grow during recovery — make today count")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
    }

    private var restDaySectionPicker: some View {
        HStack(spacing: 6) {
            ForEach(RestDaySection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.spring(duration: 0.3)) { restDaySection = section }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: section.icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(section.title)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(restDaySection == section ? .white : AppTheme.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(
                        restDaySection == section
                            ? AnyShapeStyle(section.color.opacity(0.25))
                            : AnyShapeStyle(AppTheme.cardSurfaceElevated)
                    )
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                restDaySection == section ? section.color.opacity(0.5) : AppTheme.border,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
        .sensoryFeedback(.selection, trigger: restDaySection)
    }

    private var activeRecoverySection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("5-MIN STRETCH ROUTINE")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(AppTheme.success)
                    .tracking(1)
                Spacer()
                Text("~5 min")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
            }

            ForEach(Array(stretchRoutine.enumerated()), id: \.offset) { index, stretch in
                Button {
                    restChecks[safe: index]?.toggle()
                    vm.saveRestDayCheckboxes(restChecks)
                } label: {
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .foregroundStyle(restChecks[safe: index] == true ? .white : AppTheme.success)
                            .frame(width: 24, height: 24)
                            .background(
                                restChecks[safe: index] == true
                                    ? AppTheme.success
                                    : AppTheme.success.opacity(0.12)
                            )
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stretch.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(restChecks[safe: index] == true ? .white : AppTheme.secondaryText)
                            Text(stretch.duration)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.muted)
                        }

                        Spacer()

                        if restChecks[safe: index] == true {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(AppTheme.success)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(12)
                    .background(
                        restChecks[safe: index] == true
                            ? AppTheme.success.opacity(0.06)
                            : AppTheme.cardSurfaceElevated
                    )
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                restChecks[safe: index] == true ? AppTheme.success.opacity(0.3) : AppTheme.border,
                                lineWidth: 1
                            )
                    )
                }
                .sensoryFeedback(.impact(weight: .light), trigger: restChecks[safe: index] ?? false)
            }

            let done = restChecks.filter { $0 }.count
            if done == restChecks.count {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                    Text("Recovery routine complete — your abs thank you")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.success)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(AppTheme.success.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: restChecks)
    }

    private var nutritionFocusSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.orange.opacity(0.6))
                Text("Rest days are when abs grow — hit your protein today")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .italic()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.orange.opacity(0.08))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppTheme.orange.opacity(0.2), lineWidth: 1)
            )

            ForEach(nutritionRestTips, id: \.title) { tip in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(tip.color.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: tip.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tip.color)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(tip.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text(tip.detail)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(12)
                .background(AppTheme.cardSurfaceElevated)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
            }

            if vm.dailyNutrition.proteinGoal > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Protein Target")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(Int(vm.totalProteinToday))g / \(Int(vm.dailyNutrition.proteinGoal))g")
                            .font(.system(size: 20, weight: .black, design: .default))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(AppTheme.border, lineWidth: 5)
                            .frame(width: 50, height: 50)
                        Circle()
                            .trim(from: 0, to: vm.proteinProgress)
                            .stroke(AppTheme.success, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(vm.proteinProgress * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.success)
                    }
                }
                .padding(14)
                .background(AppTheme.cardSurfaceElevated)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
            }
        }
    }

    private var posingGuideSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                Text("FLEX FRIDAY")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                    .tracking(1)
                Spacer()
                Text("Posing practice")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
            }

            Text("Bodybuilders practice posing on rest days — it builds mind-muscle connection and teaches you to flex each ab zone independently.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(4)

            ForEach(posingMoves, id: \.name) { pose in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: pose.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(pose.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text(pose.instruction)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    Text(pose.hold)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(12)
                .background(AppTheme.cardSurfaceElevated)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
            }
        }
    }

    private var stretchRoutine: [(name: String, duration: String)] {
        [
            ("Cat-Cow Stretch", "60 sec"),
            ("Cobra Stretch", "45 sec hold"),
            ("Seated Spinal Twist", "30 sec each side"),
            ("Hip Flexor Stretch", "30 sec each side"),
        ]
    }

    private var nutritionRestTips: [(title: String, detail: String, icon: String, color: Color)] {
        [
            ("Protein Priority", "Aim for 1g per lb of lean mass — muscle repair peaks on rest days", "fish.fill", AppTheme.success),
            ("Stay Hydrated", "Dehydrated muscles recover 40% slower — aim for 3L today", "drop.fill", Color(red: 0.3, green: 0.7, blue: 1.0)),
            ("Don't Cut Too Hard", "Eat at maintenance or small deficit — starving on rest days kills recovery", "fork.knife", AppTheme.orange),
        ]
    }

    private var posingMoves: [(name: String, instruction: String, icon: String, hold: String)] {
        [
            ("Front Double Abs", "Flex every ab segment — hold and breathe", "figure.arms.open", "10 sec"),
            ("Vacuum Pose", "Exhale fully, pull navel to spine, hold", "wind", "15 sec"),
            ("Side Oblique Crunch", "Flex and lean to show oblique separation", "figure.walk", "10 sec"),
        ]
    }

    // MARK: - Exercises List

    private var exercisesList: some View {
        VStack(spacing: 10) {
            HStack {
                Text("EXERCISES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(1)
                Spacer()
            }

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
            let delay = Double(i) * 0.07
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    _ = animatedExerciseIndices.insert(i)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(count) * 0.07 + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                difficultyAnimating = false
                animatedExerciseIndices = []
            }
        }
    }

    private func exerciseRow(exercise: Exercise, isCompleted: Bool, index: Int = 0) -> some View {
        HStack(spacing: 14) {
            ExerciseImageView(exercise: exercise, size: 56)
                .opacity(isCompleted ? 0.5 : 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isCompleted ? AppTheme.muted : .white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(vm.progressiveRepsString(for: exercise))
                        .font(.system(size: 13, weight: animatedExerciseIndices.contains(index) ? .bold : .medium))
                        .foregroundStyle(
                            animatedExerciseIndices.contains(index)
                                ? difficultyColor(selectedDifficulty ?? .medium)
                                : (isCompleted ? AppTheme.muted.opacity(0.5) : AppTheme.secondaryText)
                        )
                        .contentTransition(.numericText())

                    if animatedExerciseIndices.contains(index), let sel = selectedDifficulty {
                        Image(systemName: sel == .hard ? "arrow.up" : (sel == .easy ? "arrow.down" : "equal"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(difficultyColor(sel))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.success)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(14)
        .background(isCompleted ? AppTheme.success.opacity(0.06) : AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    animatedExerciseIndices.contains(index)
                        ? difficultyColor(selectedDifficulty ?? .medium).opacity(0.5)
                        : (isCompleted ? AppTheme.success.opacity(0.2) : AppTheme.border),
                    lineWidth: animatedExerciseIndices.contains(index) ? 1.5 : 1
                )
        )
        .scaleEffect(animatedExerciseIndices.contains(index) ? 1.02 : 1.0)
        .contentShape(Rectangle())
    }



    // MARK: - Helpers

    private func regionColor(_ region: AbRegion) -> Color {
        switch region {
        case .lowerAbs: return AppTheme.success
        case .obliques: return AppTheme.destructive
        case .deepCore: return Color(red: 0.6, green: 0.4, blue: 1.0)
        case .upperAbs: return AppTheme.primaryAccent
        }
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
        case .medium: return AppTheme.warning
        case .hard: return AppTheme.destructive
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



struct ExerciseDetailSheet: View {
    let exercise: Exercise
    let isCompleted: Bool
    let onComplete: () -> Void
    var onSwap: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    private var detailInfo: ExerciseDetailInfo {
        ExerciseDetailData.info(for: exercise.id)
    }

    private var regionColor: Color {
        switch exercise.region {
        case .upperAbs: return AppTheme.primaryAccent
        case .lowerAbs: return AppTheme.destructive
        case .obliques: return AppTheme.orange
        case .deepCore: return Color(red: 0.6, green: 0.4, blue: 1.0)
        }
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
        .presentationBackground(AppTheme.background)
        .presentationContentInteraction(.scrolls)
    }

    private var headerImageSection: some View {
        VStack(spacing: 0) {
            ExerciseFormGuideView(exercise: exercise, showFullGuide: true)
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
                            .font(.system(size: 9, weight: .bold))
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
                .font(.system(size: 28, weight: .black))
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
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.cardSurfaceElevated)
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
                    .background(isPrimary ? AppTheme.cardSurfaceElevated : AppTheme.cardSurface)
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
