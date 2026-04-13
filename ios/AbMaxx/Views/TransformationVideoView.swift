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
            } else if let url = videoURL {
                videoPreviewSection(url: url)
            } else {
                createVideoButton
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

    private var createVideoButton: some View {
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

                    if isGenerating {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    }
                }
                .padding(.trailing, 14)

                VStack(alignment: .leading, spacing: 4) {
                    Text(isGenerating ? "Creating Video..." : "Create Transformation Video")
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

                if !isGenerating {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
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
        .disabled(isGenerating)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isGenerating)
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

            Button {
                saveToPhotos(url: url)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: savedToPhotos ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(savedToPhotos ? AppTheme.success : .white)

                    Text(savedToPhotos ? "Saved to Camera Roll" : "Save to Camera Roll")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
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
                .shadow(color: savedToPhotos ? .clear : AppTheme.primaryAccent.opacity(0.3), radius: 16, y: 6)
            }
            .disabled(savedToPhotos)
            .sensoryFeedback(.success, trigger: savedToPhotos)

            if let error = errorMessage {
                Text(error)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.destructive)
            }
        }
    }

    private func generateVideo() {
        guard hasEnoughScans else { return }
        isGenerating = true
        errorMessage = nil

        Task {
            let scans = scansWithPhotos
            let images: [(image: UIImage, week: Int, score: Int)] = scans.enumerated().compactMap { index, scan in
                guard let img = scan.loadImage() else { return nil }
                return (image: img, week: index + 1, score: scan.overallScore)
            }

            guard images.count >= 2 else {
                isGenerating = false
                errorMessage = "Could not load scan photos"
                return
            }

            let url = await createTransformationVideo(from: images)

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

    private func createTransformationVideo(from frames: [(image: UIImage, week: Int, score: Int)]) async -> URL? {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AbMaxx_Transformation_\(UUID().uuidString).mp4")

        let size = CGSize(width: 1080, height: 1920)
        let fps: Int32 = 30
        let holdFrames = 60
        let transitionFrames = 20

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
            guard let cgImage = frame.image.cgImage else { continue }

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
                    week: frame.week,
                    score: frame.score,
                    alpha: 1.0,
                    fadeProgress: f < 10 && i > 0 ? Double(f) / 10.0 : 1.0
                )

                adaptor.append(buffer, withPresentationTime: time)
                frameIndex += 1
            }

            if i < frames.count - 1 {
                guard let nextCG = frames[i + 1].image.cgImage else { continue }

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
                        fromWeek: frame.week,
                        fromScore: frame.score,
                        toWeek: frames[i + 1].week,
                        toScore: frames[i + 1].score,
                        progress: progress
                    )

                    adaptor.append(buffer, withPresentationTime: time)
                    frameIndex += 1
                }
            }
        }

        writerInput.markAsFinished()
        await writer.finishWriting()
        return writer.status == .completed ? outputURL : nil
    }

    private func renderFrame(
        to buffer: CVPixelBuffer,
        size: CGSize,
        image: CGImage,
        week: Int,
        score: Int,
        alpha: Double,
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

        let gradientSpace = CGColorSpaceCreateDeviceRGB()
        let topColors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.7),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        ] as CFArray
        if let topGrad = CGGradient(colorsSpace: gradientSpace, colors: topColors, locations: [0, 1]) {
            context.drawLinearGradient(
                topGrad,
                start: CGPoint(x: size.width / 2, y: size.height),
                end: CGPoint(x: size.width / 2, y: size.height - 340),
                options: []
            )
        }

        let bottomColors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.6),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        ] as CFArray
        if let botGrad = CGGradient(colorsSpace: gradientSpace, colors: bottomColors, locations: [0, 1]) {
            context.drawLinearGradient(
                botGrad,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: 260),
                options: []
            )
        }

        let whiteColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let mutedColor = CGColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 1)

        drawText(
            context: context,
            text: "ABMAXX",
            at: CGPoint(x: size.width / 2, y: size.height - 80),
            fontSize: 42,
            weight: .black,
            color: whiteColor,
            centered: true,
            tracking: 8
        )

        drawText(
            context: context,
            text: "WEEK \(week)",
            at: CGPoint(x: size.width / 2, y: size.height - 140),
            fontSize: 68,
            weight: .black,
            color: whiteColor,
            centered: true,
            tracking: 4
        )

        drawText(
            context: context,
            text: "\(score)",
            at: CGPoint(x: 60, y: 80),
            fontSize: 72,
            weight: .black,
            color: whiteColor,
            centered: false,
            tracking: 0
        )

        drawText(
            context: context,
            text: "SCORE",
            at: CGPoint(x: 64, y: 155),
            fontSize: 20,
            weight: .bold,
            color: mutedColor,
            centered: false,
            tracking: 4
        )
    }

    private func renderTransitionFrame(
        to buffer: CVPixelBuffer,
        size: CGSize,
        fromImage: CGImage,
        toImage: CGImage,
        fromWeek: Int,
        fromScore: Int,
        toWeek: Int,
        toScore: Int,
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

        drawImage(fromImage, 1.0 - progress)
        drawImage(toImage, progress)

        let gradientSpace = CGColorSpaceCreateDeviceRGB()
        let topColors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.7),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        ] as CFArray
        if let topGrad = CGGradient(colorsSpace: gradientSpace, colors: topColors, locations: [0, 1]) {
            context.drawLinearGradient(
                topGrad,
                start: CGPoint(x: size.width / 2, y: size.height),
                end: CGPoint(x: size.width / 2, y: size.height - 340),
                options: []
            )
        }

        let bottomColors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.6),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        ] as CFArray
        if let botGrad = CGGradient(colorsSpace: gradientSpace, colors: bottomColors, locations: [0, 1]) {
            context.drawLinearGradient(
                botGrad,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: 260),
                options: []
            )
        }

        let interpWeek = progress < 0.5 ? fromWeek : toWeek
        let interpScore = Int(Double(fromScore) * (1.0 - progress) + Double(toScore) * progress)

        let whiteColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let mutedColor = CGColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 1)

        drawText(
            context: context,
            text: "ABMAXX",
            at: CGPoint(x: size.width / 2, y: size.height - 80),
            fontSize: 42,
            weight: .black,
            color: whiteColor,
            centered: true,
            tracking: 8
        )

        drawText(
            context: context,
            text: "WEEK \(interpWeek)",
            at: CGPoint(x: size.width / 2, y: size.height - 140),
            fontSize: 68,
            weight: .black,
            color: whiteColor,
            centered: true,
            tracking: 4
        )

        drawText(
            context: context,
            text: "\(interpScore)",
            at: CGPoint(x: 60, y: 80),
            fontSize: 72,
            weight: .black,
            color: whiteColor,
            centered: false,
            tracking: 0
        )

        drawText(
            context: context,
            text: "SCORE",
            at: CGPoint(x: 64, y: 155),
            fontSize: 20,
            weight: .bold,
            color: mutedColor,
            centered: false,
            tracking: 4
        )
    }

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
