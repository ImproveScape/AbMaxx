import SwiftUI
import AVFoundation
import Photos
import AVKit

struct TransformationVideoView: View {
    @Bindable var vm: AppViewModel
    @State private var isGenerating: Bool = false
    @State private var videoURL: URL?
    @State private var showVideoPreview: Bool = false
    @State private var savedToPhotos: Bool = false
    @State private var errorMessage: String?
    @State private var pulseAnimation: Bool = false
    @State private var generationProgress: Double = 0
    @State private var secondsPerPhoto: Double = 2.0

    private var scansWithPhotos: [ScanResult] {
        vm.scanResults.filter { $0.hasPhoto }.sorted { $0.date < $1.date }
    }

    private var hasEnoughScans: Bool {
        scansWithPhotos.count >= 2
    }

    var body: some View {
        VStack(spacing: 0) {
            if !hasEnoughScans {
                notEnoughScansView
            } else if isGenerating {
                generatingView
            } else if let url = videoURL {
                videoPreviewSection(url: url)
            } else {
                createVideoSection
            }
        }
    }

    private var notEnoughScansView: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.primaryAccent.opacity(0.08))
                    .frame(width: 48, height: 48)
                Image(systemName: "film.stack")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Transformation Video")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                Text("Complete at least 2 weekly scans to unlock your transformation video")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Loading Animation

    private var generatingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(AppTheme.cardSurface, lineWidth: 4)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: generationProgress)
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "film.stack.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 6) {
                Text("Rendering Your Transformation")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(Int(generationProgress * 100))%")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundStyle(AppTheme.primaryAccent)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Create Video Section with Duration Control

    private var createVideoSection: some View {
        VStack(spacing: 12) {
            Button {
                generateVideo()
            } label: {
                HStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppTheme.primaryAccent,
                                        AppTheme.primaryAccent.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)

                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    }
                    .padding(.trailing, 14)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create Transformation Video")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)

                        HStack(spacing: 6) {
                            Text("\(scansWithPhotos.count) weeks")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryAccent)

                            Circle()
                                .fill(AppTheme.muted.opacity(0.5))
                                .frame(width: 3, height: 3)

                            if let first = scansWithPhotos.first, let last = scansWithPhotos.last {
                                let diff = last.overallScore - first.overallScore
                                Text(diff >= 0 ? "+\(diff) pts" : "\(diff) pts")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(diff >= 0 ? AppTheme.success : AppTheme.destructive)
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
                .padding(14)
                .background(
                    ZStack {
                        AppTheme.cardSurface
                        LinearGradient(
                            colors: [AppTheme.primaryAccent.opacity(0.06), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                )
                .clipShape(.rect(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent.opacity(0.4), AppTheme.primaryAccent.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: AppTheme.primaryAccent.opacity(0.15), radius: 20, y: 8)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: isGenerating)

            // Duration Control
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)

                Text("Display Time")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        if secondsPerPhoto > 0.5 {
                            secondsPerPhoto -= 0.5
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.cardSurfaceElevated, in: Circle())
                    }

                    Text(String(format: "%.1fs", secondsPerPhoto))
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(width: 44)

                    Button {
                        if secondsPerPhoto < 5.0 {
                            secondsPerPhoto += 0.5
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.cardSurfaceElevated, in: Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppTheme.border, lineWidth: 1)
            )
        }
    }

    private func videoPreviewSection(url: URL) -> some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                VideoPlayerView(url: url)
                    .frame(height: 480)
                    .clipShape(.rect(cornerRadius: 20))

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        videoURL = nil
                        savedToPhotos = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(12)
            }

            HStack(spacing: 10) {
                Button {
                    saveToPhotos(url: url)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: savedToPhotos ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(savedToPhotos ? AppTheme.success : .white)

                        Text(savedToPhotos ? "Saved" : "Save")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        savedToPhotos
                            ? AnyShapeStyle(AppTheme.success.opacity(0.15))
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                savedToPhotos ? AppTheme.success.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .disabled(savedToPhotos)

                ShareLink(item: url) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Share")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.cardSurfaceElevated)
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.destructive)
            }
        }
        .sensoryFeedback(.success, trigger: savedToPhotos)
    }

    private func generateVideo() {
        guard hasEnoughScans else { return }
        isGenerating = true
        errorMessage = nil
        generationProgress = 0

        Task {
            let scans = scansWithPhotos
            let images: [(image: UIImage, scan: ScanResult, week: Int)] = scans.enumerated().compactMap { index, scan in
                guard let img = scan.loadImage() else { return nil }
                return (image: img, scan: scan, week: index + 1)
            }

            guard images.count >= 2 else {
                isGenerating = false
                errorMessage = "Could not load scan photos"
                return
            }

            let holdDuration = secondsPerPhoto
            let url = await createTransformationVideo(from: images, secondsPerPhoto: holdDuration)

            withAnimation(.spring(duration: 0.4)) {
                videoURL = url
                isGenerating = false
            }

            if url == nil {
                errorMessage = "Failed to generate video"
            }
        }
    }

    private func saveToPhotos(url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                Task { @MainActor in
                    errorMessage = "Photo library access required"
                }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                Task { @MainActor in
                    if success {
                        savedToPhotos = true
                    } else {
                        errorMessage = "Could not save video"
                    }
                }
            }
        }
    }

    // MARK: - Orientation Fix

    private func normalizedCGImage(from uiImage: UIImage) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let targetSize = CGSize(width: uiImage.size.width, height: uiImage.size.height)
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let normalized = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return normalized.cgImage
    }

    // MARK: - Video Generation

    private func createTransformationVideo(
        from frames: [(image: UIImage, scan: ScanResult, week: Int)],
        secondsPerPhoto: Double
    ) async -> URL? {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AbMaxx_Transformation_\(UUID().uuidString).mp4")

        let size = CGSize(width: 1080, height: 1920)
        let fps: Int32 = 30
        let holdFrames = Int(secondsPerPhoto * Double(fps))
        let transitionFrames = 15

        let totalFramesEstimate = frames.count * holdFrames + (frames.count - 1) * transitionFrames

        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else { return nil }

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height)
            ]
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        var frameIndex = 0

        for (i, frame) in frames.enumerated() {
            guard let cgImage = normalizedCGImage(from: frame.image) else { continue }

            for f in 0..<holdFrames {
                while !writerInput.isReadyForMoreMediaData {
                    try? await Task.sleep(for: .milliseconds(10))
                }

                let time = CMTime(value: CMTimeValue(frameIndex), timescale: fps)
                guard let pool = adaptor.pixelBufferPool else { continue }
                var pixelBuffer: CVPixelBuffer?
                CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
                guard let buffer = pixelBuffer else { continue }

                renderFrame(
                    to: buffer,
                    size: size,
                    image: cgImage,
                    scan: frame.scan,
                    week: frame.week,
                    fadeProgress: f < 10 && i > 0 ? Double(f) / 10.0 : 1.0
                )

                adaptor.append(buffer, withPresentationTime: time)
                frameIndex += 1

                if frameIndex % 5 == 0 {
                    let progress = Double(frameIndex) / Double(totalFramesEstimate)
                    await MainActor.run {
                        generationProgress = min(progress, 0.95)
                    }
                }
            }

            if i < frames.count - 1 {
                guard let nextCG = normalizedCGImage(from: frames[i + 1].image) else { continue }

                for t in 0..<transitionFrames {
                    while !writerInput.isReadyForMoreMediaData {
                        try? await Task.sleep(for: .milliseconds(10))
                    }

                    let progress = Double(t) / Double(transitionFrames)
                    let time = CMTime(value: CMTimeValue(frameIndex), timescale: fps)
                    guard let pool = adaptor.pixelBufferPool else { continue }
                    var pixelBuffer: CVPixelBuffer?
                    CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
                    guard let buffer = pixelBuffer else { continue }

                    renderTransitionFrame(
                        to: buffer,
                        size: size,
                        fromImage: cgImage,
                        toImage: nextCG,
                        fromScan: frame.scan,
                        toScan: frames[i + 1].scan,
                        fromWeek: frame.week,
                        toWeek: frames[i + 1].week,
                        progress: progress
                    )

                    adaptor.append(buffer, withPresentationTime: time)
                    frameIndex += 1
                }
            }
        }

        await MainActor.run { generationProgress = 1.0 }

        writerInput.markAsFinished()
        await writer.finishWriting()
        return writer.status == .completed ? outputURL : nil
    }

    // MARK: - Frame Rendering

    private func renderFrame(
        to buffer: CVPixelBuffer,
        size: CGSize,
        image: CGImage,
        scan: ScanResult,
        week: Int,
        fadeProgress: Double
    ) {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return }

        context.setFillColor(CGColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))

        // Draw photo
        context.saveGState()
        context.setAlpha(fadeProgress)
        let imageSize = CGSize(width: image.width, height: image.height)
        let scale = max(size.width / imageSize.width, size.height / imageSize.height)
        let scaledW = imageSize.width * scale
        let scaledH = imageSize.height * scale
        let x = (size.width - scaledW) / 2
        let y = (size.height - scaledH) / 2
        context.draw(image, in: CGRect(x: x, y: y, width: scaledW, height: scaledH))
        context.restoreGState()

        // Gradient overlays
        drawGradients(context: context, size: size)

        // Watermark + scores
        drawWatermark(context: context, size: size, scan: scan, week: week)
    }

    private func renderTransitionFrame(
        to buffer: CVPixelBuffer,
        size: CGSize,
        fromImage: CGImage,
        toImage: CGImage,
        fromScan: ScanResult,
        toScan: ScanResult,
        fromWeek: Int,
        toWeek: Int,
        progress: Double
    ) {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return }

        context.setFillColor(CGColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))

        let drawImage = { (img: CGImage, a: CGFloat) in
            context.saveGState()
            context.setAlpha(a)
            let imgSize = CGSize(width: img.width, height: img.height)
            let sc = max(size.width / imgSize.width, size.height / imgSize.height)
            let sw = imgSize.width * sc
            let sh = imgSize.height * sc
            let ix = (size.width - sw) / 2
            let iy = (size.height - sh) / 2
            context.draw(img, in: CGRect(x: ix, y: iy, width: sw, height: sh))
            context.restoreGState()
        }

        drawImage(fromImage, CGFloat(1.0 - progress))
        drawImage(toImage, CGFloat(progress))

        drawGradients(context: context, size: size)

        let activeScan = progress < 0.5 ? fromScan : toScan
        let activeWeek = progress < 0.5 ? fromWeek : toWeek
        drawWatermark(context: context, size: size, scan: activeScan, week: activeWeek)
    }

    // MARK: - Gradient Overlays

    private func drawGradients(context: CGContext, size: CGSize) {
        let gradientSpace = CGColorSpaceCreateDeviceRGB()

        // Bottom gradient (stronger)
        let bottomColors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.85),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        ] as CFArray
        if let grad = CGGradient(colorsSpace: gradientSpace, colors: bottomColors, locations: [0, 1]) {
            context.drawLinearGradient(
                grad,
                start: CGPoint(x: size.width / 2, y: size.height),
                end: CGPoint(x: size.width / 2, y: size.height - 500),
                options: []
            )
        }

        // Top gradient
        let topColors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.7),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        ] as CFArray
        if let grad = CGGradient(colorsSpace: gradientSpace, colors: topColors, locations: [0, 1]) {
            context.drawLinearGradient(
                grad,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: 300),
                options: []
            )
        }
    }

    // MARK: - Watermark & Scores

    private func drawWatermark(context: CGContext, size: CGSize, scan: ScanResult, week: Int) {
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let muted = CGColor(red: 0.55, green: 0.58, blue: 0.75, alpha: 1)
        let accentR: CGFloat = 45/255
        let accentG: CGFloat = 59/255
        let accentB: CGFloat = 255/255
        let accent = CGColor(red: accentR, green: accentG, blue: accentB, alpha: 1)

        // Top-left: ABMAXX brand
        drawText(context: context, text: "ABMAXX", at: CGPoint(x: 50, y: 60), fontSize: 28, weight: .black, color: white, centered: false, tracking: 6)

        // Accent line under brand
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(context.height))
        context.scaleBy(x: 1, y: -1)
        context.setFillColor(accent)
        context.fill(CGRect(x: 50, y: 95, width: 40, height: 3))
        context.restoreGState()

        // Top-right: Overall score circle
        let scoreX: CGFloat = size.width - 90
        let scoreY: CGFloat = 75
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(context.height))
        context.scaleBy(x: 1, y: -1)

        // Score circle background
        let circleRect = CGRect(x: scoreX - 35, y: scoreY - 35, width: 70, height: 70)
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
        context.fillEllipse(in: circleRect)
        context.setStrokeColor(accent)
        context.setLineWidth(2.5)
        context.strokeEllipse(in: circleRect)
        context.restoreGState()

        drawText(context: context, text: "\(scan.overallScore)", at: CGPoint(x: scoreX, y: scoreY - 12), fontSize: 32, weight: .black, color: white, centered: true, tracking: 0)
        drawText(context: context, text: "SCORE", at: CGPoint(x: scoreX, y: scoreY + 24), fontSize: 9, weight: .heavy, color: muted, centered: true, tracking: 3)

        // Bottom section: Week + region scores
        let bottomY: CGFloat = size.height - 60

        // Week label
        drawText(context: context, text: "WEEK \(week)", at: CGPoint(x: size.width / 2, y: bottomY - 130), fontSize: 52, weight: .black, color: white, centered: true, tracking: 4)

        // Region scores bar
        let regions: [(String, Int)] = [
            ("UPPER", scan.upperAbsScore),
            ("LOWER", scan.lowerAbsScore),
            ("OBLIQUES", scan.obliquesScore),
            ("CORE", scan.deepCoreScore)
        ]

        let barY = bottomY - 55
        let totalBarW: CGFloat = size.width - 100
        let regionW: CGFloat = totalBarW / CGFloat(regions.count)
        let startX: CGFloat = 50

        for (idx, region) in regions.enumerated() {
            let cx: CGFloat = startX + regionW * CGFloat(idx) + regionW / 2

            let scoreColor = colorForScore(region.1)
            drawText(context: context, text: "\(region.1)", at: CGPoint(x: cx, y: barY - 2), fontSize: 26, weight: .black, color: scoreColor, centered: true, tracking: 0)
            drawText(context: context, text: region.0, at: CGPoint(x: cx, y: barY + 28), fontSize: 10, weight: .heavy, color: muted, centered: true, tracking: 2)
        }

        // Separator dots between regions
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(context.height))
        context.scaleBy(x: 1, y: -1)
        for idx in 0..<(regions.count - 1) {
            let dotX: CGFloat = startX + regionW * CGFloat(idx + 1)
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
            context.fillEllipse(in: CGRect(x: dotX - 1.5, y: size.height - barY - 5, width: 3, height: 3))
        }
        context.restoreGState()

        // Bottom accent line
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(context.height))
        context.scaleBy(x: 1, y: -1)
        context.setFillColor(CGColor(red: accentR, green: accentG, blue: accentB, alpha: 0.4))
        let lineW: CGFloat = 200
        context.fill(CGRect(x: (size.width - lineW) / 2, y: size.height - bottomY + 75, width: lineW, height: 2))
        context.restoreGState()
    }

    private func colorForScore(_ score: Int) -> CGColor {
        if score >= 87 {
            return CGColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1) // green
        } else if score >= 80 {
            return CGColor(red: 255/255, green: 217/255, blue: 61/255, alpha: 1) // yellow
        } else if score >= 70 {
            return CGColor(red: 45/255, green: 59/255, blue: 255/255, alpha: 1) // blue
        } else {
            return CGColor(red: 255/255, green: 82/255, blue: 82/255, alpha: 1) // red
        }
    }

    // MARK: - Text Drawing

    private func drawText(
        context: CGContext,
        text: String,
        at point: CGPoint,
        fontSize: CGFloat,
        weight: UIFont.Weight,
        color: CGColor,
        centered: Bool,
        tracking: CGFloat
    ) {
        let font = UIFont.systemFont(ofSize: fontSize, weight: weight)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(cgColor: color),
            .kern: tracking
        ]

        let nsString = text as NSString
        let textSize = nsString.size(withAttributes: attributes)

        let drawX: CGFloat = centered ? point.x - textSize.width / 2 : point.x

        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: CGFloat(context.height))
        context.scaleBy(x: 1, y: -1)

        nsString.draw(
            at: CGPoint(x: drawX, y: point.y),
            withAttributes: attributes
        )

        context.restoreGState()
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .clear
        player.play()

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
