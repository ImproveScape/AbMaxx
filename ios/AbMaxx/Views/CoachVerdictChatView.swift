import SwiftUI

struct CoachVerdictChatView: View {
    @Bindable var vm: AppViewModel
    @State private var messages: [CoachMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @Environment(\.dismiss) private var dismiss

    private var fullContext: String {
        var parts: [String] = []

        let p = vm.profile
        parts.append("Name: \(p.displayName)")
        parts.append("Gender: \(p.gender.rawValue)")
        parts.append("Age: \(p.age)")
        if p.useMetric {
            parts.append("Height: \(Int(p.heightInCm)) cm")
            parts.append("Weight: \(String(format: "%.1f", p.weightLbs)) kg")
        } else {
            parts.append("Height: \(p.heightFeet)'\(p.heightInches)\"")
            parts.append("Weight: \(String(format: "%.0f", p.weightLbs)) lbs")
        }
        parts.append("Activity Level: \(p.activityLevel.rawValue)")
        parts.append("Goal: \(p.goal.rawValue)")
        parts.append("Body Fat Category: \(p.bodyFatCategory.rawValue)")
        parts.append("Plan Speed: \(p.planSpeed.rawValue)")
        parts.append("Days on Program: \(p.daysOnProgram)")
        parts.append("Streak: \(p.streakDays) days")
        parts.append("Program Day: \(vm.programDayNumber)")

        if let bf = p.scanBodyFatEstimate {
            parts.append("Scan Body Fat: \(String(format: "%.1f", bf))%")
        }
        if let structure = p.scanAbsStructure {
            parts.append("Abs Structure: \(structure)")
        }
        if let cal = p.scanDailyCalorieTarget {
            parts.append("Daily Calorie Target: \(cal) kcal")
        }
        if let protein = p.scanProteinG { parts.append("Protein Goal: \(protein)g") }
        if let carbs = p.scanCarbsG { parts.append("Carbs Goal: \(carbs)g") }
        if let fat = p.scanFatG { parts.append("Fat Goal: \(fat)g") }
        if let deficit = p.scanDeficit { parts.append("Calorie Deficit: \(deficit) kcal") }

        if let scan = vm.latestScan {
            parts.append("--- LATEST SCAN ---")
            parts.append("Overall Score: \(scan.overallScore)/99")
            parts.append("Upper Abs: \(scan.upperAbsScore)")
            parts.append("Lower Abs: \(scan.lowerAbsScore)")
            parts.append("Obliques: \(scan.obliquesScore)")
            parts.append("Deep Core: \(scan.deepCoreScore)")
            parts.append("Symmetry: \(scan.symmetry)")
            parts.append("V Taper: \(scan.frame)")
            parts.append("Genetic Potential: \(scan.geneticPotentialLevel.rawValue)")
            parts.append("Est. Body Fat: \(String(format: "%.1f", scan.estimatedBodyFat))%")
            if let verdict = scan.coachVerdict { parts.append("Last Coach Verdict: \(verdict)") }
            if let timeline = scan.visibilityTimeline { parts.append("Visibility Timeline: \(timeline)") }
        }

        let weakest = vm.weakestZoneFromScan
        parts.append("Weakest Zone: \(weakest.rawValue)")

        if vm.scanResults.count >= 2 {
            let sorted = vm.scanResults.sorted { $0.date < $1.date }
            let prev = sorted[sorted.count - 2]
            let curr = sorted[sorted.count - 1]
            let diff = curr.overallScore - prev.overallScore
            parts.append("Score Change (last scan): \(diff > 0 ? "+\(diff)" : "\(diff)")")
        }
        parts.append("Total Scans: \(vm.scanResults.count)")

        parts.append("Today's Target: \(vm.todayTargetLabel)")
        parts.append("Is Rest Day: \(vm.isTodayRestDay)")
        parts.append("Exercises Completed Today: \(vm.completedExercises.count)/\(vm.todaysExercises.count)")

        parts.append("Calories Today: \(vm.totalCaloriesToday)/\(vm.dailyNutrition.calorieGoal)")
        parts.append("Protein Today: \(String(format: "%.0f", vm.totalProteinToday))/\(String(format: "%.0f", vm.dailyNutrition.proteinGoal))g")
        parts.append("Water Today: \(vm.waterGlasses)/\(vm.dailyNutrition.waterGoal) glasses")

        if let difficulty = vm.currentDifficulty {
            parts.append("Difficulty Level: \(difficulty.rawValue)")
        }

        if let weekEta = p.scanUpperAbsWeeks { parts.append("Upper Abs Visibility ETA: ~\(weekEta) weeks") }
        if let weekEta = p.scanLowerAbsWeeks { parts.append("Lower Abs Visibility ETA: ~\(weekEta) weeks") }
        if let weekEta = p.scanObliquesWeeks { parts.append("Obliques Visibility ETA: ~\(weekEta) weeks") }
        if let weekEta = p.scanVtaperWeeks { parts.append("V-Taper Visibility ETA: ~\(weekEta) weeks") }

        return parts.joined(separator: "\n")
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().overlay(AppTheme.border)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { message in
                                VerdictBubble(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                HStack(spacing: 6) {
                                    verdictAvatar
                                    VerdictTypingDots()
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .id("loading")
                            }
                        }
                        .padding(.vertical, 16)
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
                            withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                        }
                    }
                }

