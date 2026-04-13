import SwiftUI
import AVFoundation

nonisolated struct ExerciseSet: Sendable {
    let value: Int
    let sets: Int
    let isTimeBased: Bool

    static func parse(from reps: String) -> ExerciseSet {
        let lower = reps.lowercased()
        let isTime = lower.contains("sec")

        let parts = lower.components(separatedBy: "×").map { $0.trimmingCharacters(in: .whitespaces) }

        var value = 30
        var sets = 3

        if let first = parts.first {
            let digits = first.filter(\.isNumber)
            if let parsed = Int(digits), parsed > 0 {
                value = parsed
            }
        }

        if parts.count > 1 {
            let digits = parts[1].filter(\.isNumber)
            if let parsed = Int(digits), parsed > 0 {
                sets = parsed
            }
        }

        return ExerciseSet(value: value, sets: sets, isTimeBased: isTime)
    }

    func adjusted(for difficulty: DifficultyLevel) -> ExerciseSet {
        switch difficulty {
        case .easy:
            let adjustedValue = isTimeBased ? max(15, value - 15) : max(5, value - 5)
            let adjustedSets = max(1, sets - 1)
            return ExerciseSet(value: adjustedValue, sets: adjustedSets, isTimeBased: isTimeBased)
        case .medium:
            return self
        case .hard:
            let adjustedValue = isTimeBased ? value + 10 : value + 5
            let adjustedSets = sets + 1
            return ExerciseSet(value: adjustedValue, sets: adjustedSets, isTimeBased: isTimeBased)
        }
    }
}

struct WorkoutSessionView: View {
    let exercises: [Exercise]
    let completedExercises: Set<String>
    let onComplete: (String) -> Void
    var daysUntilNextScan: Int = 7
    var hoursUntilNextScan: Int = 0
    var canScan: Bool = false
    var currentScore: Int = 0
    var difficulty: DifficultyLevel = .medium
    var weakestZone: AbRegion = .lowerAbs
    var initialAICounterEnabled: Bool = true
    var zoneScores: [AbRegion: Int] = [:]
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0
    @State private var currentSet: Int = 1
    @State private var timeRemaining: Int = 0
    @State private var totalElapsed: Int = 0
    @State private var completedCount: Int = 0
    @State private var showComplete: Bool = false
    @State private var timerTask: Task<Void, Never>?
    @State private var totalElapsedTimer: Task<Void, Never>?

    @State private var sessionPhase: SessionPhase = .guide
    @State private var setJustCompleted: Int = 0
    @State private var showSetBanner: Bool = false
    @State private var showExerciseTransition: Bool = false
    @State private var exerciseAppear: Bool = false
    @State private var pulseActive: Bool = false

    @State private var coach = LiveCoachingService()
    @State private var voiceCoach = VoiceCoachService()

    @State private var showDemoSheet: Bool = false

    @State private var cameraManager = ExerciseCameraManager()
    @State private var poseService: PoseDetectionService?
    @State private var repCounter = RepCountingService()
    @State private var poseDetected: Bool = false
    @State private var repPulse: Bool = false
    @State private var targetReached: Bool = false
    @State private var isCameraReady: Bool = false
    @State private var restBreathScale: CGFloat = 1.0
    @State private var restPulseOpacity: Double = 0.3
    @State private var aiCounterEnabled: Bool = true
    @State private var showQuitConfirmation: Bool = false

    nonisolated enum SessionPhase: Sendable {
        case guide
        case countdown
        case active
        case resting
    }

    @State private var countdownValue: Int = 3

    private var currentExercise: Exercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    private var parsed: ExerciseSet {
        guard let ex = currentExercise else { return ExerciseSet(value: 30, sets: 3, isTimeBased: true) }
        return ExerciseSet.parse(from: ex.reps).adjusted(for: difficulty)
    }

