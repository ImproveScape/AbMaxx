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
            AppTheme.background.ignoresSafeArea()

            switch flowStep {
            case .camera:
                AbScanCameraView(
                    onCapture: { image in
                        guard let image else { return }
                        capturedImage = ScanView.downsizeImage(image, maxDimension: 900)
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

            case .analyzing:
                AbScanAnalyzingView(capturedImage: capturedImage, resultReady: pendingResult != nil) {
                    if let result = pendingResult {
                        vm.addScanResult(result)
                    }
                    vm.scanJustCompleted = true
                    vm.shouldNavigateToAnalysis = true
                    pendingResult = nil
                    capturedImage = nil
                    dismiss()
                }
                .transition(.opacity)
            }
        }
    }

    private var photoConfirmationView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            LinearGradient(
                colors: [.clear, .clear, Color.black.opacity(0.6), Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack {
                Spacer()

                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            capturedImage = nil
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
                            Text("Analyze")
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
        withAnimation(.easeInOut(duration: 0.4)) {
            flowStep = .analyzing
        }
        Task {
            var savedFileName: String?
            autoreleasepool {
                if let jpegData = image.jpegData(compressionQuality: 0.6) {
                    let fileName = PhotoStorageService.generateFileName()
                    PhotoStorageService.savePhoto(jpegData, fileName: fileName)
                    savedFileName = fileName
                }
            }
            guard var result = await vm.analyzeAbPhoto(image) else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    flowStep = .camera
                    showPoorPhotoAlert = true
                }
                return
            }
            result.photoFileName = savedFileName
            pendingResult = result
        }
    }

    private static func downsizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
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
