import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var viewModel: OnboardingViewModel
    let store: StoreViewModel
    let onComplete: (UserProfile, ScanResult?) -> Void
    var onReturningSignIn: (() -> Void)?

    @State private var direction: TransitionDirection = .forward

    enum TransitionDirection {
        case forward, backward
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.showsProgressBar {
                    onboardingProgressBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                stepView
                    .id(viewModel.currentStep)
                    .transition(stepTransition)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.currentStep)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.showsProgressBar)

        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }

    private var onboardingProgressBar: some View {
        HStack(spacing: 12) {
            Button(action: { goBack() }) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 32, height: 32)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.onboardingProgress)
                        .animation(.spring(duration: 0.5), value: viewModel.onboardingProgress)

                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: geo.size.width * viewModel.onboardingProgress)
                        .blur(radius: 4)
                        .animation(.spring(duration: 0.5), value: viewModel.onboardingProgress)
                }
            }
            .frame(height: 4)
        }
        .padding(.leading, 16)
        .padding(.trailing, 24)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }


    private func goForward() {
        direction = .forward
        withAnimation(.easeInOut(duration: 0.35)) {
            viewModel.nextStep()
        }
    }

    private func goBack() {
        direction = .backward
        withAnimation(.easeInOut(duration: 0.35)) {
            viewModel.previousStep()
        }
    }

    private var stepTransition: AnyTransition {
        switch direction {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch viewModel.currentStep {
        // Phase 1: HOOK
        case .welcome:
            WelcomeView(onStart: { goForward() }, onSignIn: onReturningSignIn)
        case .showcase1:
            ProductShowcaseView(page: 0) { goForward() }
        case .showcase2:
            ProductShowcaseView(page: 1) { goForward() }
        case .showcase3:
            ProductShowcaseView(page: 2) { goForward() }
        case .showcase4:
            ProductShowcaseView(page: 3) { goForward() }

        // Phase 2: DATA INVESTMENT
        case .surveyGender:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyGenderView(gender: $viewModel.profile.gender)
            }
        case .surveyAbsFrequency:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyAbsFrequencyView(frequency: $viewModel.profile.absTrainingFrequency)
            }
        case .surveyAge:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyAgeView(dateOfBirth: $viewModel.profile.dateOfBirth)
            }
        case .surveyHeightWeight:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyHeightWeightView(
                    heightFeet: $viewModel.profile.heightFeet,
                    heightInches: $viewModel.profile.heightInches,
                    weightLbs: $viewModel.profile.weightLbs,
                    useMetric: $viewModel.profile.useMetric
                )
            }
        case .surveyUsername:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyUsernameView(username: $viewModel.profile.username)
            }
        case .surveyGoal:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyGoalView(goal: $viewModel.profile.goal)
            }
        case .goalPlan:
            StandalonePage(
                showBack: false,
                buttonText: "Let's Go",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                GoalPlanView(
                    goal: viewModel.profile.goal,
                    username: viewModel.profile.displayName
                )
            }
        case .surveyBodyType:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyBodyTypeView(category: $viewModel.profile.bodyFatCategory)
            }
        case .surveyActivity:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyActivityView(level: $viewModel.profile.activityLevel)
            }
        case .surveyEquipment:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyEquipmentView(equipment: $viewModel.profile.equipmentSetting)
            }

        case .surveyBiggestStruggle:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SurveyBiggestStruggleView(selectedStruggles: $viewModel.profile.biggestStruggles)
            }
        case .struggleSolution:
            StandalonePage(
                showBack: false,
                buttonText: "Let's Do This",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                StruggleSolutionView(
                    selectedStruggles: viewModel.profile.biggestStruggles,
                    username: viewModel.profile.displayName
                )
            }

        // Phase 3: PROGRAM BUILD
        case .generatingProgram:
            GeneratingProgramView(profile: viewModel.profile) { goForward() }
        case .withWithout:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                WithWithoutChartView(estimatedWeeks: viewModel.profile.estimatedWeeksToAbs)
            }
        case .summerCountdown:
            StandalonePage(
                showBack: false,
                buttonText: "Continue",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SummerCountdownView(daysUntilSummer: viewModel.daysUntilSummer)
            }

        // Phase 5: ASPIRE + SOCIAL PROOF
        case .transformationVision:
            StandalonePage(
                showBack: false,
                buttonText: "I'm Ready",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                TransformationVisionView(username: viewModel.profile.displayName)
            }
        case .socialProof:
            StandalonePage(
                showBack: false,
                buttonText: "Scan My Abs",
                canProceed: viewModel.canProceed,
                onBack: { goBack() },
                onContinue: { goForward() }
            ) {
                SocialProofView()
            }

        // Phase 6: SCAN
        case .scanCamera:
            OnboardingScanCameraView(
                onCapture: { image in
                    viewModel.poorPhotoDetected = false
                    viewModel.handleCapturedPhoto(image)
                    goForward()
                },
                onSkip: {
                    viewModel.poorPhotoDetected = false
                    viewModel.handleCapturedPhoto(nil)
                    goForward()
                },
                showRejection: viewModel.poorPhotoDetected,
                rejectionMessage: viewModel.photoRejectionMessage
            )
        case .scanAnalyzing:
            OnboardingScanAnalyzingView(viewModel: viewModel) { goForward() }
        case .scanResults:
            if let result = viewModel.scanResult {
                ScanResultsPreviewView(
                    scanResult: result,
                    estimatedWeeks: viewModel.profile.estimatedWeeksToAbs
                ) { goForward() }
            }

        // Phase 6: RED MOTIVATION (after score reveal)
        case .habitTracking:
            RedMotivationPageView(
                currentPage: 0,
                totalPages: 4,
                onBack: { goBack() },
                onNext: { goForward() }
            )
        case .goalTracking:
            RedMotivationPageView(
                currentPage: 1,
                totalPages: 4,
                onBack: { goBack() },
                onNext: { goForward() }
            )
        case .progressTracking:
            RedMotivationPageView(
                currentPage: 2,
                totalPages: 4,
                onBack: { goBack() },
                onNext: { goForward() }
            )
        case .disciplinePath:
            RedMotivationPageView(
                currentPage: 3,
                totalPages: 4,
                onBack: { goBack() },
                onNext: { goForward() },
                currentScore: viewModel.scanResult?.overallScore ?? 42
            )

        // Phase 6.5: NOTIFICATIONS
        case .notifications:
            NotificationPermissionView { goForward() }

        // Phase 7: CONVERT
        case .paywall:
            PaywallView(store: store) {
                viewModel.profile.isSubscribed = true
                viewModel.profile.transformationStartDate = Date()
                goForward()
            }

        case .signIn:
            SignInView(
                onComplete: {
                    Task {
                        await AuthenticationService.shared.saveProfileToCloud(
                            profile: viewModel.profile,
                            scanResults: viewModel.scanResult.map { [$0] } ?? []
                        )
                    }
                    goForward()
                },
                onSkip: { goForward() },
                isReturningUser: false
            )

        // Phase 8: REWARD
        case .postPaymentIntro:
            PostPaymentIntroView(
                scanResult: viewModel.scanResult,
                profile: viewModel.profile
            ) {
                var profile = viewModel.profile
                profile.hasCompletedOnboarding = true
                onComplete(profile, viewModel.scanResult)
            }
        }
    }
}

struct StandalonePage<Content: View>: View {
    let showBack: Bool
    let buttonText: String
    let canProceed: Bool
    let onBack: () -> Void
    let onContinue: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    if showBack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 44, height: 44)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button(action: onContinue) {
                    Text(buttonText)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            canProceed
                                ? AppTheme.accentGradient
                                : LinearGradient(colors: [AppTheme.muted], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(.capsule)
                        .shadow(color: canProceed ? AppTheme.primaryAccent.opacity(0.5) : .clear, radius: 24, y: 6)
                }
                .disabled(!canProceed)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}
