import SwiftUI
import AVFoundation
import Photos

struct ProgressPhotosDetailView: View {
    @Bindable var vm: AppViewModel
    @State private var selectedPhoto: ScanResult?
    @State private var isGeneratingVideo: Bool = false
    @State private var videoGenerated: Bool = false
    @State private var videoURL: URL?
    @State private var showShareSheet: Bool = false
    @State private var generationProgress: Double = 0
    @State private var showScanSheet: Bool = false
    @State private var compareSliderPosition: CGFloat = 0.5

    private let goldAccent = Color(red: 0.85, green: 0.65, blue: 0.2)

    private var scansWithPhotos: [ScanResult] {
        vm.scanResults.filter { $0.hasPhoto }.sorted { $0.date < $1.date }
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            if scansWithPhotos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        summaryHeader
                        transformationCompareSection
                        transformationVideoButton
                        photoTimeline
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Progress Photos")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedPhoto) { scan in
            PhotoDetailSheet(scan: scan, dayIndex: dayIndex(for: scan))
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = videoURL {
                ShareSheet(items: [url])
            }
        }
        .fullScreenCover(isPresented: $showScanSheet) {
            ScanView(vm: vm)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.muted)
            Text("No Progress Photos Yet")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Complete your first scan to start\ntracking your transformation")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("\(scansWithPhotos.count)")
                    .font(.system(size: 28, weight: .black, design: .default))
                    .foregroundStyle(.white)
                Text("Photos")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(AppTheme.border.opacity(0.5))
                .frame(width: 1, height: 36)

            VStack(spacing: 6) {
                let first = scansWithPhotos.first?.overallScore ?? 0
                let last = scansWithPhotos.last?.overallScore ?? 0
                let diff = last - first
                Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                    .font(.system(size: 28, weight: .black, design: .default))
                    .foregroundStyle(diff >= 0 ? AppTheme.success : AppTheme.destructive)
                Text("Score Change")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(AppTheme.border.opacity(0.5))
                .frame(width: 1, height: 36)

            VStack(spacing: 6) {
                if let first = scansWithPhotos.first?.date, let last = scansWithPhotos.last?.date {
                    let days = max(Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0, 0)
                    Text("\(days)")
                        .font(.system(size: 28, weight: .black, design: .default))
                        .foregroundStyle(goldAccent)
                } else {
                    Text("0")
                        .font(.system(size: 28, weight: .black, design: .default))
                        .foregroundStyle(goldAccent)
                }
                Text("Days")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
        )
    }

