import SwiftUI

@Observable
@MainActor
class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var profile = UserProfile()
    var scanResult: ScanResult?

    var selectedGender: Gender? = nil
    var selectedGoal: AbsGoal? = nil
    var selectedActivity: ActivityLevel? = nil
    var selectedBodyFat: BodyFatCategory? = nil
    var selectedAbsFreq: AbsTrainingFrequency? = nil
    var selectedEquipment: EquipmentSetting? = nil

    var capturedImage: UIImage?
    var scanThumbnail: UIImage?
    var preparedBase64: String?
    var isAnalyzing: Bool = false
    var analysisComplete: Bool = false
    var poorPhotoDetected: Bool = false
    var photoRejectionMessage: String = "Photo unclear — good lighting, shirt off, front facing camera"
    var pendingAnalysisOutcome: AnalysisOutcome?
    var analysisAPIFinished: Bool = false

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case surveyGender
        case surveyGoal
        case progressGraph
        case surveyAge
        case surveyHeightWeight
        case surveyAbsFrequency
        case surveyBodyType
        case absComparison
        case surveyActivity
        case surveyTrainingSource
        case surveyEquipment
        case surveyBiggestStruggle
        case surveyAccomplish
        case goalPlan
        case surveyUsername
        case scanIntro
        case scanCamera
        case scanConfirm
        case scanAnalyzing
        case scanBadNews
        case scanResults
        case socialProof
        case notifications
        case generatingProgram
        case customPlanCreated
        case feelConfidentShowcase
        case allInOnePlace
        case paywall
        case postPaymentIntro
    }

    private static let questionSteps: [OnboardingStep] = [
        .surveyGender, .surveyGoal, .progressGraph, .surveyAge, .surveyHeightWeight,
        .surveyAbsFrequency, .surveyBodyType, .absComparison, .surveyActivity, .surveyTrainingSource, .surveyEquipment, .surveyBiggestStruggle, .surveyAccomplish,
        .goalPlan, .surveyUsername,
        .scanIntro, .scanCamera, .scanConfirm, .scanAnalyzing, .scanBadNews, .scanResults,
        .socialProof, .notifications, .generatingProgram
    ]

    func goBackToScanIntro() {
        resetScanState()
        currentStep = .scanIntro
    }

    var isQuestionStep: Bool {
        Self.questionSteps.contains(currentStep)
    }

    var questionProgress: Double {
        guard let idx = Self.questionSteps.firstIndex(of: currentStep) else { return 0 }
        return Double(idx + 1) / Double(Self.questionSteps.count)
    }

    var canProceed: Bool {
        switch currentStep {
        case .surveyUsername: return !profile.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .surveyGender: return selectedGender != nil
        case .surveyGoal: return selectedGoal != nil
        case .surveyActivity: return selectedActivity != nil
        case .surveyBodyType: return selectedBodyFat != nil
        case .surveyAbsFrequency: return selectedAbsFreq != nil
        case .surveyEquipment: return selectedEquipment != nil
        case .surveyTrainingSource: return profile.trainingSource != nil
        case .surveyBiggestStruggle: return !profile.biggestStruggles.isEmpty
        case .surveyAccomplish: return profile.accomplishGoal != nil
        default: return true
        }
    }

    var needsContinueButton: Bool {
        switch currentStep {
        case .surveyUsername, .surveyGender, .surveyGoal, .progressGraph, .surveyAge,
             .surveyHeightWeight, .surveyAbsFrequency, .surveyBodyType, .absComparison, .surveyActivity,
             .surveyTrainingSource, .surveyEquipment, .surveyBiggestStruggle, .surveyAccomplish, .goalPlan:
            return true
        default:
            return false
        }
    }

    var showsProgressBar: Bool {
        guard Self.questionSteps.contains(currentStep) else { return false }
        switch currentStep {
        case .scanCamera, .scanConfirm, .scanAnalyzing, .generatingProgram:
            return false
        default:
            return true
        }
    }

    var continueButtonText: String {
        switch currentStep {
        case .goalPlan: return "Let's Go"
        case .feelConfidentShowcase, .allInOnePlace: return "Continue"
        default: return "Continue"
        }
    }

    var totalOnboardingSteps: Int {
        OnboardingStep.allCases.count
    }

    var currentOnboardingIndex: Int {
        OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
    }

    func syncSelectionsToProfile() {
        if let g = selectedGender { profile.gender = g }
        if let g = selectedGoal { profile.goal = g }
        if let a = selectedActivity { profile.activityLevel = a }
        if let b = selectedBodyFat { profile.bodyFatCategory = b }
        if let f = selectedAbsFreq { profile.absTrainingFrequency = f }
        if let e = selectedEquipment { profile.equipmentSetting = e }
    }

    func nextStep() {
        syncSelectionsToProfile()
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex + 1 < OnboardingStep.allCases.count else { return }
        let next = OnboardingStep.allCases[currentIndex + 1]
        currentStep = next
        if next == .customPlanCreated {
            persistProgress()
        }
    }

    func previousStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        if currentStep == .generatingProgram || currentStep == .customPlanCreated || currentStep == .feelConfidentShowcase || currentStep == .allInOnePlace || currentStep == .paywall || currentStep == .postPaymentIntro {
            return
        }
        currentStep = OnboardingStep.allCases[currentIndex - 1]
    }

    var progressValue: Double {
        guard let index = OnboardingStep.allCases.firstIndex(of: currentStep) else { return 0 }
        return Double(index) / Double(OnboardingStep.allCases.count - 1)
    }

    func handleCapturedPhoto(_ image: UIImage?) {
        preparedBase64 = nil
        scanThumbnail = nil
        capturedImage = nil
        if let image {
            autoreleasepool {
                let size = image.size
                guard size.width > 0, size.height > 0 else { return }

                let thumbDim: CGFloat = 300
                let thumbScale = min(thumbDim / max(size.width, size.height), 1.0)
                let thumbSize = CGSize(width: floor(size.width * thumbScale), height: floor(size.height * thumbScale))
                let fmt = UIGraphicsImageRendererFormat()
                fmt.scale = 1.0
                let thumbRenderer = UIGraphicsImageRenderer(size: thumbSize, format: fmt)
                scanThumbnail = thumbRenderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: thumbSize))
                }

                let apiDim: CGFloat = 400
                let apiScale = min(apiDim / max(size.width, size.height), 1.0)
                let apiSize = CGSize(width: floor(size.width * apiScale), height: floor(size.height * apiScale))
                let apiFormat = UIGraphicsImageRendererFormat()
                apiFormat.scale = 1.0
                let apiRenderer = UIGraphicsImageRenderer(size: apiSize, format: apiFormat)
                let apiImage = apiRenderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: apiSize))
                }
                if let jpegData = apiImage.jpegData(compressionQuality: 0.4) {
                    preparedBase64 = jpegData.base64EncodedString()
                    print("[OnboardingScan] Pre-encoded base64: \(jpegData.count / 1024)KB")
                }
            }
        }
        poorPhotoDetected = false
    }

    func confirmAndStartAnalysis() {
        isAnalyzing = true
        analysisComplete = false
        poorPhotoDetected = false
        capturedImage = nil
        pendingAnalysisOutcome = nil
        analysisAPIFinished = false

        if let thumb = scanThumbnail {
            autoreleasepool {
                if let photoData = thumb.jpegData(compressionQuality: 0.7) {
                    let fileName = PhotoStorageService.generateFileName()
                    PhotoStorageService.savePhoto(photoData, fileName: fileName)
                    pendingSaveFileName = fileName
                }
            }
        }

        let savedFileName = pendingSaveFileName
        let base64 = preparedBase64
        let apiKey = Config.EXPO_PUBLIC_ANTHROPIC_API_KEY
        preparedBase64 = nil

        Task {
            let outcome: AnalysisOutcome

            if let base64, !apiKey.isEmpty {
                let networkResult = await AbScanService.runAnalysisNetwork(base64: base64, apiKey: apiKey)

                switch networkResult {
                case .success(let aiResult):
                    if aiResult.poorPhoto {
                        outcome = .poorPhoto(aiResult.rejectionReason ?? "Photo unclear \u{2014} good lighting, shirt off, front facing camera")
                    } else {
                        var scan = ScanResult.fromAnalysis(aiResult)
                        scan.phase = 0
                        scan.level = 0
                        scan.photoFileName = savedFileName
                        scan.enforceMinimums()
                        outcome = .success(scan)
                    }
                case .failure(let error):
                    if error.isBadPhoto {
                        outcome = .poorPhoto(error.userMessage)
                    } else {
                        outcome = buildFallbackOutcome(photoFileName: savedFileName)
                    }
                }
            } else {
                outcome = buildFallbackOutcome(photoFileName: savedFileName)
            }

            pendingAnalysisOutcome = outcome
            analysisAPIFinished = true
        }
    }

    private var pendingSaveFileName: String?

    func resetScanState() {
        isAnalyzing = false
        analysisComplete = false
        poorPhotoDetected = false
        capturedImage = nil
        scanThumbnail = nil
        preparedBase64 = nil
        pendingSaveFileName = nil
        pendingAnalysisOutcome = nil
        analysisAPIFinished = false
    }

    nonisolated enum AnalysisOutcome: Sendable {
        case success(ScanResult)
        case poorPhoto(String)
        case fallback(ScanResult)
    }

    func applyPendingOutcome() {
        guard let outcome = pendingAnalysisOutcome else {
            let fallback = buildFallbackOutcome(photoFileName: pendingSaveFileName)
            applyOutcome(fallback)
            return
        }
        applyOutcome(outcome)
    }

    private func applyOutcome(_ outcome: AnalysisOutcome) {
        switch outcome {
        case .success(let scan):
            scanResult = scan
            isAnalyzing = false
            analysisComplete = true
        case .poorPhoto(let message):
            poorPhotoDetected = true
            photoRejectionMessage = message
            isAnalyzing = false
        case .fallback(let scan):
            scanResult = scan
            isAnalyzing = false
            analysisComplete = true
        }
    }

    func runAnalysis() async {
        isAnalyzing = true
        analysisComplete = false
        poorPhotoDetected = false
        confirmAndStartAnalysis()
    }

    private func buildFallbackOutcome(photoFileName: String? = nil) -> AnalysisOutcome {
        return .fallback(buildFallbackResult(photoFileName: photoFileName))
    }

    private func buildFallbackResult(photoFileName: String? = nil) -> ScanResult {
        let fallback = AbScanService.shared.profileBasedScoring(
            profile: profile,
            previousScan: nil,
            daysOnProgram: 0,
            exercisesCompleted: 0
        )
        var scan = ScanResult.fromAnalysis(fallback)
        scan.wasAIAnalyzed = false
        scan.phase = 0
        scan.level = 0
        scan.photoFileName = photoFileName
        scan.enforceMinimums()
        return scan
    }

    // MARK: - Onboarding Progress Persistence

    private static let progressKey = "onboarding_reachedPlanCreated"
    private static let profileKey = "onboarding_savedProfile"
    private static let scanKey = "onboarding_savedScan"
    private static let selectionsKey = "onboarding_savedSelections"

    private func persistProgress() {
        UserDefaults.standard.set(true, forKey: Self.progressKey)
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Self.profileKey)
        }
        if let scan = scanResult, let data = try? JSONEncoder().encode(scan) {
            UserDefaults.standard.set(data, forKey: Self.scanKey)
        }
        let selections = SavedSelections(
            gender: selectedGender,
            goal: selectedGoal,
            activity: selectedActivity,
            bodyFat: selectedBodyFat,
            absFreq: selectedAbsFreq,
            equipment: selectedEquipment
        )
        if let data = try? JSONEncoder().encode(selections) {
            UserDefaults.standard.set(data, forKey: Self.selectionsKey)
        }
    }

    func restoreProgressIfNeeded() -> Bool {
        guard UserDefaults.standard.bool(forKey: Self.progressKey) else { return false }
        if let data = UserDefaults.standard.data(forKey: Self.profileKey),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = saved
        }
        if let data = UserDefaults.standard.data(forKey: Self.scanKey),
           let saved = try? JSONDecoder().decode(ScanResult.self, from: data) {
            scanResult = saved
        }
        if let data = UserDefaults.standard.data(forKey: Self.selectionsKey),
           let saved = try? JSONDecoder().decode(SavedSelections.self, from: data) {
            selectedGender = saved.gender
            selectedGoal = saved.goal
            selectedActivity = saved.activity
            selectedBodyFat = saved.bodyFat
            selectedAbsFreq = saved.absFreq
            selectedEquipment = saved.equipment
        }
        currentStep = .customPlanCreated
        return true
    }

    static func clearSavedProgress() {
        UserDefaults.standard.removeObject(forKey: progressKey)
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: scanKey)
        UserDefaults.standard.removeObject(forKey: selectionsKey)
    }

    nonisolated private struct SavedSelections: Codable, Sendable {
        var gender: Gender?
        var goal: AbsGoal?
        var activity: ActivityLevel?
        var bodyFat: BodyFatCategory?
        var absFreq: AbsTrainingFrequency?
        var equipment: EquipmentSetting?
    }
}
