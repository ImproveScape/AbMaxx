import SwiftUI
import AVFoundation
import PhotosUI
import UIKit

struct FuelCameraView: View {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var flashOn: Bool = false
    @State private var pulseCorners: Bool = false

    private let brandAccent = AppTheme.primaryAccent

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            #if targetEnvironment(simulator)
            simulatorPlaceholder
            #else
            if AVCaptureDevice.default(for: .video) != nil {
                FuelCameraPreview(flashOn: $flashOn, capturedImage: $capturedImage, onCapture: {
                    dismiss()
                })
                .ignoresSafeArea()
            } else {
                simulatorPlaceholder
            }
            #endif

            cameraOverlay
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onChange(of: selectedItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    capturedImage = uiImage
                    dismiss()
                }
            }
        }
    }

    private var simulatorPlaceholder: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.15), Color(white: 0.08)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "camera.fill").font(.system(size: 48)).foregroundStyle(.secondary)
                Text("Camera Preview").font(.title2.weight(.semibold))
                Text("Install this app on your device\nvia the Rork App to use the camera.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
    }

    private var cameraOverlay: some View {
        VStack(spacing: 0) {
            topBar.padding(.top, 8)
            Spacer()
            scanBrackets.padding(.horizontal, 32)
            Spacer()
            bottomControls
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 44, height: 44).background(.white.opacity(0.15), in: Circle())
            }
            Spacer()
            ABMAXXWordmark(size: .medium)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }

    private var scanBrackets: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height * 0.85)
            let cornerLen: CGFloat = 36
            let lineW: CGFloat = 3.5
            let xOffset = (geo.size.width - size) / 2
            let yOffset = (geo.size.height - size) / 2

            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(.black.opacity(0.0001)).frame(width: size, height: size)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                Group {
                    cornerShape(at: CGPoint(x: xOffset, y: yOffset), corner: .topLeft, length: cornerLen, lineWidth: lineW)
                    cornerShape(at: CGPoint(x: xOffset + size, y: yOffset), corner: .topRight, length: cornerLen, lineWidth: lineW)
                    cornerShape(at: CGPoint(x: xOffset, y: yOffset + size), corner: .bottomLeft, length: cornerLen, lineWidth: lineW)
                    cornerShape(at: CGPoint(x: xOffset + size, y: yOffset + size), corner: .bottomRight, length: cornerLen, lineWidth: lineW)
                }
                .opacity(pulseCorners ? 1.0 : 0.7)
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { pulseCorners = true }
        }
    }

    private func cornerShape(at point: CGPoint, corner: FuelCorner, length: CGFloat, lineWidth: CGFloat) -> some View {
        Path { path in
            switch corner {
            case .topLeft:
                path.move(to: CGPoint(x: point.x, y: point.y + length))
                path.addLine(to: CGPoint(x: point.x, y: point.y + 8))
                path.addQuadCurve(to: CGPoint(x: point.x + 8, y: point.y), control: CGPoint(x: point.x, y: point.y))
                path.addLine(to: CGPoint(x: point.x + length, y: point.y))
            case .topRight:
                path.move(to: CGPoint(x: point.x - length, y: point.y))
                path.addLine(to: CGPoint(x: point.x - 8, y: point.y))
                path.addQuadCurve(to: CGPoint(x: point.x, y: point.y + 8), control: CGPoint(x: point.x, y: point.y))
                path.addLine(to: CGPoint(x: point.x, y: point.y + length))
            case .bottomLeft:
                path.move(to: CGPoint(x: point.x + length, y: point.y))
                path.addLine(to: CGPoint(x: point.x + 8, y: point.y))
                path.addQuadCurve(to: CGPoint(x: point.x, y: point.y - 8), control: CGPoint(x: point.x, y: point.y))
                path.addLine(to: CGPoint(x: point.x, y: point.y - length))
            case .bottomRight:
                path.move(to: CGPoint(x: point.x, y: point.y - length))
                path.addLine(to: CGPoint(x: point.x, y: point.y - 8))
                path.addQuadCurve(to: CGPoint(x: point.x - 8, y: point.y), control: CGPoint(x: point.x, y: point.y))
                path.addLine(to: CGPoint(x: point.x - length, y: point.y))
            }
        }
        .stroke(brandAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }

    nonisolated enum FuelCorner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private var bottomControls: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                Button { flashOn.toggle() } label: {
                    Image(systemName: flashOn ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(flashOn ? .yellow : .white.opacity(0.6))
                        .frame(width: 50, height: 50).background(.white.opacity(0.1), in: Circle())
                }
                .frame(maxWidth: .infinity)

                Button { capturePhoto() } label: {
                    ZStack {
                        Circle().strokeBorder(brandAccent, lineWidth: 4).frame(width: 72, height: 72)
                        Circle().fill(.white).frame(width: 60, height: 60)
                    }
                }
                .frame(maxWidth: .infinity)

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle").font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6)).frame(width: 50, height: 50).background(.white.opacity(0.1), in: Circle())
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)

            Text("Point at your meal to scan").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.4)).padding(.bottom, 8)
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.6), .black.opacity(0.85)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        )
    }

    private func capturePhoto() {
        NotificationCenter.default.post(name: .fuelCameraCapture, object: nil)
    }
}

extension Notification.Name {
    static let fuelCameraCapture = Notification.Name("fuelCameraCapture")
}

struct FuelCameraPreview: UIViewControllerRepresentable {
    @Binding var flashOn: Bool
    @Binding var capturedImage: UIImage?
    let onCapture: () -> Void

    func makeUIViewController(context: Context) -> FuelCameraViewController {
        let vc = FuelCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: FuelCameraViewController, context: Context) {
        uiViewController.setFlash(flashOn)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        let parent: FuelCameraPreview
        init(_ parent: FuelCameraPreview) {
            self.parent = parent
            super.init()
        }

        func didCapture(_ image: UIImage) {
            parent.capturedImage = image
            parent.onCapture()
        }
    }
}

class FuelCameraViewController: UIViewController {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: FuelCameraPreview.Coordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        NotificationCenter.default.addObserver(self, selector: #selector(captureRequested), name: .fuelCameraCapture, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in self?.session.startRunning() }
    }

    func setFlash(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    @objc private func captureRequested() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        session.stopRunning()
    }
}

extension FuelCameraViewController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        Task { @MainActor [weak self] in self?.delegate?.didCapture(image) }
    }
}