    private var transformationVideoButton: some View {
        Button {
            generateTransformationVideo()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            isGeneratingVideo
                                ? LinearGradient(colors: [AppTheme.cardSurfaceElevated], startPoint: .top, endPoint: .bottom)
                                : AppTheme.accentGradient
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: isGeneratingVideo ? .clear : AppTheme.primaryAccent.opacity(0.4), radius: 12)

                    if isGeneratingVideo {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: videoGenerated ? "checkmark.circle.fill" : "film.stack")
                            .font(.body.bold())
                            .foregroundStyle(videoGenerated ? AppTheme.success : .white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(videoGenerated ? "Video Ready" : "Create Transformation Video")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(isGeneratingVideo ? "Generating..." : videoGenerated ? "Tap to share your transformation" : "\(scansWithPhotos.count) photos · Timelapse video")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                if !isGeneratingVideo {
                    Image(systemName: videoGenerated ? "square.and.arrow.up" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
            }
            .padding(16)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        videoGenerated ? AppTheme.success.opacity(0.4) : AppTheme.primaryAccent.opacity(0.4),
                        lineWidth: 1
                    )
            )
        }
        .disabled(isGeneratingVideo || scansWithPhotos.count < 2)
        .opacity(scansWithPhotos.count < 2 ? 0.5 : 1)
    }

    private var photoTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Timeline")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(scansWithPhotos.count) scans")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(Array(scansWithPhotos.enumerated()), id: \.element.id) { index, scan in
                    Button {
                        selectedPhoto = scan
                    } label: {
                        timelineCell(scan: scan, index: index)
                    }
                }

                if !hasTodaysPhoto {
                    Button {
                        showScanSheet = true
                    } label: {
                        todayPlaceholderCell
                    }
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
        )
    }

    private var hasTodaysPhoto: Bool {
        let calendar = Calendar.current
        return scansWithPhotos.contains { calendar.isDateInToday($0.date) }
    }

    private var todayPlaceholderCell: some View {
        VStack(spacing: 0) {
            AppTheme.cardSurface
                .aspectRatio(3/4, contentMode: .fit)
                .overlay {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryAccent.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(AppTheme.primaryAccent)
                        }
                        Text("Add Today's Scan")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .clipShape(.rect(cornerRadius: 14))
                .overlay(alignment: .bottomLeading) {
                    Text("Day \(scansWithPhotos.count + 1)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AppTheme.primaryAccent.opacity(0.85)))
                        .padding(8)
                }

            VStack(spacing: 4) {
                Text(Date.now, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Score: --")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.vertical, 10)
        }
        .background(AppTheme.cardSurfaceElevated)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.primaryAccent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
    }

    private func timelineCell(scan: ScanResult, index: Int) -> some View {
        VStack(spacing: 0) {
            if let uiImage = scan.loadImage() {
                AppTheme.cardSurface
                    .aspectRatio(3/4, contentMode: .fit)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(alignment: .topTrailing) {
                        Text("\(scan.overallScore)")
                            .font(.system(.caption2, design: .default, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AppTheme.scoreColor(for: scan.overallScore).opacity(0.9)))
                            .padding(8)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text("Day \(index + 1)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AppTheme.primaryAccent.opacity(0.85)))
                            .padding(8)
                    }
            }

            VStack(spacing: 4) {
                Text(scan.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Score: \(scan.overallScore)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.scoreColor(for: scan.overallScore))
            }
            .padding(.vertical, 10)
        }
        .background(AppTheme.cardSurfaceElevated)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
    }

    private var firstScanWithPhoto: ScanResult? {
        scansWithPhotos.first
    }

    private var latestScanWithPhoto: ScanResult? {
        scansWithPhotos.last
    }

    private var hasBeforeAfterPhotos: Bool {
        guard let first = firstScanWithPhoto, let latest = latestScanWithPhoto else { return false }
        return first.id != latest.id
    }

    private var transformationCompareSection: some View {
        Group {
            if hasBeforeAfterPhotos,
               let firstScan = firstScanWithPhoto,
               let latestScan = latestScanWithPhoto {
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.stack")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.secondaryAccent)
                        Text("Your Transformation")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                        Spacer()
                        let scoreDiff = latestScan.overallScore - firstScan.overallScore
                        if scoreDiff != 0 {
                            HStack(spacing: 3) {
                                Image(systemName: scoreDiff > 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption2.bold())
                                Text(scoreDiff > 0 ? "+\(scoreDiff)" : "\(scoreDiff)")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(scoreDiff > 0 ? AppTheme.success : AppTheme.destructive)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background((scoreDiff > 0 ? AppTheme.success : AppTheme.destructive).opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    GeometryReader { geo in
                        let w = geo.size.width
                        let h: CGFloat = 380

                        ZStack {
                            if let beforeImage = firstScan.loadImage() {
                                AppTheme.cardSurface
                                    .overlay {
                                        Image(uiImage: beforeImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .allowsHitTesting(false)
                                    }
                                    .clipShape(.rect(cornerRadius: 16))
                            }

                            if let afterImage = latestScan.loadImage() {
                                AppTheme.cardSurface
                                    .overlay {
                                        Image(uiImage: afterImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .allowsHitTesting(false)
                                    }
                                    .clipShape(.rect(cornerRadius: 16))
                                    .mask(
                                        HStack(spacing: 0) {
                                            Color.clear.frame(width: w * compareSliderPosition)
                                            Color.black
                                        }
                                    )
                            }

                            Rectangle()
                                .fill(.white)
                                .frame(width: 3)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                                .position(x: w * compareSliderPosition, y: h / 2)

                            Circle()
                                .fill(.white)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "arrow.left.and.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.black)
                                }
                                .shadow(color: .black.opacity(0.4), radius: 10)
                                .position(x: w * compareSliderPosition, y: h / 2)

                            VStack {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("START")
                                            .font(.system(size: 10, weight: .black))
                                            .tracking(1)
                                        Text("\(firstScan.overallScore)")
                                            .font(.system(size: 18, weight: .black, design: .default))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.black.opacity(0.6))
                                    .clipShape(.rect(cornerRadius: 8))
                                    .padding(12)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("CURRENT")
                                            .font(.system(size: 10, weight: .black))
                                            .tracking(1)
                                        Text("\(latestScan.overallScore)")
                                            .font(.system(size: 18, weight: .black, design: .default))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.black.opacity(0.6))
                                    .clipShape(.rect(cornerRadius: 8))
                                    .padding(12)
                                }
                                Spacer()
                                HStack {
                                    Text(firstScan.date, format: .dateTime.month(.abbreviated).day().year())
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.black.opacity(0.5))
                                        .clipShape(Capsule())
                                        .padding(12)
                                    Spacer()
                                    Text(latestScan.date, format: .dateTime.month(.abbreviated).day().year())
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.black.opacity(0.5))
                                        .clipShape(Capsule())
                                        .padding(12)
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .frame(height: h)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    compareSliderPosition = max(0.05, min(0.95, value.location.x / w))
                                }
                        )
                    }
                    .frame(height: 380)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 18)
                }
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
                )
            }
        }
    }

    private func dayIndex(for scan: ScanResult) -> Int {
        (scansWithPhotos.firstIndex(where: { $0.id == scan.id }) ?? 0) + 1
    }

    private func generateTransformationVideo() {
        guard scansWithPhotos.count >= 2 else { return }

        if videoGenerated, let _ = videoURL {
            showShareSheet = true
            return
        }

        isGeneratingVideo = true
        generationProgress = 0

        Task {
            let images: [UIImage] = scansWithPhotos.compactMap { scan in
                scan.loadImage()
            }

            guard images.count >= 2 else {
                isGeneratingVideo = false
                return
            }

            let url = await createVideo(from: images)
            videoURL = url
            videoGenerated = url != nil
            isGeneratingVideo = false

            if url != nil {
                showShareSheet = true
            }
        }
    }

    private func createVideo(from images: [UIImage]) async -> URL? {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("AbMaxx_Transformation_\(UUID().uuidString).mp4")

        let size = CGSize(width: 1080, height: 1440)
        let fps: Int32 = 30
        let _ = CMTime(value: 1, timescale: fps)
        let durationPerImage = 1.5
        let framesPerImage = Int(durationPerImage * Double(fps))

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

        for image in images {
            guard let cgImage = image.cgImage else { continue }

            for _ in 0..<framesPerImage {
                while !writerInput.isReadyForMoreMediaData {
                    try? await Task.sleep(for: .milliseconds(10))
                }

                let presentationTime = CMTime(value: CMTimeValue(frameIndex), timescale: fps)

                guard let pool = adaptor.pixelBufferPool else { continue }
                var pixelBuffer: CVPixelBuffer?
                CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
                guard let buffer = pixelBuffer else { continue }

                CVPixelBufferLockBaseAddress(buffer, [])
                let context = CGContext(
                    data: CVPixelBufferGetBaseAddress(buffer),
                    width: Int(size.width),
                    height: Int(size.height),
                    bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                )
                context?.interpolationQuality = .high

                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                let scale = max(size.width / imageSize.width, size.height / imageSize.height)
                let scaledWidth = imageSize.width * scale
                let scaledHeight = imageSize.height * scale
                let x = (size.width - scaledWidth) / 2
                let y = (size.height - scaledHeight) / 2

                context?.draw(cgImage, in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
                CVPixelBufferUnlockBaseAddress(buffer, [])

                adaptor.append(buffer, withPresentationTime: presentationTime)
                frameIndex += 1
            }
        }

        writerInput.markAsFinished()
        await writer.finishWriting()

        return writer.status == .completed ? outputURL : nil
    }
}

struct PhotoDetailSheet: View {
    let scan: ScanResult
    let dayIndex: Int

    private let goldAccent = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let uiImage = scan.loadImage() {
                            AppTheme.cardSurface
                                .aspectRatio(3/4, contentMode: .fit)
                                .overlay {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .allowsHitTesting(false)
                                }
                                .clipShape(.rect(cornerRadius: 20))
                        }

                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day \(dayIndex)")
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                    Text(scan.date, format: .dateTime.month(.wide).day().year())
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                Spacer()
                                VStack(spacing: 2) {
                                    Text("\(scan.overallScore)")
                                        .font(.system(size: 36, weight: .black, design: .default))
                                        .foregroundStyle(goldAccent)
                                    Text("AbMaxx Score")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(AppTheme.muted)
                                }
                            }

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 10) {
                                ForEach(scan.subscores, id: \.0) { name, score, icon in
                                    VStack(spacing: 6) {
                                        Image(systemName: icon)
                                            .font(.caption.bold())
                                            .foregroundStyle(AppTheme.scoreColor(for: score))
                                        Text("\(score)")
                                            .font(.system(.subheadline, design: .default, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text(name)
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.cardSurfaceElevated)
                                    .clipShape(.rect(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(18)
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Day \(dayIndex)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {}
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
