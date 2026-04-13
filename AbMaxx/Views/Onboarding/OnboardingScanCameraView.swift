import SwiftUI
import AVFoundation
import PhotosUI

struct OnboardingScanCameraView: View {
    let onCapture: (UIImage?) -> Void
    let onSkip: () -> Void
    var showRejection: Bool = false
    var rejectionMessage: String = ""

    @State private var cameraManager: CameraManager?
    @State private var isCameraAvailable: Bool = false
    @State private var isCapturing: Bool = false
    @State private var flashActive: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoadingPhoto: Bool = false
    @State private var scanLineOffset: CGFloat = 0
    @State private var isScanning: Bool = false
    @State private var scanPulse: Bool = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            #if targetEnvironment(simulator)
            cameraPlaceholder
            #else
            if isCameraAvailable, let manager = cameraManager {
                CameraPreviewView(session: manager.session)
                    .ignoresSafeArea()
            } else {
                cameraPlaceholder
            }
            #endif

            if isScanning {
                scanningEffect
            }

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 8)

                Spacer()

                if showRejection {
                    rejectionBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 16)
                }

                bottomControls
                    .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.error, trigger: showRejection)
        .onChange(of: showRejection) { _, newValue in
            if newValue {
                isCapturing = false
                stopScanning()
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            isLoadingPhoto = true
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    isLoadingPhoto = false
                    startScanning()
                    onCapture(image)
                } else {
                    isLoadingPhoto = false
                }
                selectedItem = nil
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraManager?.stop()
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                Button {
                    onSkip()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                Spacer()
            }

            Text("ABMaxx")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
    }

    private var bottomControls: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                Button {
                    flashActive.toggle()
                    toggleTorch(on: flashActive)
                } label: {
                    Image(systemName: flashActive ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(flashActive ? AppTheme.warning : .white)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(flashActive ? 0.2 : 0.1))
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    guard !isCapturing else { return }
                    isCapturing = true
                    startScanning()
                    capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 4)
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 66, height: 66)

                        if isCapturing {
                            ProgressView()
                                .tint(AppTheme.primaryAccent)
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.2))
                        }
                    }
                    .opacity(isCapturing ? 0.6 : 1)
                }
                .disabled(isCapturing)
                .sensoryFeedback(.impact(weight: .heavy), trigger: isCapturing)

                Spacer()

                HStack(spacing: 16) {
                    Button {
                        cameraManager?.switchCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(isCapturing || isLoadingPhoto)
                }
            }
            .padding(.horizontal, 24)

            Button {
                onSkip()
            } label: {
                Text("Skip for now")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private var scanningEffect: some View {
        GeometryReader { _ in
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.primaryAccent.opacity(0),
                                AppTheme.primaryAccent.opacity(0.4),
                                AppTheme.secondaryAccent.opacity(0.6),
                                AppTheme.primaryAccent.opacity(0.4),
                                AppTheme.primaryAccent.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 3)
                    .blur(radius: 1)
                    .overlay(
                        Rectangle()
                            .fill(AppTheme.primaryAccent.opacity(0.12))
                            .frame(height: 60)
                            .blur(radius: 20)
                    )
                    .offset(y: scanLineOffset)

                Rectangle()
                    .fill(AppTheme.primaryAccent.opacity(scanPulse ? 0.06 : 0))
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scanPulse)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var rejectionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.destructive)

            VStack(alignment: .leading, spacing: 2) {
                Text("Photo Rejected")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(rejectionMessage)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.destructive.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.destructive.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    private var cameraPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.background, AppTheme.cardSurface, AppTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.3))
                Text("Camera Preview")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                Text("Install on your device via Rork App\nto use the camera.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func setupCamera() {
        #if targetEnvironment(simulator)
        isCameraAvailable = false
        #else
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil else {
            isCameraAvailable = false
            return
        }
        let manager = CameraManager()
        manager.configure()
        cameraManager = manager
        isCameraAvailable = true
        Task.detached {
            manager.start()
        }
        #endif
    }

    private func capturePhoto() {
        #if targetEnvironment(simulator)
        onCapture(nil)
        #else
        guard let manager = cameraManager else {
            onCapture(nil)
            return
        }
        manager.capturePhoto { image in
            onCapture(image)
        }
        #endif
    }

    private func startScanning() {
        isScanning = true
        scanPulse = true
        scanLineOffset = -UIScreen.main.bounds.height / 2
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            scanLineOffset = UIScreen.main.bounds.height / 2
        }
    }

    private func stopScanning() {
        isScanning = false
        scanPulse = false
    }

    private func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}
