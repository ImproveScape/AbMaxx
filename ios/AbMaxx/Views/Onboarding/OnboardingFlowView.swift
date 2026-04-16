import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var viewModel: OnboardingViewModel
    let store: StoreViewModel
    let onComplete: (UserProfile, ScanResult?) -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if viewModel.showsProgressBar {
                    questionProgressBar
                }

                Group {
                    stepView
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if viewModel.needsContinueButton {
                    continueButton
                }
            }
        }
        .premiumBackground()
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }

    private var questionProgressBar: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.previousStep() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 36, height: 36)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: geo.size.width * viewModel.questionProgress)
                        .animation(.spring(duration: 0.4), value: viewModel.questionProgress)
                }
            }
            .frame(height: 4)
        }
        .padding(.leading, 12)
        .padding(.trailing, 24)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var continueButton: some View {
        Button(action: { goForward() }) {
            Text(viewModel.continueButtonText)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    viewModel.canProceed
                        ? AppTheme.accentGradient
                        : LinearGradient(colors: [AppTheme.muted], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(.capsule)
                .shadow(color: viewModel.canProceed ? AppTheme.primaryAccent.opacity(0.4) : .clear, radius: 20, y: 6)
        }
        .disabled(!viewModel.canProceed)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func goForward() {
        viewModel.nextStep()
    }


    @ViewBuilder
    private var stepView: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeView(onStart: { goForward() })

        case .surveyUsername:
            SurveyUsernameView(username: $viewModel.profile.username)

        case .surveyGender:
            SurveyGenderView(gender: $viewModel.selectedGender)

        case .surveyGoal:
            SurveyGoalView(goal: $viewModel.selectedGoal)

        case .surveyAge:
            SurveyAgeView(dateOfBirth: $viewModel.profile.dateOfBirth)

        case .surveyHeightWeight:
            SurveyHeightWeightView(
                heightFeet: $viewModel.profile.heightFeet,
                heightInches: $viewModel.profile.heightInches,
                weightLbs: $viewModel.profile.weightLbs,
                useMetric: $viewModel.profile.useMetric
            )

        case .surveyAbsFrequency:
            SurveyAbsFrequencyView(frequency: $viewModel.selectedAbsFreq)

        case .surveyBodyType:
            SurveyBodyTypeView(category: $viewModel.selectedBodyFat)

        case .absComparison:
            AbsComparisonBarView()

        case .surveyActivity:
            SurveyActivityView(level: $viewModel.selectedActivity)

        case .surveyTrainingSource:
            SurveyTrainingSourceView(selectedSource: $viewModel.profile.trainingSource)

        case .surveyEquipment:
            SurveyEquipmentView(equipment: $viewModel.selectedEquipment)

        case .surveyBiggestStruggle:
            SurveyBiggestStruggleView(selectedStruggles: $viewModel.profile.biggestStruggles)

        case .surveyAccomplish:
            SurveyAccomplishView(selectedGoal: $viewModel.profile.accomplishGoal)

        case .progressGraph:
            ProgressGraphView()

        case .goalPlan:
            GoalPlanView(
                goal: viewModel.profile.goal,
                username: viewModel.profile.displayName
            )

        case .scanIntro:
            ScanIntroView(username: viewModel.profile.displayName) { goForward() }

        case .scanCamera:
            OnboardingScanCameraView(
                onCapture: { image in
                    viewModel.handleCapturedPhoto(image)
                    goForward()
                },
                onDismiss: {
                    viewModel.goBackToScanIntro()
                },
                showRejection: viewModel.poorPhotoDetected,
                rejectionMessage: viewModel.photoRejectionMessage
            )

        case .scanConfirm:
            OnboardingScanConfirmView(
                capturedImage: viewModel.scanThumbnail,
                onAnalyze: {
                    viewModel.confirmAndStartAnalysis()
                    goForward()
                },
                onRetake: {
                    viewModel.resetScanState()
                    viewModel.currentStep = .scanCamera
                }
            )

        case .scanAnalyzing:
            OnboardingScanAnalyzingView(viewModel: viewModel) { goForward() }

        case .scanBadNews:
            if let result = viewModel.scanResult {
                BadNewsRevealView(scanResult: result, username: viewModel.profile.displayName) { goForward() }
            } else {
                Color.clear.onAppear { goForward() }
            }

        case .scanResults:
            if let result = viewModel.scanResult {
                ScanResultsPreviewView(
                    scanResult: result,
                    estimatedWeeks: viewModel.profile.estimatedWeeksToAbs
                ) { goForward() }
            } else {
                Color.clear.onAppear { goForward() }
            }

        case .socialProof:
            SocialProofView(onContinue: { goForward() }, onBack: { viewModel.previousStep() })

        case .notifications:
            NotificationPermissionView { goForward() }

        case .generatingProgram:
            GeneratingProgramView(profile: viewModel.profile) { goForward() }

        case .customPlanCreated:
            CustomPlanCreatedView(username: viewModel.profile.displayName, scanResult: viewModel.scanResult) { goForward() }

        case .feelConfidentShowcase:
            FeelConfidentShowcaseView { goForward() }

        case .allInOnePlace:
            AllInOnePlaceView { goForward() }

        case .paywall:
            Color.clear.onAppear {
                viewModel.profile.isSubscribed = true
                viewModel.profile.transformationStartDate = Date()
                goForward()
            }

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
