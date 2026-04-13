import SwiftUI

@Observable
@MainActor
class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var profile = UserProfile()
    var scanResult: ScanResult?



    var capturedImage: UIImage?
    var displayThumbnail: UIImage?
    var isAnalyzing: Bool = false
    var analysisComplete: Bool = false
    var poorPhotoDetected: Bool = false
    var photoRejectionMessage: String = "Photo unclear \u{2014} good lighting, shirt off, front facing camera"

    enum OnboardingStep: Int, CaseIterable {
        // Phase 1: HOOK
        case welcome
        case showcase1
        case showcase2
        case showcase3
        case showcase4
        // Phase 2: DATA INVESTMENT
        case surveyGender
        case surveyAbsFrequency
        case surveyAge
        case surveyHeightWeight
        case surveyUsername
        case surveyGoal
        case goalPlan
        case surveyBodyType
        case surveyActivity
        case surveyEquipment
        case surveyBiggestStruggle
        case struggleSolution
        // Phase 3: PROGRAM BUILD
        case generatingProgram
        case withWithout
        case summerCountdown
        // Phase 4: ASPIRE + SOCIAL PROOF
        case transformationVision
        case socialProof
        // Phase 5: SCAN
        case scanCamera
        case scanAnalyzing
        case scanResults
        // Phase 6: RED MOTIVATION (after score reveal)
        case habitTracking
        case goalTracking
        case progressTracking
        case disciplinePath
        // Phase 6.5: NOTIFICATIONS
        case notifications
        // Phase 7: CONVERT
        case paywall
        // Phase 7.5: SECURE ACCOUNT
        case signIn
        // Phase 8: REWARD
        case postPaymentIntro
    }

    var canProceed: Bool {
        switch currentStep {
        case .surveyUsername: return !profile.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .habitTracking: return true
        case .goalTracking: return true
        case .progressTracking: return true
        case .disciplinePath: return true
        case .surveyGender: return true
        case .surveyAbsFrequency: return true
        case .surveyAge: return true
        case .surveyHeightWeight: return true
        case .surveyGoal: return true
        case .goalPlan: return true
        case .surveyBodyType: return true
        case .surveyActivity: return true
        case .surveyEquipment: return true
        case .surveyBiggestStruggle: return !profile.biggestStruggles.isEmpty
        case .struggleSolution: return true
        default: return true
        }
    }

    private static let surveySteps: [OnboardingStep] = [
        .surveyGender, .surveyAbsFrequency, .surveyAge, .surveyHeightWeight, .surveyUsername,
        .surveyGoal, .goalPlan, .surveyBodyType, .surveyActivity, .surveyEquipment, .surveyBiggestStruggle
    ]

    private static let painSteps: [OnboardingStep] = [
        .habitTracking, .goalTracking, .progressTracking, .disciplinePath
    ]

    var surveyProgress: Double {
        guard let idx = Self.surveySteps.firstIndex(of: currentStep) else { return 0 }
        return Double(idx + 1) / Double(Self.surveySteps.count)
    }

    var isPainStep: Bool {
        Self.painSteps.contains(currentStep)
    }

    var painProgress: Double {
        guard let idx = Self.painSteps.firstIndex(of: currentStep) else { return 0 }
        return Double(idx + 1) / Double(Self.painSteps.count)
    }

    var isSurveyStep: Bool {
        Self.surveySteps.contains(currentStep)
    }

    private static let showcaseSteps: [OnboardingStep] = [
        .showcase1, .showcase2, .showcase3, .showcase4
    ]

    var isShowcaseStep: Bool {
        Self.showcaseSteps.contains(currentStep)
    }

    var showcaseStepIndex: Int {
        Self.showcaseSteps.firstIndex(of: currentStep) ?? 0
    }

    var totalOnboardingSteps: Int {
        OnboardingStep.allCases.count
    }

    var currentOnboardingIndex: Int {
        OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
    }

    private static let progressBarSteps: [OnboardingStep] = [
        .showcase1, .showcase2, .showcase3, .showcase4,
        .surveyGender, .surveyAbsFrequency, .surveyAge, .surveyHeightWeight,
        .surveyUsername, .surveyGoal, .goalPlan, .surveyBodyType,
        .surveyActivity, .surveyEquipment, .surveyBiggestStruggle, .struggleSolution,
        .generatingProgram, .withWithout, .summerCountdown,
        .transformationVision, .socialProof,
        .scanAnalyzing, .scanResults,
        .habitTracking, .goalTracking, .progressTracking, .disciplinePath,
        .notifications
    ]

    var showsProgressBar: Bool {
        Self.progressBarSteps.contains(currentStep)
    }

    var onboardingProgress: Double {
        guard let idx = Self.progressBarSteps.firstIndex(of: currentStep) else { return 0 }
        return Double(idx + 1) / Double(Self.progressBarSteps.count)
    }

    func nextStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex + 1 < OnboardingStep.allCases.count else { return }
        currentStep = OnboardingStep.allCases[currentIndex + 1]
    }

    func previousStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        currentStep = OnboardingStep.allCases[currentIndex - 1]
    }

    var progressValue: Double {
        guard let index = OnboardingStep.allCases.firstIndex(of: currentStep) else { return 0 }
        return Double(index) / Double(OnboardingStep.allCases.count - 1)
    }

    var daysUntilSummer: Int {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        var components = DateComponents()
        components.month = 6
        components.day = 21
        components.year = year
        if let summer = calendar.date(from: components), summer > now {
            return calendar.dateComponents([.day], from: now, to: summer).day ?? 0
        }
        components.year = year + 1
        guard let nextSummer = calendar.date(from: components) else { return 0 }
        return calendar.dateComponents([.day], from: now, to: nextSummer).day ?? 0
    }

    func handleCapturedPhoto(_ image: UIImage?) {
        if let image = image {
            capturedImage = downsizeImage(image, maxDimension: 900)
            displayThumbnail = downsizeImage(image, maxDimension: 300)
        } else {
            capturedImage = nil
            displayThumbnail = nil
        }
        isAnalyzing = true
        analysisComplete = false
    }

    private func downsizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func runAnalysis() async {
        isAnalyzing = true
        analysisComplete = false
        poorPhotoDetected = false

        var savedFileName: String?
        let imageForAnalysis = capturedImage
        capturedImage = nil

        if let image = imageForAnalysis {
            autoreleasepool {
                if let photoData = image.jpegData(compressionQuality: 0.7) {
                    let fileName = PhotoStorageService.generateFileName()
                    PhotoStorageService.savePhoto(photoData, fileName: fileName)
                    savedFileName = fileName
                }
            }

            do {
                if let aiResult = try await analyzeWithTimeout(image: image, timeout: 90) {
                    if aiResult.poorPhoto {
                        poorPhotoDetected = true
                        photoRejectionMessage = aiResult.rejectionReason ?? "Photo unclear \u{2014} good lighting, shirt off, front facing camera"
                        isAnalyzing = false
                        return
                    }
                    var scan = ScanResult.fromAnalysis(aiResult)
                    scan.phase = 0
                    scan.level = 0
                    scan.photoFileName = savedFileName
                    scan.enforceMinimums()
                    scanResult = scan
                    analysisComplete = true
                    return
                }
            } catch {
                print("[OnboardingVM] Analysis error: \(error)")
            }
        }

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
        scan.photoFileName = savedFileName
        scan.enforceMinimums()
        scanResult = scan
        analysisComplete = true
    }

    private func analyzeWithTimeout(image: UIImage, timeout: Int) async throws -> AbAnalysisResponse? {
        try await withThrowingTaskGroup(of: AbAnalysisResponse?.self) { group in
            group.addTask {
                await AbScanService.shared.analyzePhoto(image, profile: self.profile)
            }
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                return nil
            }
            let result = try await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }
}
