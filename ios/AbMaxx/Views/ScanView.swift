import SwiftUI

enum ScanFlowStep {
    case camera
    case confirm
    case analyzing
}

struct ScanView: View {
    @Bindable var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var flowStep: ScanFlowStep = .camera
    @State private var pendingResult: ScanResult?
    @State private var capturedImage: UIImage?
    @State private var showPoorPhotoAlert: Bool = false

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            switch flowStep {
            case .camera:
                AbScanCameraView(
                    onCapture: { image in
                        guard let image else { return }
                        capturedImage = image
                        showPoorPhotoAlert = false
                        withAnimation(.easeInOut(duration: 0.3)) {
                            flowStep = .confirm
                        }
                    },
                    onDismiss: {
                        dismiss()
                    },
                    isValidating: false,
                    showRejection: showPoorPhotoAlert,
                    rejectionMessage: "Photo unclear \u{2014} good lighting, shirt off, front facing camera"
                )
                .transition(.opacity)

            case .confirm:
                photoConfirmationView
                    .transition(.opacity)
                    .sensoryFeedback(.impact(weight: .light), trigger: showPoorPhotoAlert)

            case .analyzing:
                AbScanAnalyzingView(capturedImage: capturedImage, resultReady: pendingResult != nil) {
                    if let result = pendingResult {
                        vm.addScanResult(result)
                        vm.scanJustCompleted = true
                        vm.shouldNavigateToAnalysis = true
                        pendingResult = nil
                        capturedImage = nil
                        dismiss()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            flowStep = .confirm
                            showPoorPhotoAlert = true
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }

    private var photoConfirmationView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 16))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }

                Spacer(minLength: 16)

                if showPoorPhotoAlert {
                    let scanError = AbScanService.shared.lastScanError
                    let isBadPhoto = scanError?.isBadPhoto ?? true
                    let errorMessage = scanError?.userMessage ?? "No abs detected \u{2014} make sure your midsection is visible, shirt off, good lighting."
                    let errorIcon = isBadPhoto ? "exclamationmark.triangle.fill" : "wifi.slash"
                    let errorTitle = isBadPhoto ? "Photo Rejected" : "Analysis Failed"
                    let errorColor: Color = isBadPhoto ? .red : .orange

                    HStack(spacing: 12) {
                        Image(systemName: errorIcon)
                            .font(.title3)
                            .foregroundStyle(errorColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(errorTitle)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(3)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(errorColor.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(errorColor.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            capturedImage = nil
                            showPoorPhotoAlert = false
                            flowStep = .camera
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .bold))
                            Text("Retake")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.18))
                        .clipShape(.rect(cornerRadius: 16))
                    }

                    Button {
                        analyzePhoto()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Analyze My Abs")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryAccent)
                        .clipShape(.rect(cornerRadius: 16))
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: flowStep)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func analyzePhoto() {
        guard let image = capturedImage else { return }
        showPoorPhotoAlert = false
        withAnimation(.easeInOut(duration: 0.4)) {
            flowStep = .analyzing
        }
        Task {
            guard var result = await vm.analyzeAbPhoto(image) else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    flowStep = .confirm
                    showPoorPhotoAlert = true
                }
                return
            }
            if let jpegData = image.jpegData(compressionQuality: 0.6) {
                let fileName = PhotoStorageService.generateFileName()
                PhotoStorageService.savePhoto(jpegData, fileName: fileName)
                result.photoFileName = fileName
            }
            pendingResult = result
        }
    }
}

struct ScanTip: View {
    let icon: String
    let text: String
    var color: Color = AppTheme.primaryAccent

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
        }
    }
}