                Divider().overlay(AppTheme.border)
                inputBar
            }
        }
        .onAppear {
            if messages.isEmpty {
                let score = vm.latestScan?.overallScore ?? 0
                let greeting: String
                if score > 0 {
                    greeting = "What's good. I'm Coach Verdict — I know your body inside out. Score sitting at \(score) right now. Ask me anything — training, nutrition, weak zones, timeline. I got you."
                } else {
                    greeting = "Yo. I'm Coach Verdict — your personal abs coach. I'll know everything about your body once you take your first scan. For now, ask me anything about training or nutrition. Let's get after it."
                }
                messages.append(CoachMessage(text: greeting, isUser: false))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.05)))
            }

            CoachMaxxAvatar(size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Coach Verdict")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text("Knows everything about you")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.success)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.cardSurface)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Coach Verdict...", text: $inputText, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.cardSurfaceElevated)
                .clipShape(.rect(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )

            Button { sendMessage() } label: {
                ZStack {
                    Circle()
                        .fill(canSend ? AppTheme.primaryAccent : AppTheme.muted.opacity(0.4))
                        .frame(width: 38, height: 38)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.cardSurface)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    private var verdictAvatar: some View {
        CoachMaxxAvatar(size: 28)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(CoachMessage(text: text, isUser: true))
        inputText = ""
        isLoading = true

        Task {
            do {
                let response = try await CoachVerdictService.shared.sendMessage(
                    messages: Array(messages.dropFirst()),
                    userContext: fullContext
                )
                messages.append(CoachMessage(text: response, isUser: false))
            } catch {
                messages.append(CoachMessage(
                    text: "Can't connect right now. Try again in a sec.",
                    isUser: false
                ))
            }
            isLoading = false
        }
    }
}

struct VerdictBubble: View {
    let message: CoachMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser { Spacer(minLength: 50) }

            if !message.isUser {
                CoachMaxxAvatar(size: 28)
            }

            Text(message.text)
                .font(.system(size: 15))
                .foregroundStyle(message.isUser ? .white : Color(red: 0.88, green: 0.88, blue: 0.95))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.isUser
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, Color(red: 0.3, green: 0.15, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                          )
                        : AnyShapeStyle(AppTheme.cardSurfaceElevated)
                )
                .clipShape(.rect(cornerRadius: 18))
                .overlay(
                    Group {
                        if !message.isUser {
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
                        }
                    }
                )

            if !message.isUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal, 16)
    }
}

struct VerdictTypingDots: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.3 : 0.7)
                    .opacity(phase == i ? 1.0 : 0.3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.cardSurfaceElevated)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
        )
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}
