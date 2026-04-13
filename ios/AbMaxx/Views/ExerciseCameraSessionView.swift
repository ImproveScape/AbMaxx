import SwiftUI
import AVFoundation
import Vision

struct ExerciseCameraSessionView: View {
    let exercise: Exercise
    let targetReps: Int
    let isTimeBased: Bool
    let targetSeconds: Int
    let onComplete: (Int) -> Void
    let onSkip: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var cameraManager = ExerciseCameraManager()
    @State private var poseService: PoseDetectionService?
    @State private var repCounter = RepCountingService()
    @State private var coachingService = LiveCoachingService()
    @State private var currentPose: DetectedPose?
    @State private var sessionState: SessionState = .preview
    @State private var countdown: Int = 3
    @State private var holdTimer: Int = 0
    @State private var isHoldingPosition: Bool = false
    @State private var timerTask: Task<Void, Never>?
    @State private var showCompletion: Bool = false
    @State private var poseDetected: Bool = false
    @State private var repPulse: Bool = false
    @State private var targetReached: Bool = false
    @State private var formPulse: Bool = false

    private let neonBlue = Color(red: 0.0, green: 0.85, blue: 1.0)

    nonisolated enum SessionState: Sendable {
        case preview
        case countdown
        case active
        case completed
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            #if targetEnvironment(simulator)
            simulatorPlaceholder
            #else
            if AVCaptureDevice.default(for: .video) != nil {
                cameraContent
            } else {
                simulatorPlaceholder
            }
            #endif

            if showCompletion {
                ExerciseCompletionOverlay(
                    exerciseName: exercise.name,
                    repsCompleted: isTimeBased ? targetSeconds : repCounter.repCount,
                    targetReps: isTimeBased ? targetSeconds : targetReps,
                    onContinue: {
                        onComplete(isTimeBased ? targetSeconds : repCounter.repCount)
                    }
                )
                .transition(.opacity)
            }
        }
        .statusBarHidden()
        .onDisappear {
            timerTask?.cancel()
            cameraManager.stop()
            coachingService.stop()
        }
    }

    private var cameraContent: some View {
        ZStack {
            ExerciseCameraPreview(session: cameraManager.captureSession)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()

                if sessionState == .preview {
                    previewOverlay
                        .transition(.opacity)
                }
                if sessionState == .countdown {
                    countdownOverlay
                        .transition(.opacity)
                }
                if sessionState == .active {
                    activeOverlay
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            setupCamera()
        }
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Text(exercise.name.uppercased())
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.5)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.primaryAccent)
                    ABMAXXWordmark(size: .small)
                }

                Spacer()

                if isTimeBased {
                    Text("\(targetSeconds)s")
                        .font(.system(size: 13, weight: .heavy, design: .default))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.primaryAccent.opacity(0.7))
                        .clipShape(.rect(cornerRadius: 8))
                } else {
                    Text("\(targetReps) reps")
                        .font(.system(size: 13, weight: .heavy, design: .default))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.primaryAccent.opacity(0.7))
                        .clipShape(.rect(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.black.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .top)
            )

            HStack {
                Button {
                    timerTask?.cancel()
                    cameraManager.stop()
                    coachingService.stop()
                    onSkip()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    timerTask?.cancel()
                    cameraManager.stop()
                    coachingService.stop()
                    onSkip()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private var previewOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            if poseDetected {
                VStack(spacing: 8) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.success)
                    Text("Body Detected")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Position yourself in frame")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
            }

            positioningGuide

            VStack(spacing: 8) {
                Text(exercise.name.uppercased())
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(1)
                Text(isTimeBased ? "\(targetSeconds) seconds" : "\(targetReps) reps")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(neonBlue)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(Color.black.opacity(0.6))
            .clipShape(.rect(cornerRadius: 16))

            Button {
                startCountdown()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Start")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [neonBlue, AppTheme.primaryAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(.capsule)
                .shadow(color: neonBlue.opacity(0.5), radius: 20, y: 6)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    private var countdownOverlay: some View {
        VStack {
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

                Text("\(countdown)")
                    .font(.system(size: 120, weight: .black, design: .default))
                    .foregroundStyle(.white)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.8), radius: 30)
                    .contentTransition(.numericText())
            }
            Text("GET READY")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(AppTheme.primaryAccent)
                .tracking(4)
            Spacer()
            Spacer()
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: countdown)
    }

    private var activeOverlay: some View {
        VStack(spacing: 0) {
            if isTimeBased {
                timedActiveUI
            } else {
                repActiveUI
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Live Form Feedback Banner

    private var formFeedbackBanner: some View {
        Group {
            if let feedback = repCounter.formFeedback {
                HStack(spacing: 8) {
                    Image(systemName: formIcon(for: feedback.quality))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(formColor(for: feedback.quality))

                    Text(feedback.message)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    formColor(for: feedback.quality).opacity(0.25)
                        .background(Color.black.opacity(0.5))
                )
                .clipShape(Capsule())
                .scaleEffect(formPulse ? 1.05 : 1.0)
                .animation(.spring(duration: 0.2), value: formPulse)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: repCounter.formFeedback?.message)
    }

    private var coachingBanner: some View {
        Group {
            if !coachingService.currentTip.isEmpty && sessionState == .active {
                HStack(spacing: 8) {
                    Image(systemName: coachIcon(for: coachingService.tipCategory))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(coachColor(for: coachingService.tipCategory))

                    Text(coachingService.currentTip)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: coachingService.currentTip)
    }

    private var repActiveUI: some View {
        VStack(spacing: 0) {
            Spacer()

            formFeedbackBanner
                .padding(.bottom, 12)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                targetReached ? AppTheme.success.opacity(0.4) : AppTheme.primaryAccent.opacity(0.3),
                                targetReached ? AppTheme.success.opacity(0.1) : AppTheme.primaryAccent.opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(repPulse ? 1.5 : 1.0)

                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: Double(repCounter.repCount) / Double(max(1, targetReps)))
                    .stroke(
                        LinearGradient(
                            colors: targetReached
                                ? [AppTheme.success, Color(red: 0.2, green: 1.0, blue: 0.6)]
                                : [AppTheme.primaryAccent, neonBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.4), value: repCounter.repCount)

                Text("\(repCounter.repCount)")
                    .font(.system(size: 110, weight: .black, design: .default))
                    .foregroundStyle(.white)
                    .shadow(color: targetReached ? AppTheme.success.opacity(0.9) : AppTheme.primaryAccent.opacity(0.9), radius: 30)
                    .shadow(color: targetReached ? AppTheme.success.opacity(0.5) : AppTheme.primaryAccent.opacity(0.5), radius: 60)
                    .contentTransition(.numericText())
                    .scaleEffect(repPulse ? 1.25 : 1.0)
            }
            .animation(.spring(duration: 0.2, bounce: 0.6), value: repPulse)

            Text("\(repCounter.repCount)/\(targetReps)")
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 12)

            coachingBanner
                .padding(.top, 16)

            Spacer()

            if targetReached {
                completeSetButton
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                progressBar
                    .padding(.bottom, 50)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: repCounter.repCount)
        .onChange(of: repCounter.repCount) { oldValue, newValue in
            if newValue > oldValue {
                repPulse = true
                Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    repPulse = false
                }
                if newValue >= targetReps && !targetReached {
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        targetReached = true
                    }
                }
            }
        }
        .onChange(of: repCounter.formFeedback?.message) { _, newValue in
            if newValue != nil {
                formPulse = true
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    formPulse = false
                }
            }
        }
    }

    private var completeSetButton: some View {
        VStack(spacing: 12) {
            Text("TARGET REACHED")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(AppTheme.success)
                .tracking(2)

            Button {
                completeExercise()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Complete Set")
                        .font(.system(size: 18, weight: .black))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [AppTheme.success, Color(red: 0.1, green: 0.8, blue: 0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(.capsule)
                .shadow(color: AppTheme.success.opacity(0.6), radius: 20, y: 6)
            }
            .padding(.horizontal, 40)
        }
        .sensoryFeedback(.success, trigger: targetReached)
    }

    private var timedActiveUI: some View {
        VStack(spacing: 20) {
            Spacer()

            formFeedbackBanner

            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 200, height: 200)

                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: Double(holdTimer) / Double(targetSeconds))
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent, neonBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.4), value: holdTimer)

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

                Text("\(holdTimer)")
                    .font(.system(size: 90, weight: .black, design: .default))
                    .foregroundStyle(.white)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.9), radius: 30)
                    .contentTransition(.numericText())
            }

            if isHoldingPosition {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 8, height: 8)
                    Text("Holding")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.orange)
                        .frame(width: 8, height: 8)
                    Text("Get in position")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
            }

            coachingBanner

            Spacer()

            progressBar
                .padding(.bottom, 50)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: holdTimer)
    }

    private var progressBar: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 5)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, neonBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * min(1, isTimeBased
                                ? Double(holdTimer) / Double(max(1, targetSeconds))
                                : Double(repCounter.repCount) / Double(max(1, targetReps))),
                            height: 5
                        )
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 8)
                        .animation(.spring(duration: 0.3), value: isTimeBased ? holdTimer : repCounter.repCount)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 40)
        }
    }

    private var simulatorPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(neonBlue.opacity(0.6))
            Text("AI Rep Counter")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Install this app on your device\nvia the Rork App to use the camera.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Text(exercise.name.uppercased())
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(1)
                Text(isTimeBased ? "\(targetSeconds) seconds" : "\(targetReps) reps")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(neonBlue)
            }
            .padding(20)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(neonBlue.opacity(0.3), lineWidth: 1)
            )

            HStack(spacing: 16) {
                Button {
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.12))
                        .clipShape(.rect(cornerRadius: 14))
                }

                Button {
                    onComplete(isTimeBased ? targetSeconds : targetReps)
                } label: {
                    Text("Mark Done")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryAccent)
                        .clipShape(.rect(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Button {
                timerTask?.cancel()
                cameraManager.stop()
                coachingService.stop()
                onSkip()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(AppTheme.muted)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundView().ignoresSafeArea())
    }

    private var positioningGuide: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "iphone.rear.camera")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(neonBlue)
                Text("For best tracking:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            VStack(alignment: .leading, spacing: 3) {
                guideTip("Stand 4–6 feet from your phone")
                guideTip("Prop phone at waist height, angled up")
                guideTip("Make sure your full torso is visible")
                guideTip("Good lighting helps accuracy")
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.6))
        .clipShape(.rect(cornerRadius: 14))
        .padding(.horizontal, 32)
        .padding(.top, 8)
    }

    private func guideTip(_ text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(neonBlue.opacity(0.6))
                .frame(width: 4, height: 4)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Setup & Logic

    private func setupCamera() {
        repCounter.configure(for: exercise.id)

        let service = PoseDetectionService { pose in
            Task { @MainActor in
                currentPose = pose
                poseDetected = pose != nil
                if sessionState == .active, let pose {
                    if isTimeBased {
                        isHoldingPosition = pose.hasEnoughJoints
                        repCounter.processPose(pose)
                    } else {
                        repCounter.processPose(pose)
                    }
                    coachingService.updateWithPoseFeedback(
                        repCounter.formFeedback,
                        repCount: repCounter.repCount
                    )
                }
            }
        }
        poseService = service

        cameraManager.frameHandler = { [service] sampleBuffer in
            service.detectPose(in: sampleBuffer)
        }

        cameraManager.configure(position: .front)
    }

    private func startCountdown() {
        countdown = 3
        timerTask?.cancel()
        withAnimation(.spring(duration: 0.25)) {
            sessionState = .countdown
        }
        timerTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.25, bounce: 0.2)) {
                countdown = 2
            }
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.25, bounce: 0.2)) {
                countdown = 1
            }
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            sessionState = .active
            coachingService.start(for: exercise.id)
            if isTimeBased {
                startHoldTimer()
            }
        }
    }

    private func startHoldTimer() {
        timerTask?.cancel()
        holdTimer = 0
        timerTask = Task {
            while !Task.isCancelled && holdTimer < targetSeconds {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if isHoldingPosition || currentPose != nil {
                    withAnimation {
                        holdTimer += 1
                    }
                }
                if holdTimer >= targetSeconds {
                    completeExercise()
                    return
                }
            }
        }
    }

    private func completeExercise() {
        timerTask?.cancel()
        coachingService.stop()
        withAnimation(.spring(duration: 0.4)) {
            sessionState = .completed
            showCompletion = true
        }
    }

    // MARK: - Helpers

    private func formIcon(for quality: FormQuality) -> String {
        switch quality {
        case .good: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .bad: "xmark.circle.fill"
        }
    }

    private func formColor(for quality: FormQuality) -> Color {
        switch quality {
        case .good: AppTheme.success
        case .warning: AppTheme.warning
        case .bad: AppTheme.destructive
        }
    }

    private func coachIcon(for category: LiveCoachingService.TipCategory) -> String {
        switch category {
        case .form: "figure.core.training"
        case .tempo: "metronome.fill"
        case .breathing: "wind"
        case .motivation: "flame.fill"
        case .correction: "exclamationmark.triangle.fill"
        }
    }

    private func coachColor(for category: LiveCoachingService.TipCategory) -> Color {
        switch category {
        case .form: neonBlue
        case .tempo: AppTheme.primaryAccent
        case .breathing: Color(red: 0.4, green: 0.8, blue: 1.0)
        case .motivation: AppTheme.orange
        case .correction: AppTheme.warning
        }
    }
}