    private var hasCameraAccess: Bool {
        guard aiCounterEnabled else { return false }
        #if targetEnvironment(simulator)
        return false
        #else
        return AVCaptureDevice.default(for: .video) != nil
        #endif
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            if showComplete {
                SessionCompleteView(
                    exercises: exercises,
                    completedCount: completedCount,
                    totalElapsed: totalElapsed,
                    difficulty: difficulty,
                    daysUntilNextScan: daysUntilNextScan,
                    canScan: canScan,
                    onDismiss: { dismiss() }
                )
                    .transition(.opacity)
            } else if showExerciseTransition {
                exerciseTransitionView
                    .transition(.opacity)
            } else {
                mainSessionContent
            }

            if showSetBanner {
                setBannerOverlay
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }

            if showQuitConfirmation {
                quitConfirmationOverlay
                    .transition(.opacity)
                    .zIndex(30)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showComplete)
        .animation(.easeInOut(duration: 0.3), value: showExerciseTransition)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: showQuitConfirmation)
        .statusBarHidden()
        .sheet(isPresented: $showDemoSheet) {
            if let ex = currentExercise {
                ExerciseDemoSheet(exercise: ex, regionScore: zoneScores[ex.region] ?? 0)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            aiCounterEnabled = initialAICounterEnabled
            voiceCoach.isEnabled = true
            skipToFirstIncomplete()
            setupForCurrentExercise()
            startElapsedTimer()
            setupCamera()
        }
        .onDisappear {
            totalElapsedTimer?.cancel()
            timerTask?.cancel()
            coach.stop()
            voiceCoach.stop()
            cameraManager.stop()
        }
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: sessionPhase == .resting)
        .sensoryFeedback(.success, trigger: showComplete)
        .sensoryFeedback(.impact(weight: .heavy), trigger: showSetBanner)
    }

    // MARK: - Main Content

    private var mainSessionContent: some View {
        ZStack {
            if !parsed.isTimeBased && aiCounterEnabled && sessionPhase == .active {
                cameraActiveView
            } else if !parsed.isTimeBased && aiCounterEnabled && sessionPhase == .countdown {
                cameraCountdownView
            } else {
                standardSessionContent
            }
        }
        .opacity(exerciseAppear ? 1 : 0)
        .offset(y: exerciseAppear ? 0 : 20)
    }

    private var standardSessionContent: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.top, 8)
                .padding(.horizontal, 16)

            progressSegments
                .padding(.top, 10)
                .padding(.horizontal, 16)

            switch sessionPhase {
            case .guide:
                guideContent
            case .countdown:
                countdownContent
            case .active:
                activeContent
            case .resting:
                restContent
            }
        }
    }

    // MARK: - Camera Active View (Rep-Based)

    private var cameraActiveView: some View {
        ZStack {
            if hasCameraAccess {
                ExerciseCameraPreview(session: cameraManager.captureSession)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [Color.black.opacity(0.6), .clear, .clear, Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                BackgroundView().ignoresSafeArea()
            }

            VStack(spacing: 0) {
                cameraTopBar
                    .padding(.top, 8)

                Spacer()

                repCounterOverlay

                Spacer()

                cameraCoachingBanner
                    .padding(.horizontal, 20)

                cameraActiveActions
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
        }
        .onChange(of: repCounter.repCount) { oldValue, newValue in
            if newValue > oldValue {
                repPulse = true
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    repPulse = false
                }
                if newValue >= parsed.value && !targetReached {
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        targetReached = true
                    }
                    Task {
                        try? await Task.sleep(for: .milliseconds(800))
                        completeCurrentSet()
                    }
                }
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: repCounter.repCount)
    }

    private var cameraCountdownView: some View {
        ZStack {
            if hasCameraAccess {
                ExerciseCameraPreview(session: cameraManager.captureSession)
                    .ignoresSafeArea()

                AppTheme.background.opacity(0.5).ignoresSafeArea()
            } else {
                BackgroundView().ignoresSafeArea()
            }

            VStack(spacing: 0) {
                cameraTopBar
                    .padding(.top, 8)

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.primaryAccent.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)

                    Text("\(countdownValue)")
                        .font(.system(size: 120, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.8), radius: 30)
                        .contentTransition(.numericText())
                }

                if poseDetected {
                    HStack(spacing: 6) {
                        Circle().fill(AppTheme.success).frame(width: 8, height: 8)
                        Text("Body Detected")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.success)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(.top, 12)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.stand")
                            .font(.system(size: 12, weight: .bold))
                        Text("Position yourself in frame")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(.top, 12)
                }

                cameraPositioningGuide
                    .padding(.top, 8)

                Text("GET READY")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(4)
                    .padding(.top, 8)

                Spacer()
                Spacer()
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: countdownValue)
    }

    private var cameraPositioningGuide: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: "iphone.rear.camera")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("For best tracking:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            VStack(alignment: .leading, spacing: 2) {
                cameraGuideTip("Stand 4\u{2013}6 feet from phone")
                cameraGuideTip("Prop phone at waist height, angled up")
                cameraGuideTip("Full torso must be visible")
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.5))
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 40)
    }

    private func cameraGuideTip(_ text: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(AppTheme.primaryAccent.opacity(0.5))
                .frame(width: 3, height: 3)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private var cameraTopBar: some View {
        VStack(spacing: 6) {
            HStack {
                Button { withAnimation { showQuitConfirmation = true } } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }

                Spacer()

                if let ex = currentExercise {
                    Text(ex.name.uppercased())
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                        .lineLimit(1)
                }

                Spacer()

                Text(formatTime(totalElapsed))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal, 16)

            HStack(spacing: 3) {
                ForEach(0..<exercises.count, id: \.self) { i in
                    Capsule()
                        .fill(i < currentIndex ? AppTheme.success : (i == currentIndex ? AppTheme.primaryAccent : Color.white.opacity(0.15)))
                        .frame(height: 3)
                        .animation(.spring(duration: 0.5), value: currentIndex)
                }
            }
            .padding(.horizontal, 16)

            HStack(spacing: 4) {
                ForEach(1...parsed.sets, id: \.self) { s in
                    Circle()
                        .fill(s < currentSet ? AppTheme.success : (s == currentSet ? AppTheme.primaryAccent : Color.white.opacity(0.15)))
                        .frame(width: 8, height: 8)
                }
                Text("SET \(currentSet)/\(parsed.sets)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(1)
                    .padding(.leading, 4)
            }
            .padding(.top, 2)
        }
    }

    private var repCounterOverlay: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                targetReached ? AppTheme.success.opacity(0.35) : AppTheme.primaryAccent.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(repPulse ? 1.3 : 1.0)

                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: min(1, Double(repCounter.repCount) / Double(max(1, parsed.value))))
                    .stroke(
                        LinearGradient(
                            colors: targetReached
                                ? [AppTheme.success, Color(red: 0.2, green: 1.0, blue: 0.6)]
                                : [AppTheme.primaryAccent, AppTheme.primaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.4), value: repCounter.repCount)

                VStack(spacing: 0) {
                    Text("\(repCounter.repCount)")
                        .font(.system(size: 96, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: targetReached ? AppTheme.success.opacity(0.9) : AppTheme.primaryAccent.opacity(0.7), radius: 30)
                        .contentTransition(.numericText())
                        .scaleEffect(repPulse ? 1.15 : 1.0)
                        .monospacedDigit()

                    Text("of \(parsed.value)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .animation(.spring(duration: 0.15, bounce: 0.5), value: repPulse)

            if targetReached {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("TARGET REACHED")
                        .font(.system(size: 13, weight: .black))
                        .tracking(2)
                }
                .foregroundStyle(AppTheme.success)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.success.opacity(0.15))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            } else if !hasCameraAccess {
                Text("Camera unavailable — tap to count reps")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
            }
        }
    }

    private var cameraCoachingBanner: some View {
        HStack(spacing: 8) {
            let iconName: String = {
                switch coach.tipCategory {
                case .form: return "figure.core.training"
                case .tempo: return "metronome.fill"
                case .breathing: return "wind"
                case .motivation: return "flame.fill"
                case .correction: return "exclamationmark.triangle.fill"
                }
            }()
            let iconColor: Color = {
                switch coach.tipCategory {
                case .form: return AppTheme.primaryAccent
                case .tempo: return AppTheme.warning
                case .breathing: return AppTheme.success
                case .motivation: return AppTheme.orange
                case .correction: return AppTheme.destructive
                }
            }()

            Image(systemName: iconName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())

            Text(coach.currentTip)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .id(coach.currentTip)
                .transition(.push(from: .bottom))
                .animation(.easeInOut(duration: 0.4), value: coach.currentTip)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.5))
        .clipShape(.rect(cornerRadius: 12))
        .opacity(coach.currentTip.isEmpty ? 0 : 1)
    }

    private var cameraActiveActions: some View {
        HStack(spacing: 10) {
            Button { cancelActiveSet() } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 56, height: 56)
                    .background(Color.black.opacity(0.4))
                    .clipShape(.rect(cornerRadius: 16))
            }

            if !hasCameraAccess {
                Button { manualCountRep() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("TAP REP")
                            .font(.system(size: 15, weight: .black))
                            .tracking(1)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent, Color(red: 0.1, green: 0.25, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: 16))
                    .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 12, y: 4)
                }
            } else {
                Spacer()
            }

            Button { completeCurrentSet() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("DONE")
                        .font(.system(size: 15, weight: .black))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .frame(width: hasCameraAccess ? nil : 100, height: 56)
                .frame(maxWidth: hasCameraAccess ? .infinity : nil)
                .background(
                    targetReached
                        ? LinearGradient(colors: [AppTheme.success, Color(red: 0.1, green: 0.75, blue: 0.4)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: targetReached ? AppTheme.success.opacity(0.3) : .clear, radius: 12, y: 4)
            }
        }
    }

    // MARK: - Top Bar

    private var quitConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showQuitConfirmation = false } }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [AppTheme.orange.opacity(0.25), .clear],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.orange, AppTheme.destructive],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: AppTheme.orange.opacity(0.5), radius: 12)
                        }

                        Text("DON'T QUIT NOW")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                            .tracking(1)

                        Text(quitMotivationalMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 8)
                    }

                    progressSummaryPill

                    VStack(spacing: 10) {
                        Button {
                            withAnimation { showQuitConfirmation = false }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Resume Workout")
                                    .font(.system(size: 17, weight: .black))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.primaryAccent, Color(red: 0.1, green: 0.25, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(.rect(cornerRadius: 16))
                            .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 16, y: 6)
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: showQuitConfirmation)

                        Button {
                            withAnimation { showQuitConfirmation = false }
                            dismiss()
                        } label: {
                            Text("End Session")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white.opacity(0.35))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 20)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: "1A1A1E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.6), radius: 40, y: 10)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }

    private var quitMotivationalMessage: String {
        let messages = [
            "You're already making progress. Every rep counts toward your goal.",
            "The version of you tomorrow will thank you for finishing today.",
            "Pain is temporary. Quitting lasts forever. Keep pushing.",
            "You didn't come this far to only come this far.",
            "Your abs are being built right now. Don't stop.",
        ]
        return messages[totalElapsed % messages.count]
    }

    private var progressSummaryPill: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("\(completedCount)")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("done")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 30)

            VStack(spacing: 2) {
                Text("\(exercises.count - completedCount)")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .monospacedDigit()
                Text("left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 30)

            VStack(spacing: 2) {
                Text(formatTime(totalElapsed))
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text("time")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.04))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var topBar: some View {
        HStack {
            Button { withAnimation { showQuitConfirmation = true } } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 1) {
                Text("\(currentIndex + 1) of \(exercises.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text(formatTime(totalElapsed))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 50, alignment: .trailing)
        }
    }

    private var progressSegments: some View {
        HStack(spacing: 3) {
            ForEach(0..<exercises.count, id: \.self) { i in
                Capsule()
                    .fill(i < currentIndex ? AppTheme.success : (i == currentIndex ? AppTheme.primaryAccent : Color.white.opacity(0.1)))
                    .frame(height: 3)
                    .animation(.spring(duration: 0.5), value: currentIndex)
            }
        }
    }

    // MARK: - Guide (Pre-Set)

    private var guideContent: some View {
        VStack(spacing: 0) {
            exerciseImageOnly
                .padding(.top, 12)

            exerciseInfoSection
                .padding(.top, 12)
                .padding(.horizontal, 20)

            setIndicator
                .padding(.top, 16)
                .padding(.horizontal, 20)

            Spacer()

            sessionToggles
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            guideActions
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
        }
    }

    private var exerciseImageOnly: some View {
        VStack(spacing: 0) {
            if let ex = currentExercise {
                ZStack {
                    Color(AppTheme.cardSurfaceElevated)

                    AsyncImage(url: URL(string: ex.demoImageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .allowsHitTesting(false)
                        case .failure:
                            exercisePlaceholder
                        case .empty:
                            ProgressView().tint(AppTheme.primaryAccent)
                        @unknown default:
                            exercisePlaceholder
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 12)
    }

    private var exercisePlaceholder: some View {
        VStack(spacing: 10) {
            if let ex = currentExercise {
                Image(systemName: ex.region.icon)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent.opacity(0.3))
                Text(ex.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var exerciseInfoSection: some View {
        VStack(spacing: 6) {
            if let ex = currentExercise {
                Text(ex.name.uppercased())
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(0.5)

                HStack(spacing: 10) {
                    regionBadge(ex.region)
                    targetBadge
                }
            }
        }
    }

    private func regionBadge(_ region: AbRegion) -> some View {
        HStack(spacing: 4) {
            Image(systemName: region.icon)
                .font(.system(size: 10, weight: .bold))
            Text(region.rawValue)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(.white.opacity(0.5))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private var targetBadge: some View {
        Group {
            if parsed.isTimeBased {
                Text("\(parsed.value)s × \(parsed.sets)")
                    .font(.system(size: 11, weight: .bold))
            } else {
                Text("\(parsed.value) reps × \(parsed.sets)")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .foregroundStyle(.white.opacity(0.4))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private var setIndicator: some View {
        HStack(spacing: 6) {
            ForEach(1...parsed.sets, id: \.self) { setNum in
                SetPill(
                    number: setNum,
                    isCompleted: setNum < currentSet,
                    isCurrent: setNum == currentSet
                )
            }
        }
    }

    private var guideActions: some View {
        VStack(spacing: 10) {
            if let tip = coachTipForGuide {
                HStack(spacing: 8) {
                    Image(systemName: (!parsed.isTimeBased && aiCounterEnabled) ? "camera.fill" : (!parsed.isTimeBased ? "hand.tap.fill" : "hand.point.up.fill"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(!parsed.isTimeBased ? AppTheme.primaryAccent.opacity(0.8) : AppTheme.primaryAccent.opacity(0.6))
                    Text(!parsed.isTimeBased ? (aiCounterEnabled ? "Camera will count your reps" : "Tap to count your reps") : tip)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(.rect(cornerRadius: 10))
            }

            HStack(spacing: 8) {
                Button {
                    startCountdown()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: (!parsed.isTimeBased && aiCounterEnabled) ? "camera.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("SET \(currentSet)")
                            .font(.system(size: 17, weight: .black))
                            .tracking(1)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        !parsed.isTimeBased
                            ? LinearGradient(colors: [AppTheme.primaryAccent, AppTheme.primaryAccent], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [AppTheme.primaryAccent, Color(red: 0.1, green: 0.25, blue: 1.0)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(.rect(cornerRadius: 16))
                    .shadow(color: (!parsed.isTimeBased ? AppTheme.primaryAccent : AppTheme.primaryAccent).opacity(0.35), radius: 16, y: 6)
                }

                Button { skipExercise() } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.05))
                        .clipShape(.rect(cornerRadius: 16))
                }
            }
        }
    }

    private var sessionToggles: some View {
        HStack(spacing: 10) {
            Button { showDemoSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Demo")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            }

            Spacer()

            if !parsed.isTimeBased {
                Button {
                    aiCounterEnabled.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: aiCounterEnabled ? "camera.fill" : "camera")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(aiCounterEnabled ? AppTheme.primaryAccent : .white.opacity(0.35))
                        Text(aiCounterEnabled ? "AI Counter ON" : "AI Counter OFF")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(aiCounterEnabled ? .white.opacity(0.8) : .white.opacity(0.35))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(aiCounterEnabled ? AppTheme.primaryAccent.opacity(0.12) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(aiCounterEnabled ? AppTheme.primaryAccent.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: aiCounterEnabled)
            }
        }
    }

    private var coachTipForGuide: String? {
        guard let ex = currentExercise else { return nil }
        if let tip = ExerciseFormTip.tip(for: ex.id, weakZone: weakestZone) {
            return tip.tip
        }
        return ExerciseFormTip.tipForExercise(ex.id)?.tip
    }

    // MARK: - Countdown (Timer-based only)

    private var countdownContent: some View {
        VStack {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.primaryAccent.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Text("\(countdownValue)")
                    .font(.system(size: 120, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.6), radius: 30)
                    .contentTransition(.numericText())
            }

            Text("GET READY")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(AppTheme.primaryAccent)
                .tracking(4)
                .padding(.top, 4)

            Spacer()
            Spacer()
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: countdownValue)
    }

    // MARK: - Active Set (Timer-based only)

    private var activeContent: some View {
        VStack(spacing: 0) {
            Spacer()
            if parsed.isTimeBased {
                timerDisplay
            } else {
                manualRepDisplay
            }
            Spacer()

            coachingBanner
                .padding(.horizontal, 20)

            activeSetInfo
                .padding(.top, 12)
                .padding(.horizontal, 20)

            if parsed.isTimeBased {
                activeActions
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            } else {
                manualRepActions
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
        }
    }

    private var manualRepDisplay: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                targetReached ? AppTheme.success.opacity(0.35) : AppTheme.primaryAccent.opacity(0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(repPulse ? 1.3 : 1.0)

                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 6)
                    .frame(width: 220, height: 220)

                Circle()
                    .trim(from: 0, to: min(1, Double(repCounter.repCount) / Double(max(1, parsed.value))))
                    .stroke(
                        LinearGradient(
                            colors: targetReached
                                ? [AppTheme.success, Color(red: 0.2, green: 1.0, blue: 0.6)]
                                : [AppTheme.primaryAccent, AppTheme.primaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.4), value: repCounter.repCount)

                VStack(spacing: 0) {
                    Text("\(repCounter.repCount)")
                        .font(.system(size: 80, weight: .black))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .scaleEffect(repPulse ? 1.15 : 1.0)
                        .monospacedDigit()

                    Text("of \(parsed.value)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .animation(.spring(duration: 0.15, bounce: 0.5), value: repPulse)

            if targetReached {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("TARGET REACHED")
                        .font(.system(size: 13, weight: .black))
                        .tracking(2)
                }
                .foregroundStyle(AppTheme.success)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.success.opacity(0.15))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: repCounter.repCount)
        .onChange(of: repCounter.repCount) { oldValue, newValue in
            if newValue > oldValue {
                repPulse = true
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    repPulse = false
                }
                if newValue >= parsed.value && !targetReached {
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        targetReached = true
                    }
                    Task {
                        try? await Task.sleep(for: .milliseconds(800))
                        completeCurrentSet()
                    }
                }
            }
        }
    }

    private var manualRepActions: some View {
        HStack(spacing: 10) {
            Button { cancelActiveSet() } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 16))
            }

            Button { manualCountRep() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("TAP REP")
                        .font(.system(size: 15, weight: .black))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primaryAccent, Color(red: 0.1, green: 0.25, blue: 1.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 12, y: 4)
            }

            Button { completeCurrentSet() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("DONE")
                        .font(.system(size: 15, weight: .black))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .frame(width: 100, height: 56)
                .background(
                    targetReached
                        ? LinearGradient(colors: [AppTheme.success, Color(red: 0.1, green: 0.75, blue: 0.4)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: targetReached ? AppTheme.success.opacity(0.3) : .clear, radius: 12, y: 4)
            }
        }
    }

    private var timerDisplay: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 6)
                .frame(width: 220, height: 220)

            Circle()
                .trim(from: 0, to: max(0, 1.0 - Double(timeRemaining) / Double(max(1, parsed.value))))
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.primaryAccent, AppTheme.primaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)

            VStack(spacing: 4) {
                Text("\(timeRemaining)")
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text("seconds")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: timeRemaining)
    }

    private var coachingBanner: some View {
        HStack(spacing: 8) {
            let iconName: String = {
                switch coach.tipCategory {
                case .form: return "figure.core.training"
                case .tempo: return "metronome.fill"
                case .breathing: return "wind"
                case .motivation: return "flame.fill"
                case .correction: return "exclamationmark.triangle.fill"
                }
            }()
            let iconColor: Color = {
                switch coach.tipCategory {
                case .form: return AppTheme.primaryAccent
                case .tempo: return AppTheme.warning
                case .breathing: return AppTheme.success
                case .motivation: return AppTheme.orange
                case .correction: return AppTheme.destructive
                }
            }()

            Image(systemName: iconName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())

            Text(coach.currentTip)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .id(coach.currentTip)
                .transition(.push(from: .bottom))
                .animation(.easeInOut(duration: 0.4), value: coach.currentTip)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .clipShape(.rect(cornerRadius: 12))
        .opacity(coach.currentTip.isEmpty ? 0 : 1)
    }

    private var activeSetInfo: some View {
        HStack(spacing: 4) {
            ForEach(1...parsed.sets, id: \.self) { s in
                Circle()
                    .fill(s < currentSet ? AppTheme.success : (s == currentSet ? AppTheme.primaryAccent : Color.white.opacity(0.1)))
                    .frame(width: 6, height: 6)
                    .animation(.spring(duration: 0.3), value: currentSet)
            }
            Text("SET \(currentSet)/\(parsed.sets)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
                .padding(.leading, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var activeActions: some View {
        HStack(spacing: 10) {
            Button { cancelActiveSet() } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 16))
            }
        }
    }

    // MARK: - Rest

    @State private var restStartTotal: Int = 30

    private var restContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 4) {
                Text("REST")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(4)
                    .padding(.bottom, 4)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.primaryAccent.opacity(0.08), AppTheme.primaryAccent.opacity(0.02), .clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 180
                            )
                        )
                        .frame(width: 320, height: 320)
                        .scaleEffect(restBreathScale)
                        .opacity(restPulseOpacity)

                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 6)
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: max(0, Double(timeRemaining) / Double(max(1, restStartTotal))))
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.primaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)

                    VStack(spacing: 2) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 80, weight: .black))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .scaleEffect(timeRemaining <= 3 && timeRemaining > 0 ? 1.08 : 1.0)
                            .animation(.spring(duration: 0.2), value: timeRemaining)

                        Text("seconds")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }

            if currentSet <= parsed.sets {
                VStack(spacing: 4) {
                    Text("UP NEXT")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .tracking(2)
                    Text("Set \(currentSet) of \(parsed.sets)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                    if let ex = currentExercise {
                        Text(ex.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .padding(.top, 20)
            } else {
                VStack(spacing: 4) {
                    Text("UP NEXT")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .tracking(2)
                    nextExerciseLabel
                }
                .padding(.top, 20)
            }

            Spacer()

            if currentSet > parsed.sets, currentIndex + 1 < exercises.count {
                nextExercisePreview
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }

            HStack(spacing: 8) {
                Button {
                    timeRemaining = max(0, timeRemaining - 15)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                        Text("15s")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 14))
                }

                Button {
                    endRest()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Start Next Set")
                            .font(.system(size: 14, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent, Color(red: 0.1, green: 0.25, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: 14))
                    .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 12, y: 4)
                }

                Button {
                    timeRemaining += 15
                    restStartTotal = max(restStartTotal, timeRemaining)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("15s")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .onAppear { startRestBreathing() }
        .onDisappear { restBreathScale = 1.0 }
        .sensoryFeedback(.impact(weight: .heavy), trigger: timeRemaining == 3)
        .sensoryFeedback(.impact(weight: .heavy), trigger: timeRemaining == 2)
        .sensoryFeedback(.impact(weight: .heavy), trigger: timeRemaining == 1)
    }

    private func startRestBreathing() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            restBreathScale = 1.15
            restPulseOpacity = 0.5
        }
    }

    private var nextExerciseLabel: some View {
        Group {
            if currentIndex + 1 < exercises.count {
                let next = exercises[currentIndex + 1]
                HStack(spacing: 6) {
                    Text("Next:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                    Text(next.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else {
                Text("Last exercise!")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.success)
            }
        }
    }

    private var nextExercisePreview: some View {
        Group {
            if currentIndex + 1 < exercises.count {
                let next = exercises[currentIndex + 1]
                let nextParsed = ExerciseSet.parse(from: next.reps).adjusted(for: difficulty)

                HStack(spacing: 12) {
                    Color(.systemGray6)
                        .frame(width: 56, height: 56)
                        .overlay {
                            AsyncImage(url: URL(string: next.demoImageURL)) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                                } else {
                                    Image(systemName: next.region.icon)
                                        .font(.title3.bold())
                                        .foregroundStyle(AppTheme.primaryAccent.opacity(0.3))
                                }
                            }
                        }
                        .clipShape(.rect(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(next.name.uppercased())
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                            .tracking(0.3)
                        Text(nextParsed.isTimeBased ? "\(nextParsed.value)s × \(nextParsed.sets) sets" : "\(nextParsed.value) reps × \(nextParsed.sets) sets")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    Spacer()

                    Text("UP NEXT")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .tracking(1)
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(.rect(cornerRadius: 14))
            }
        }
    }

    // MARK: - Set Banner

    private var setBannerOverlay: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.success)
                    .symbolEffect(.bounce, value: showSetBanner)

                Text("Set \(setJustCompleted) done")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                if setJustCompleted < parsed.sets {
                    Text("\(parsed.sets - setJustCompleted) left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.06))
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 60)

            Spacer()
        }
    }

    // MARK: - Exercise Transition

    @State private var exTransCheckScale: CGFloat = 0.0
    @State private var exTransCheckY: CGFloat = 80
    @State private var exTransGlow: Double = 0.0
    @State private var exTransRingScale: CGFloat = 0.4
    @State private var exTransRingOpacity: Double = 0.8
    @State private var exTransTextOpacity: Double = 0.0
    @State private var exTransGreenFlash: Double = 0.0

    private var exerciseTransitionView: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.1, green: 0.95, blue: 0.4).opacity(0.3 * exTransGreenFlash), AppTheme.success.opacity(0.1 * exTransGreenFlash), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 350
            )
            .ignoresSafeArea()

            Circle()
                .stroke(AppTheme.success.opacity(exTransRingOpacity), lineWidth: 3)
                .frame(width: 160, height: 160)
                .scaleEffect(exTransRingScale)

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.success.opacity(0.15))
                        .frame(width: 130, height: 130)
                        .scaleEffect(exTransCheckScale)

                    Image(systemName: "checkmark")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(Color(red: 0.1, green: 0.95, blue: 0.4))
                        .shadow(color: AppTheme.success.opacity(exTransGlow), radius: 30)
                        .shadow(color: AppTheme.success.opacity(exTransGlow * 0.5), radius: 60)
                        .scaleEffect(exTransCheckScale)
                        .offset(y: exTransCheckY)
                }

                VStack(spacing: 8) {
                    Text("EXERCISE DONE")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                        .tracking(2)
                        .shadow(color: AppTheme.success.opacity(0.4), radius: 12)

                    if let ex = currentExercise {
                        Text(ex.name.uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.success)
                            .tracking(0.5)
                    }

                    let phrases = [
                        "Abs are being built.",
                        "One step closer to shredded.",
                        "Locked in. Keep going.",
                        "The grind pays off.",
                        "You're a machine.",
                    ]
                    Text(phrases[completedCount % phrases.count])
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 4)
                }
                .opacity(exTransTextOpacity)

                Spacer()
            }
        }
        .sensoryFeedback(.success, trigger: showExerciseTransition)
        .onAppear {
            exTransCheckScale = 0.0
            exTransCheckY = 80
            exTransGlow = 0.0
            exTransRingScale = 0.4
            exTransRingOpacity = 0.8
            exTransTextOpacity = 0.0
            exTransGreenFlash = 0.0

            withAnimation(.spring(duration: 0.4, bounce: 0.45)) {
                exTransCheckScale = 1.0
                exTransCheckY = 0
            }
            withAnimation(.easeOut(duration: 0.5)) {
                exTransGlow = 0.9
                exTransGreenFlash = 1.0
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
                exTransRingScale = 2.5
                exTransRingOpacity = 0
            }
            withAnimation(.spring(duration: 0.4, bounce: 0.2).delay(0.25)) {
                exTransTextOpacity = 1.0
            }
            Task {
                try? await Task.sleep(for: .seconds(1.0))
                withAnimation(.easeIn(duration: 0.4)) {
                    exTransGreenFlash = 0.2
                }
            }
        }
    }



    // MARK: - Camera Setup

    private func setupCamera() {
        guard hasCameraAccess else { return }

        let service = PoseDetectionService { pose in
            Task { @MainActor in
                poseDetected = pose != nil
                if sessionPhase == .active, !parsed.isTimeBased, let pose {
                    repCounter.processPose(pose)
                }
            }
        }
        poseService = service

        cameraManager.frameHandler = { [service] sampleBuffer in
            service.detectPose(in: sampleBuffer)
        }

        cameraManager.configure(position: .front)
        isCameraReady = true
    }

    // MARK: - Logic

    private func startElapsedTimer() {
        totalElapsedTimer?.cancel()
        totalElapsedTimer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                if !showComplete {
                    totalElapsed += 1
                }
            }
        }
    }

    private func startCountdown() {
        countdownValue = 3
        timerTask?.cancel()
        withAnimation(.spring(duration: 0.25)) {
            sessionPhase = .countdown
        }
        timerTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.25, bounce: 0.2)) {
                countdownValue = 2
            }
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.25, bounce: 0.2)) {
                countdownValue = 1
            }
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            beginActiveSet()
        }
    }

    private func beginActiveSet() {
        repCounter.reset()
        targetReached = false
        repPulse = false
        withAnimation(.spring(duration: 0.3)) {
            sessionPhase = .active
        }
        if let ex = currentExercise {
            coach.start(for: ex.id)
            if currentSet == 1 {
                voiceCoach.announceExerciseStart(
                    name: ex.name,
                    sets: parsed.sets,
                    reps: ex.reps,
                    isTimeBased: parsed.isTimeBased
                )
            }
            if !parsed.isTimeBased {
                repCounter.configure(for: ex.id)
            }
        }
        if parsed.isTimeBased {
            timeRemaining = parsed.value
            startSetTimer()
        }
    }

    private func startSetTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                timeRemaining -= 1
                if timeRemaining == 0 {
                    completeCurrentSet()
                    return
                }
            }
        }
    }

    private func manualCountRep() {
        repCounter.repCount += 1
        pulseActive = true
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            pulseActive = false
        }
    }

    private func completeCurrentSet() {
        timerTask?.cancel()
        coach.stop()
        setJustCompleted = currentSet
        voiceCoach.announceSetComplete(setNumber: currentSet, totalSets: parsed.sets)

        if currentSet >= parsed.sets {
            currentSet += 1
            showExerciseCompleteTransition()
        } else {
            showSetCompleteBanner()
            currentSet += 1
            startRest()
        }
    }

    private func showSetCompleteBanner() {
        withAnimation(.spring(duration: 0.4)) {
            showSetBanner = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.3)) {
                showSetBanner = false
            }
        }
    }

    private func showExerciseCompleteTransition() {
        guard let ex = currentExercise else { return }
        if !completedExercises.contains(ex.id) {
            onComplete(ex.id)
            completedCount += 1
        }

        withAnimation(.easeOut(duration: 0.3)) {
            showExerciseTransition = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeIn(duration: 0.3)) {
                showExerciseTransition = false
            }
            try? await Task.sleep(for: .seconds(0.2))

            if currentIndex < exercises.count - 1 {
                startRest()
            } else {
                withAnimation {
                    showComplete = true
                }
            }
        }
    }

    private func startRest() {
        let isLastSetOfExercise = currentSet > parsed.sets
        let restDuration = isLastSetOfExercise ? 60 : 30
        timeRemaining = restDuration
        restStartTotal = restDuration

        withAnimation(.spring(duration: 0.3)) {
            sessionPhase = .resting
        }

        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                timeRemaining -= 1
                if timeRemaining == 0 {
                    endRest()
                    return
                }
            }
        }
    }

    private func endRest() {
        timerTask?.cancel()
        voiceCoach.announceRestOver()

        if currentSet <= parsed.sets {
            repCounter.reset()
            targetReached = false
            timeRemaining = parsed.isTimeBased ? parsed.value : 0
            withAnimation(.spring(duration: 0.3)) {
                sessionPhase = .guide
            }
            triggerAppearAnimation()
        } else {
            if currentIndex < exercises.count - 1 {
                currentIndex += 1
                setupForCurrentExercise()
            } else {
                voiceCoach.announceWorkoutComplete(exerciseCount: completedCount, totalTime: totalElapsed)
                withAnimation {
                    showComplete = true
                }
            }
        }
    }

    private func cancelActiveSet() {
        timerTask?.cancel()
        coach.stop()
        repCounter.reset()
        targetReached = false
        withAnimation(.spring(duration: 0.3)) {
            sessionPhase = .guide
        }
    }

    private func skipExercise() {
        timerTask?.cancel()
        coach.stop()
        guard let ex = currentExercise else { return }
        if !completedExercises.contains(ex.id) {
            onComplete(ex.id)
            completedCount += 1
        }

        if currentIndex < exercises.count - 1 {
            currentIndex += 1
            setupForCurrentExercise()
        } else {
            withAnimation { showComplete = true }
        }
    }

    private func setupForCurrentExercise() {
        sessionPhase = .guide
        currentSet = 1
        repCounter.reset()
        targetReached = false
        timerTask?.cancel()
        timeRemaining = parsed.isTimeBased ? parsed.value : 0
        triggerAppearAnimation()
    }

    private func triggerAppearAnimation() {
        exerciseAppear = false
        withAnimation(.spring(duration: 0.5, bounce: 0.15).delay(0.05)) {
            exerciseAppear = true
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

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Set Pill

struct SetPill: View {
    let number: Int
    let isCompleted: Bool
    let isCurrent: Bool

    @State private var checkScale: CGFloat = 0.0
    @State private var ringFlash: Bool = false

    var body: some View {
        ZStack {
            if isCompleted {
                Circle()
                    .fill(AppTheme.success)
                    .frame(width: 30, height: 30)

                Circle()
                    .fill(AppTheme.success.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .scaleEffect(ringFlash ? 1.8 : 1.0)
                    .opacity(ringFlash ? 0 : 0.5)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .scaleEffect(checkScale)
            } else if isCurrent {
                Circle()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: 30, height: 30)
                Circle()
                    .strokeBorder(AppTheme.primaryAccent.opacity(0.35), lineWidth: 2)
                    .frame(width: 38, height: 38)
                Text("\(number)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 30, height: 30)
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.25))
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: isCompleted) { oldValue, newValue in
            if newValue && !oldValue {
                checkScale = 0.0
                ringFlash = false
                withAnimation(.spring(duration: 0.4, bounce: 0.5).delay(0.05)) {
                    checkScale = 1.0
                }
                withAnimation(.easeOut(duration: 0.6)) {
                    ringFlash = true
                }
            }
        }
        .onAppear {
            if isCompleted {
                checkScale = 1.0
                ringFlash = true
            }
        }
    }
}

// MARK: - SetDot (kept for compatibility)

struct SetDot: View {
    let setNumber: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let isUpcoming: Bool

    var body: some View {
        SetPill(number: setNumber, isCompleted: isCompleted, isCurrent: isCurrent)
    }
}
