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

    private var userContext: String {
        var parts: [String] = []

        let p = vm.profile
        parts.append("Name: \(p.displayName)")
        parts.append("Age: \(p.age), Gender: \(p.gender.rawValue)")
        parts.append("Height: \(p.heightFeet)'\(p.heightInches)\", Weight: \(Int(p.weightLbs)) lbs")
        parts.append("Goal: \(p.goal.rawValue)")
        parts.append("Activity Level: \(p.activityLevel.rawValue)")
        parts.append("Body Fat Category: \(p.bodyFatCategory.rawValue)")
        parts.append("Equipment: \(p.equipmentSetting.rawValue)")
        parts.append("Abs Training Frequency: \(p.absTrainingFrequency.rawValue)")
        parts.append("Days on Program: \(p.daysOnProgram)")
        parts.append("Current Streak: \(p.streakDays) days")

        if let scan = vm.latestScan {
            parts.append("--- LATEST SCAN ---")
            parts.append("Overall Score: \(scan.overallScore)/100")
            parts.append("Upper Abs: \(scan.upperAbsScore), Lower Abs: \(scan.lowerAbsScore)")
            parts.append("Obliques: \(scan.obliquesScore), Deep Core: \(scan.deepCoreScore)")
            parts.append("Symmetry: \(scan.symmetry), V-Taper: \(scan.frame)")
            parts.append("Abs Structure: \(scan.absStructure.rawValue)")
            parts.append("Est. Body Fat: \(String(format: "%.1f", scan.estimatedBodyFat))%")
            if let verdict = scan.coachVerdict { parts.append("Last Coach Verdict: \(verdict)") }

            let weakest = [
                ("Upper Abs", scan.upperAbsScore),
                ("Lower Abs", scan.lowerAbsScore),
                ("Obliques", scan.obliquesScore),
                ("Deep Core", scan.deepCoreScore)
            ].sorted { $0.1 < $1.1 }
            parts.append("Weakest Zone: \(weakest.first?.0 ?? "N/A") (\(weakest.first?.1 ?? 0))")
            parts.append("Strongest Zone: \(weakest.last?.0 ?? "N/A") (\(weakest.last?.1 ?? 0))")
        } else {
            parts.append("No scan data yet.")
        }

        parts.append("Total Scans: \(vm.scanResults.count)")

        parts.append("--- TODAY ---")
        parts.append("Program Day: \(vm.programDayNumber)")
        parts.append("Today's Focus: \(vm.todayTargetLabel)")
        parts.append("Rest Day: \(vm.isTodayRestDay ? "Yes" : "No")")

        let exerciseTotal = vm.todaysExercises.count
        let exerciseDone = vm.todaysExercises.filter { vm.completedExercises.contains($0.id) }.count
        parts.append("Exercises Done Today: \(exerciseDone)/\(exerciseTotal)")

        parts.append("Calories Today: \(vm.totalCaloriesToday)/\(vm.dailyNutrition.calorieGoal)")
        parts.append("Protein Today: \(String(format: "%.0f", vm.totalProteinToday))/\(String(format: "%.0f", vm.dailyNutrition.proteinGoal))g")
        parts.append("Water Today: \(vm.waterGlasses)/\(vm.dailyNutrition.waterGoal) glasses")

        if let difficulty = vm.currentDifficulty {
            parts.append("Difficulty Setting: \(difficulty.rawValue)")
        }

        parts.append("--- HISTORY ---")
        parts.append("Total Workouts Completed: \(vm.workoutHistory.count)")
        parts.append("Total Exercises Completed: \(vm.totalExercisesCompleted)")

        if vm.scanResults.count >= 2 {
            let sorted = vm.scanResults.sorted { $0.date < $1.date }
            let first = sorted.first!
            let latest = sorted.last!
            let change = latest.overallScore - first.overallScore
            parts.append("Score Progress: \(first.overallScore) → \(latest.overallScore) (\(change >= 0 ? "+" : "")\(change))")
        }

        if !p.biggestStruggles.isEmpty {
            parts.append("Biggest Struggles: \(p.biggestStruggles.joined(separator: ", "))")
        }
        if let accomplishGoal = p.accomplishGoal {
            parts.append("What they want to accomplish: \(accomplishGoal)")
        }

        let nextScan = vm.timeUntilNextScan
        parts.append("Next Scan In: \(nextScan.days)d \(nextScan.hours)h")
        parts.append("Can Scan Now: \(vm.canScan ? "Yes" : "No")")

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
