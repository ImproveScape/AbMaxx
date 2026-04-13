import SwiftUI

struct WorkoutTimerView: View {
    let exercises: [Exercise]
    let completedExercises: Set<String>
    let onComplete: (String, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var timeRemaining: Int = 0
    @State private var isRunning: Bool = false
    @State private var isResting: Bool = false
    @State private var timerActive: Bool = false
    @State private var totalElapsed: Int = 0
    @State private var completedCount: Int = 0
    @State private var showComplete: Bool = false
    @State private var pulseRing: Bool = false

    private let restDuration: Int = 30

    private var currentExercise: Exercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    private var exerciseDuration: Int {
        guard let ex = currentExercise else { return 30 }
        if ex.reps.lowercased().contains("sec") {
            let digits = ex.reps.filter(\.isNumber)
            return Int(digits) ?? 30
        }
        return 40
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if showComplete {
                workoutCompleteView
            } else {
                VStack(spacing: 0) {
                    headerBar
                    Spacer()
                    timerDisplay
                    Spacer()
                    exerciseInfo
                    controlButtons
                    Color.clear.frame(height: 40)
                }
            }
        }
        .onAppear {
            skipToFirstIncomplete()
            timeRemaining = exerciseDuration
        }
        .onChange(of: timerActive) { _, newVal in
            if newVal { startTimer() }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isResting)
    }

    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.cardSurface)
                    .clipShape(Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Exercise \(currentIndex + 1)/\(exercises.count)")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.secondaryText)
                Text(formatTime(totalElapsed))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
                    .monospacedDigit()
            }
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var timerDisplay: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(AppTheme.border.opacity(0.3), lineWidth: 8)
                    .frame(width: 220, height: 220)

                let total = isResting ? restDuration : exerciseDuration
                let progress = total > 0 ? Double(timeRemaining) / Double(total) : 0

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isResting
                            ? LinearGradient(colors: [AppTheme.success, AppTheme.success.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                            : AppTheme.accentGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)

                VStack(spacing: 8) {
                    Text(isResting ? "REST" : "GO")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(isResting ? AppTheme.success : AppTheme.primaryAccent)
                        .tracking(3)

                    Text(formatTime(timeRemaining))
                        .font(.system(size: 56, weight: .black, design: .default))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .scaleEffect(pulseRing ? 1.02 : 1.0)

            if isResting {
                Text("Next: \(exercises[safe: currentIndex + 1]?.name ?? "Done")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var exerciseInfo: some View {
        VStack(spacing: 10) {
            if let ex = currentExercise {
                Text(ex.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    Label(ex.reps, systemImage: "repeat")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)

                    Label(ex.region.rawValue, systemImage: ex.region.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
            }
        }
        .padding(.bottom, 24)
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button {
                if currentIndex > 0 {
                    currentIndex -= 1
                    resetForCurrentExercise()
                }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title3.bold())
                    .foregroundStyle(currentIndex > 0 ? .white : AppTheme.muted)
                    .frame(width: 56, height: 56)
                    .background(AppTheme.cardSurface)
                    .clipShape(Circle())
            }
            .disabled(currentIndex == 0)

            Button {
                if isRunning {
                    isRunning = false
                    timerActive = false
                } else {
                    isRunning = true
                    timerActive = true
                }
            } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(AppTheme.accentGradient)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 16, y: 4)
            }

            Button {
                completeCurrentAndAdvance()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(AppTheme.cardSurface)
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 16)
    }

    private var workoutCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.success)

            Text("Workout Complete!")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(completedCount)")
                        .font(.system(size: 32, weight: .black, design: .default))
                        .foregroundStyle(AppTheme.primaryAccent)
                    Text("Exercises")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }
                VStack(spacing: 4) {
                    Text(formatTime(totalElapsed))
                        .font(.system(size: 32, weight: .black, design: .default))
                        .foregroundStyle(AppTheme.orange)
                    Text("Total Time")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            Spacer()

            Button { dismiss() } label: {
                Text("Done")
                    .font(.headline.bold())
            }
            .buttonStyle(GlowButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }

    private func skipToFirstIncomplete() {
        for (i, ex) in exercises.enumerated() {
            if !completedExercises.contains(ex.id) {
                currentIndex = i
                return
            }
        }
        currentIndex = 0
    }

    private func resetForCurrentExercise() {
        isResting = false
        isRunning = false
        timerActive = false
        timeRemaining = exerciseDuration
    }

    private func completeCurrentAndAdvance() {
        guard let ex = currentExercise else { return }
        if !completedExercises.contains(ex.id) {
            onComplete(ex.id, ex.xp)
            completedCount += 1
        }

        if currentIndex < exercises.count - 1 {
            isResting = true
            timeRemaining = restDuration
            isRunning = true
            timerActive = true
        } else {
            isRunning = false
            timerActive = false
            showComplete = true
        }
    }

    private func startTimer() {
        Task {
            while timerActive && timeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard timerActive else { break }
                timeRemaining -= 1
                totalElapsed += 1

                if timeRemaining <= 3 && timeRemaining > 0 {
                    withAnimation(.easeInOut(duration: 0.3)) { pulseRing = true }
                    try? await Task.sleep(for: .milliseconds(200))
                    withAnimation { pulseRing = false }
                }
            }
            if timerActive && timeRemaining == 0 {
                if isResting {
                    currentIndex += 1
                    resetForCurrentExercise()
                    timeRemaining = exerciseDuration
                    isRunning = true
                    timerActive = true
                } else {
                    completeCurrentAndAdvance()
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
