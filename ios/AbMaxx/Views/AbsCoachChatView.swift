import SwiftUI

struct AbsCoachChatView: View {
    @Bindable var vm: AppViewModel
    @State private var messages: [CoachMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var showQuickQuestions: Bool = true
    @Environment(\.dismiss) private var dismiss

    private let quickQuestions: [String] = [
        "I'm lacking motivation",
        "What should I eat?",
        "How do I lose belly fat?",
        "Am I overtraining?"
    ]

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: Date())
    }

    private func shortDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func scanSummaryLine(for scan: ScanResult) -> String {
        "\(shortDateString(from: scan.date)): overall \(scan.overallScore), upper \(scan.upperAbsScore), lower \(scan.lowerAbsScore), obliques \(scan.obliquesScore), deep core \(scan.deepCoreScore), symmetry \(scan.symmetry), v taper \(scan.frame), body fat \(String(format: "%.1f", scan.estimatedBodyFat))%, structure \(scan.absStructure.rawValue)"
    }

    private func workoutSummaryLine(for workout: CompletedWorkout) -> String {
        let exerciseNames = workout.exercises.map(\.name).joined(separator: ", ")
        return "\(shortDateString(from: workout.date)): \(workout.targetLabel), difficulty \(workout.difficultyLevel), duration \(workout.durationMinutes) min, exercises: \(exerciseNames)"
    }

    private func exerciseSummaryLine(for exercise: Exercise) -> String {
        let status = vm.completedExercises.contains(exercise.id) ? "completed" : "pending"
        let reps = vm.progressiveRepsString(for: exercise)
        return "\(exercise.name) — zone \(exercise.region.rawValue), \(reps), difficulty \(exercise.difficulty.rawValue), equipment \(exercise.equipmentLabel), status \(status)"
    }

    private func planDaySummaryLine(for day: TrainingDay) -> String {
        let status: String = day.isCompleted ? "completed" : (day.isUnlocked ? "unlocked" : "locked")
        let title: String = day.isRestDay ? "Rest Day" : "Training Day \(day.dayNumber)"
        let exerciseNames = vm.exercisesForDay(day).map(\.name).joined(separator: ", ")
        if exerciseNames.isEmpty {
            return "\(title) — \(status)"
        }
        return "\(title) — \(status), exercises: \(exerciseNames)"
    }

    private var userContext: String {
        var parts: [String] = []
        let p = vm.profile
        let latestScan = vm.latestScan
        let todayExercises = vm.displayExercisesWithDifficulty
        let completedTodayExercises = todayExercises.filter { vm.completedExercises.contains($0.id) }
        let remainingTodayExercises = todayExercises.filter { !vm.completedExercises.contains($0.id) }
        let todayMeals = vm.todaysFoodLog.sorted { $0.date < $1.date }
        let todayNutritionTasks = vm.todaysNutrition.map {
            "\($0.title) (\(vm.completedNutrition.contains($0.id) ? "done" : "pending")): \($0.description)"
        }
        let todayMindsetTasks = vm.todaysMindset.map {
            "\($0.title) (\(vm.completedMindset.contains($0.id) ? "done" : "pending")): \($0.description)"
        }
        let recentWorkouts = vm.workoutHistory.sorted { $0.date > $1.date }.prefix(5)
        let recentScans = vm.scanResults.sorted { $0.date > $1.date }.prefix(5)
        let nextScan = vm.timeUntilNextScan

        parts.append("CURRENT DATE: \(todayDateString)")

        parts.append("--- PROFILE ---")
        parts.append("Name: \(p.displayName)")
        parts.append("Age: \(p.age), Gender: \(p.gender.rawValue)")
        parts.append("Height: \(p.heightFeet)'\(p.heightInches)\", Weight: \(Int(p.weightLbs)) lbs")
        parts.append("Goal: \(p.goal.rawValue)")
        parts.append("Activity Level: \(p.activityLevel.rawValue)")
        parts.append("Body Fat Category: \(p.bodyFatCategory.rawValue)")
        parts.append("Equipment Setting: \(p.equipmentSetting.rawValue)")
        parts.append("Abs Training Frequency: \(p.absTrainingFrequency.rawValue)")
        parts.append("Plan Speed: \(p.planSpeed.rawValue)")
        parts.append("Commitment Level: \(p.commitmentLevel)")
        parts.append("Program Phase: \(vm.currentPhase.name)")
        parts.append("Current Level: \(p.currentLevel)")
        parts.append("Current XP: \(p.currentXP)")
        parts.append("Days on Program: \(p.daysOnProgram)")
        parts.append("Current Streak: \(p.streakDays) days")
        parts.append("Subscribed: \(p.isSubscribed ? "Yes" : "No")")
        parts.append("Has Personal Coach Upgrade: \(p.hasPersonalCoach ? "Yes" : "No")")
        if let trainingSource = p.trainingSource, !trainingSource.isEmpty {
            parts.append("Training Source: \(trainingSource)")
        }
        if !vm.whyReasons.isEmpty {
            parts.append("Why They Started: \(vm.whyReasons.joined(separator: ", "))")
        }
        if !p.biggestStruggles.isEmpty {
            parts.append("Biggest Struggles: \(p.biggestStruggles.sorted().joined(separator: ", "))")
        }
        if let accomplishGoal = p.accomplishGoal, !accomplishGoal.isEmpty {
            parts.append("What They Want To Accomplish: \(accomplishGoal)")
        }

        parts.append("--- LATEST SCAN ---")
        if let scan = latestScan {
            parts.append("Overall Score: \(scan.overallScore)/100")
            parts.append("Upper Abs: \(scan.upperAbsScore), Lower Abs: \(scan.lowerAbsScore), Obliques: \(scan.obliquesScore), Deep Core: \(scan.deepCoreScore)")
            parts.append("Symmetry: \(scan.symmetry), V-Taper: \(scan.frame), Genetic Potential: \(scan.geneticPotential)")
            parts.append("Abs Structure: \(scan.absStructure.rawValue)")
            parts.append("Estimated Body Fat: \(String(format: "%.1f", scan.estimatedBodyFat))%")
            parts.append("Dominant Zone: \(scan.dominantZone)")
            parts.append("Weakest Zones: \(vm.weakestRegions.map(\.rawValue).joined(separator: ", "))")
            parts.append("Weakest Zone Score: \(vm.weakestZoneScore)")
            parts.append("Can Scan Now: \(vm.canScan ? "Yes" : "No")")
            parts.append("Next Scan In: \(nextScan.days)d \(nextScan.hours)h \(nextScan.minutes)m")
            if let verdict = scan.coachVerdict, !verdict.isEmpty {
                parts.append("Last Coach Verdict: \(verdict)")
            }
            if let visibilityTimeline = scan.visibilityTimeline, !visibilityTimeline.isEmpty {
                parts.append("Visibility Timeline: \(visibilityTimeline)")
            }
        } else {
            parts.append("No scan data yet.")
        }

        parts.append("--- SCAN-BASED TARGETS ---")
        if let bodyFat = p.scanBodyFatEstimate {
            parts.append("Scan Body Fat Target Context: \(String(format: "%.1f", bodyFat))%")
        }
        if let structure = p.scanAbsStructure {
            parts.append("Scan Structure Tag: \(structure)")
        }
        if let calories = p.scanDailyCalorieTarget {
            parts.append("Scan Calorie Target: \(calories)")
        }
        if let protein = p.scanProteinG, let carbs = p.scanCarbsG, let fat = p.scanFatG {
            parts.append("Scan Macros: protein \(protein)g, carbs \(carbs)g, fat \(fat)g")
        }
        if let deficit = p.scanDeficit {
            parts.append("Selected Daily Deficit: \(p.selectedCalorieDeficit)")
            parts.append("Scan Suggested Deficit: \(deficit)")
        }
        if let upperWeeks = p.scanUpperAbsWeeks, let obliqueWeeks = p.scanObliquesWeeks, let lowerWeeks = p.scanLowerAbsWeeks, let taperWeeks = p.scanVtaperWeeks {
            parts.append("Estimated Timeline By Zone: upper abs \(upperWeeks)w, obliques \(obliqueWeeks)w, lower abs \(lowerWeeks)w, v-taper \(taperWeeks)w")
        }

        parts.append("--- TODAY'S TRAINING ---")
        parts.append("Program Day: \(vm.programDayNumber)")
        parts.append("Week Number: \(vm.currentWeekNumber + 1)")
        parts.append("Week Theme: \(vm.currentWeekTheme)")
        parts.append("Today's Focus: \(vm.todayTargetLabel)")
        parts.append("Target Regions: \(vm.todayTargetRegions.0.rawValue) + \(vm.todayTargetRegions.1.rawValue)")
        parts.append("Rest Day: \(vm.isTodayRestDay ? "Yes" : "No")")
        parts.append("Today's Feel Check: \(vm.todayFeelCheck?.rawValue ?? "Not logged")")
        parts.append("Difficulty Setting: \(vm.currentDifficulty?.rawValue ?? "Medium")")
        parts.append("Difficulty Locked Today: \(vm.difficultyLockedForToday ? "Yes" : "No")")
        parts.append("AI Counter Enabled: \(vm.aiCounterEnabled ? "Yes" : "No")")
        parts.append("Workout Completed Today: \(vm.allTasksCompleted ? "Yes" : "No")")
        parts.append("Exercises Done Today: \(completedTodayExercises.count)/\(todayExercises.count)")
        if !todayExercises.isEmpty {
            parts.append("Today's Exercises:")
            todayExercises.forEach { parts.append(exerciseSummaryLine(for: $0)) }
        }
        if !completedTodayExercises.isEmpty {
            parts.append("Completed Exercise Names: \(completedTodayExercises.map(\.name).joined(separator: ", "))")
        }
        if !remainingTodayExercises.isEmpty {
            parts.append("Remaining Exercise Names: \(remainingTodayExercises.map(\.name).joined(separator: ", "))")
        }
        if let bonusExercise = vm.bonusExerciseForHard {
            parts.append("Hard Mode Bonus Exercise: \(bonusExercise.name)")
        }
        parts.append("Tomorrow Focus: \(vm.tomorrowTargetLabel)")
        parts.append("Tomorrow Rest Day: \(vm.isTomorrowRestDay ? "Yes" : "No")")
        if !vm.tomorrowExercisesPreview.isEmpty {
            parts.append("Tomorrow Exercise Preview: \(vm.tomorrowExercisesPreview.map(\.name).joined(separator: ", "))")
        }

        parts.append("--- TRAINING PLAN ---")
        if let stage = vm.currentStage {
            parts.append("Plan Generated: Yes")
            parts.append("Current Stage: \(stage.name) — \(stage.subtitle)")
            parts.append("Plan Stage Progress: \(vm.trainingPlan.currentStageIndex + 1)/\(vm.trainingPlan.stages.count)")
            parts.append("Plan Day Progress: \(vm.trainingPlan.currentDayIndex + 1)/\(stage.days.count)")
            if let currentDay = vm.currentDay {
                parts.append("Current Plan Day Snapshot: \(planDaySummaryLine(for: currentDay))")
            }
            let upcomingDays = Array(stage.days.dropFirst(vm.trainingPlan.currentDayIndex).prefix(3))
            if !upcomingDays.isEmpty {
                parts.append("Upcoming Plan Days:")
                upcomingDays.forEach { parts.append(planDaySummaryLine(for: $0)) }
            }
        } else {
            parts.append("Plan Generated: No")
        }
        if let selectedDayId = vm.selectedDayId {
            parts.append("Selected Day ID In App: \(selectedDayId)")
        }

        parts.append("--- TODAY'S NUTRITION ---")
        parts.append("Calories: \(vm.totalCaloriesToday)/\(vm.dailyNutrition.calorieGoal)")
        parts.append("Protein: \(String(format: "%.0f", vm.totalProteinToday))/\(String(format: "%.0f", vm.dailyNutrition.proteinGoal))g")
        parts.append("Carbs: \(String(format: "%.0f", vm.totalCarbsToday))/\(String(format: "%.0f", vm.dailyNutrition.carbsGoal))g")
        parts.append("Fat: \(String(format: "%.0f", vm.totalFatToday))/\(String(format: "%.0f", vm.dailyNutrition.fatGoal))g")
        parts.append("Fiber: \(String(format: "%.0f", vm.totalFiberToday))/\(String(format: "%.0f", vm.dailyNutrition.fiberGoal))g")
        parts.append("Sugar: \(String(format: "%.0f", vm.totalSugarToday))/\(String(format: "%.0f", vm.dailyNutrition.sugarGoal))g")
        parts.append("Sodium: \(String(format: "%.0f", vm.totalSodiumToday))/\(String(format: "%.0f", vm.dailyNutrition.sodiumGoal))mg")
        parts.append("Water: \(vm.waterGlasses)/\(vm.dailyNutrition.waterGoal) glasses")
        parts.append("Calories Remaining: \(vm.caloriesRemaining)")
        parts.append("Meals Logged Today: \(todayMeals.count)")
        if !todayMeals.isEmpty {
            todayMeals.forEach {
                parts.append("\($0.mealType.rawValue): \($0.name) — \($0.calories) cal, protein \(String(format: "%.0f", $0.protein))g, carbs \(String(format: "%.0f", $0.carbs))g, fat \(String(format: "%.0f", $0.fat))g")
            }
        }
        if !todayNutritionTasks.isEmpty {
            parts.append("Today's Nutrition Tasks:")
            todayNutritionTasks.forEach { parts.append($0) }
        }

        parts.append("--- MINDSET & RECOVERY ---")
        parts.append("Missed Yesterday: \(vm.missedYesterday ? "Yes" : "No")")
        parts.append("Streak Recovered Today: \(vm.streakRecoveredToday ? "Yes" : "No")")
        if !todayMindsetTasks.isEmpty {
            parts.append("Today's Mindset Tasks:")
            todayMindsetTasks.forEach { parts.append($0) }
        }

        parts.append("--- HISTORY & PROGRESSION ---")
        parts.append("Total Scans: \(vm.scanResults.count)")
        parts.append("Total Workouts Completed: \(vm.workoutHistory.count)")
        parts.append("Total Exercises Completed Lifetime: \(vm.totalExercisesCompleted)")
        parts.append("Total Meals Logged Lifetime: \(vm.effectiveTotalMealsLogged)")
        parts.append("Water Goal Days Hit: \(vm.waterGoalDaysHit)")
        parts.append("Progress Photos This Month: \(vm.photoDaysThisMonth.count)")
        if vm.scanResults.count >= 2 {
            let sorted = vm.scanResults.sorted { $0.date < $1.date }
            if let first = sorted.first, let last = sorted.last {
                let change = last.overallScore - first.overallScore
                parts.append("Score Progress Since First Scan: \(first.overallScore) → \(last.overallScore) (\(change >= 0 ? "+" : "")\(change))")
            }
        }
        if !recentScans.isEmpty {
            parts.append("Recent Scans:")
            recentScans.forEach { parts.append(scanSummaryLine(for: $0)) }
        }
        if !recentWorkouts.isEmpty {
            parts.append("Recent Workouts:")
            recentWorkouts.forEach { parts.append(workoutSummaryLine(for: $0)) }
        }

        parts.append("--- ADHERENCE & PROJECTION ---")
        parts.append("Missed Workouts Last 30 Days: \(vm.missedWorkoutDaysLast30)")
        parts.append("Calorie Overage Days Last 30 Days: \(vm.calorieOverageDaysLast30)")
        parts.append("Workout Adherence Last 30 Days: \(vm.absProjection.completedWorkoutsLast30)/\(vm.absProjection.scheduledWorkoutsLast30) (\(Int((vm.absProjection.workoutAdherenceRate * 100).rounded()))%)")
        parts.append("Nutrition Adherence Last 30 Days: \(Int((vm.absProjection.nutritionAdherenceRate * 100).rounded()))%")
        parts.append("Current Score Goal Path: \(vm.absProjection.currentScore) → \(vm.absProjection.targetScore)")
        parts.append("Current Body Fat Goal Path: \(String(format: "%.1f", vm.absProjection.currentBodyFat))% → \(String(format: "%.1f", vm.absProjection.targetBodyFat))%")
        parts.append("Projected Weeks Remaining: \(vm.absProjection.projectedWeeks)")
        parts.append("Projected Goal Date: \(shortDateString(from: vm.absProjection.projectedDate))")
        parts.append("Limiting Factor: \(vm.absProjection.limitingFactor.rawValue)")
        parts.append("Planned Daily Deficit: \(Int(vm.absProjection.plannedDailyDeficit))")
        parts.append("Effective Daily Deficit: \(Int(vm.absProjection.effectiveDailyDeficit))")
        parts.append("Days Added By Nutrition: \(Int(vm.absProjection.daysAddedByNutrition.rounded()))")
        parts.append("Days Added By Missed Workouts: \(Int(vm.absProjection.daysAddedByMissedWorkouts.rounded()))")

        return parts.joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            chatHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        dateSeparator
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                        ForEach(messages) { message in
                            MaxxChatBubble(message: message)
                                .id(message.id)
                                .padding(.vertical, 4)
                        }

                        if isLoading {
                            HStack(spacing: 6) {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .id("loading")
                        }
                    }
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                .onChange(of: messages.count) { _, _ in
                    withAnimation {
                        if let lastID = messages.last?.id {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isLoading) { _, newValue in
                    if newValue {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }

            if showQuickQuestions && messages.count <= 2 && !isLoading {
                quickQuestionsBar
            }

            Divider().overlay(AppTheme.border)
            chatInputBar
        }
        .background(BackgroundView().ignoresSafeArea())
        .onAppear {
            if messages.isEmpty {
                let name = vm.profile.displayName
                let streak = vm.profile.streakDays
                let motivator: String
                if streak > 3 {
                    motivator = "\(streak) days strong — that discipline is building something real. Let's keep going."
                } else if streak > 0 {
                    motivator = "You're showing up and that's what matters. Consistency beats everything."
                } else {
                    motivator = "Today's a fresh start. Every rep gets you closer. Let's make it count."
                }
                messages.append(CoachMessage(text: "What's up \(name) 💪", isUser: false))
                messages.append(CoachMessage(text: motivator, isUser: false))
            }
        }
    }

    private var chatHeader: some View {
        ZStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                CoachMaxxAvatar(size: 32)

                Text("Coach Maxx")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.cardSurface)
    }

    private var dateSeparator: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AppTheme.border)
                .frame(height: 0.5)
            Text(todayDateString)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .layoutPriority(1)
            Rectangle()
                .fill(AppTheme.border)
                .frame(height: 0.5)
        }
        .padding(.horizontal, 16)
    }

    private var quickQuestionsBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(quickQuestions, id: \.self) { question in
                    Button {
                        inputText = question
                        sendMessage()
                        withAnimation(.easeOut(duration: 0.2)) {
                            showQuickQuestions = false
                        }
                    } label: {
                        Text(question)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppTheme.cardSurfaceElevated)
                            .clipShape(.rect(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(AppTheme.border, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
        .padding(.vertical, 8)
    }

    private var chatInputBar: some View {
        HStack(spacing: 12) {
            TextField("Message Coach Maxx...", text: $inputText, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.cardSurfaceElevated)
                .clipShape(.rect(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.muted : AppTheme.primaryAccent)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.cardSurface)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = CoachMessage(text: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        withAnimation(.easeOut(duration: 0.2)) {
            showQuickQuestions = false
        }

        Task {
            do {
                let chatMessages = messages.dropFirst().map { $0 }
                let response = try await AbsCoachChatService.shared.sendMessage(
                    messages: Array(chatMessages),
                    userContext: userContext
                )
                messages.append(CoachMessage(text: response, isUser: false))
            } catch {
                messages.append(CoachMessage(
                    text: "can't connect right now. try again in a sec.",
                    isUser: false
                ))
            }
            isLoading = false
        }
    }
}

struct MaxxChatBubble: View {
    let message: CoachMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser { Spacer(minLength: 60) }

            if !message.isUser {
                CoachMaxxAvatar(size: 28)
            }

            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.isUser
                        ? AppTheme.primaryAccent
                        : AppTheme.cardSurfaceElevated
                )
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    Group {
                        if !message.isUser {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
                        }
                    }
                )

            if !message.isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
}
