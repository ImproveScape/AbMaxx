import SwiftUI
import AVFoundation
import UIKit

struct BarcodeScannerView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var manualBarcode: String = ""
    @State private var scannedCode: String = ""
    @State private var isLookingUp: Bool = false
    @State private var lookupResult: NutritionLookupResult?
    @State private var errorMessage: String?
    @State private var cameraAvailable: Bool = false

    private let brandAccent = AppTheme.primaryAccent

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLookingUp {
                    lookingUpState
                } else if let result = lookupResult {
                    resultState(result)
                } else {
                    scannerState
                }
            }
            .background(BackgroundView().ignoresSafeArea())
            .navigationTitle("Barcode Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                #if targetEnvironment(simulator)
                cameraAvailable = false
                #else
                cameraAvailable = AVCaptureDevice.default(for: .video) != nil
                #endif
            }
        }
    }

    private var scannerState: some View {
        VStack(spacing: 0) {
            if cameraAvailable {
                BarcodeCameraView(onBarcodeScanned: handleBarcode)
                    .frame(height: 300).clipShape(.rect(cornerRadius: 20))
                    .padding(.horizontal, 16).padding(.top, 16)
                HStack(spacing: 8) {
                    Image(systemName: "viewfinder").font(.system(size: 13, weight: .medium)).foregroundStyle(brandAccent)
                    Text("Point camera at a barcode").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                }
                .padding(.top, 14)
            } else {
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(brandAccent.opacity(0.1)).frame(width: 80, height: 80)
                        Image(systemName: "barcode.viewfinder").font(.system(size: 36, weight: .medium)).foregroundStyle(brandAccent)
                    }
                    VStack(spacing: 6) {
                        Text("Barcode Scanner").font(.system(size: 22, weight: .bold))
                        Text("Camera unavailable in simulator.\nEnter a barcode manually below.")
                            .font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
            }

            manualEntrySection

            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppTheme.warning)
                    Text(error).font(.system(size: 13)).foregroundStyle(.secondary)
                }
                .padding(14).frame(maxWidth: .infinity).background(AppTheme.warning.opacity(0.08)).clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal, 16)
            }
            Spacer()
        }
    }

    private var manualEntrySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "number").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                TextField("Enter barcode number...", text: $manualBarcode).font(.system(size: 16)).keyboardType(.numberPad).submitLabel(.search)
            }
            .padding(14).background(Color(white: 0.1)).clipShape(.rect(cornerRadius: 14))

            Button {
                let code = manualBarcode.trimmingCharacters(in: .whitespaces)
                guard !code.isEmpty else { return }
                handleBarcode(code)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .semibold))
                    Text("Look Up Barcode").font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                .brandDeepGradientBackground(cornerRadius: 14)
            }
            .disabled(manualBarcode.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(manualBarcode.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 16).padding(.top, 20)
    }

    private var lookingUpState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(brandAccent.opacity(0.08)).frame(width: 100, height: 100)
                Image(systemName: "barcode").font(.system(size: 40, weight: .medium)).foregroundStyle(brandAccent.opacity(0.5))
            }
            VStack(spacing: 10) {
                ProgressView().controlSize(.large).tint(brandAccent)
                Text("Looking up barcode...").font(.system(size: 17, weight: .semibold))
                Text(scannedCode).font(.system(size: 14, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func resultState(_ result: NutritionLookupResult) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 16))
                        Text("Product Found").font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Button("Scan Again") { resetScanner() }.font(.system(size: 13, weight: .semibold)).foregroundStyle(brandAccent)
                    }
                    .padding(.horizontal, 16).padding(.top, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.name).font(.system(size: 18, weight: .bold)).foregroundStyle(.primary)
                                Text(result.servingSize).font(.system(size: 13, weight: .medium)).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(result.calories)").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(brandAccent)
                                Text("cal").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                            }
                        }
                        HStack(spacing: 12) {
                            barcodeMacroChip("Protein", value: result.protein, color: .blue)
                            barcodeMacroChip("Carbs", value: result.carbs, color: AppTheme.success)
                            barcodeMacroChip("Fat", value: result.fat, color: .purple)
                        }
                    }
                    .padding(18).background(Color(white: 0.1)).clipShape(.rect(cornerRadius: 18))
                    .padding(.horizontal, 16)
                }
            }
            .scrollIndicators(.hidden)

            Button {
                viewModel.addFoodFromAIResult(result, mealType: .lunch)
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 15))
                    Text("Add Food").font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .brandDeepGradientBackground(cornerRadius: 16)
            }
            .padding(.horizontal, 16).padding(.bottom, 8)
        }
    }

    private func barcodeMacroChip(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value))g").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12).background(color.opacity(0.08)).clipShape(.rect(cornerRadius: 12))
    }

    private func handleBarcode(_ barcode: String) {
        scannedCode = barcode; isLookingUp = true; errorMessage = nil; lookupResult = nil
        Task {
            await viewModel.lookupBarcode(barcode)
            if let result = viewModel.barcodeResult {
                lookupResult = result
            } else {
                errorMessage = viewModel.aiErrorMessage ?? "Product not found. Try a different barcode."
            }
            isLookingUp = false
            viewModel.scannedBarcode = ""
        }
    }

    private func resetScanner() {
        lookupResult = nil; errorMessage = nil; scannedCode = ""; manualBarcode = ""
        viewModel.aiSearchResults = []; viewModel.barcodeResult = nil; viewModel.aiErrorMessage = nil
    }
}

struct BarcodeCameraView: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeCameraViewController {
        let controller = BarcodeCameraViewController()
        controller.onBarcodeScanned = onBarcodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeCameraViewController, context: Context) {}
}

class BarcodeCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasDetected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else { return }
        session.addInput(input)
        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else { return }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .code93, .itf14, .dataMatrix, .qr]
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview; captureSession = session

        let scanFrame = UIView()
        scanFrame.backgroundColor = .clear
        scanFrame.layer.borderColor = UIColor(red: 45/255, green: 59/255, blue: 255/255, alpha: 1.0).cgColor
        scanFrame.layer.borderWidth = 2.5; scanFrame.layer.cornerRadius = 16
        scanFrame.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanFrame)
        NSLayoutConstraint.activate([
            scanFrame.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanFrame.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scanFrame.widthAnchor.constraint(equalToConstant: 260),
            scanFrame.heightAnchor.constraint(equalToConstant: 140)
        ])
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        Task { @MainActor in
            guard !hasDetected,
                  let metadataObject = metadataObjects.first,
                  let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }
            hasDetected = true
            captureSession?.stopRunning()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onBarcodeScanned?(stringValue)
        }
    }
}
