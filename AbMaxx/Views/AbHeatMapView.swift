import SwiftUI

struct AbHeatMapView: View {
    let image: UIImage
    let scan: ScanResult?
    @Environment(\.dismiss) private var dismiss
    @State private var heatMapData: HeatMapAnalysis?
    @State private var aiEditedImage: UIImage?
    @State private var isAnalyzing: Bool = true
    @State private var isGeneratingImage: Bool = false
    @State private var analysisError: Bool = false
    @State private var showZoneDetail: HeatMapZone?
    @State private var showOverlay: Bool = true
    @State private var pulsePhase: Bool = false
    @State private var scanLineOffset: CGFloat = 0
    @State private var statusText: String = "Mapping muscle zones..."

    private enum ViewMode: String, CaseIterable {
        case aiHeatMap = "AI Scan"
        case overlay = "Overlay"
        case original = "Original"
    }
    @State private var viewMode: ViewMode = .aiHeatMap

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isAnalyzing || isGeneratingImage {
                analyzingState
            } else if let data = heatMapData {
                resultState(data)
            } else if analysisError {
                errorState
            }
        }
        .statusBarHidden()
        .task {
            await runAnalysis()
        }
        .sheet(item: $showZoneDetail) { zone in
            ZoneDetailSheet(zone: zone)
                .presentationDetents([.medium])
                .presentationBackground(AppTheme.background)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Analyzing

    private var analyzingState: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
                .blur(radius: 8)
                .overlay(Color.black.opacity(0.65))

            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.primaryAccent.opacity(0),
                                AppTheme.primaryAccent.opacity(0.4),
                                AppTheme.primaryAccent.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 3)
                    .offset(y: scanLineOffset)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            scanLineOffset = geo.size.height
                        }
                    }
            }
            .allowsHitTesting(false)

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .strokeBorder(AppTheme.primaryAccent.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulsePhase ? 1.3 : 1.0)
                        .opacity(pulsePhase ? 0 : 0.8)

                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(0.15))
                        .frame(width: 70, height: 70)

                    Image(systemName: isGeneratingImage ? "paintbrush.fill" : "viewfinder.rectangular")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                        pulsePhase = true
                    }
                }

                VStack(spacing: 8) {
                    Text(isGeneratingImage ? "Generating Heat Map" : "Analyzing Physique")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text(statusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }

                if isGeneratingImage {
                    HStack(spacing: 16) {
                        scanningTag("Rendering zones")
                        scanningTag("Applying colors")
                        scanningTag("Contouring")
                    }
                } else {
                    HStack(spacing: 16) {
                        scanningTag("Fiber density")
                        scanningTag("Separation depth")
                        scanningTag("Fat coverage")
                    }
                }

                if isGeneratingImage {
                    VStack(spacing: 6) {
                        ProgressView()
                            .tint(AppTheme.primaryAccent)
                        Text("This takes ~30 seconds")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private func scanningTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.primaryAccent.opacity(0.8))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.primaryAccent.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Result

    private func resultState(_ data: HeatMapAnalysis) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                heatMapImageSection(data)
                diagnosticBadgesSection(data)
                technicalBreakdownSection(data)
                zoneGridSection(data)
                technicalNotesSection(data)
                Color.clear.frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                viewModePicker
                closeButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: viewMode)
    }

    private var viewModePicker: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.rawValue) { mode in
                let isActive = viewMode == mode
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isActive ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isActive ? AppTheme.primaryAccent.opacity(0.6) : Color.clear)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private func heatMapImageSection(_ data: HeatMapAnalysis) -> some View {
        let displayImage: UIImage = {
            switch viewMode {
            case .aiHeatMap:
                return aiEditedImage ?? image
            case .overlay, .original:
                return image
            }
        }()

        return GeometryReader { geo in
            let imageAspect = displayImage.size.width / displayImage.size.height
            let viewW = geo.size.width
            let viewH = viewW / imageAspect

            ZStack {
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                if viewMode == .overlay {
                    HeatMapOverlayView(
                        zones: data.zones,
                        imageSize: CGSize(width: viewW, height: viewH)
                    )
                    .transition(.opacity)
                }

                if viewMode == .aiHeatMap && aiEditedImage != nil {
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(AppTheme.primaryAccent)
                                    .frame(width: 6, height: 6)
                                Text("AI DIAGNOSTIC SCAN")
                                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(AppTheme.primaryAccent)
                                    .tracking(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.6), in: Capsule())
                            Spacer()
                        }
                        .padding(12)
                    }
                    .allowsHitTesting(false)
                }

                LinearGradient(
                    colors: [.clear, .clear, .clear, Color.black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .frame(width: viewW, height: viewH)
        }
        .aspectRatio((aiEditedImage ?? image).size.width / (aiEditedImage ?? image).size.height, contentMode: .fit)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 6) {
                Text("HEAT MAP ANALYSIS")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(1.5)

                HStack(spacing: 12) {
                    legendDot(color: Color(red: 0, green: 1, blue: 0.4), label: "Defined")
                    legendDot(color: Color(red: 1, green: 0.85, blue: 0), label: "Moderate")
                    legendDot(color: Color(red: 1, green: 0.15, blue: 0.15), label: "Needs Work")
                }
            }
            .padding(16)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Diagnostic Badges

    private func diagnosticBadgesSection(_ data: HeatMapAnalysis) -> some View {
        let avgScore = data.zones.isEmpty ? 0 : data.zones.map(\.definitionScore).reduce(0, +) / data.zones.count
        let definedCount = data.zones.filter { !$0.needsWork }.count
        let needsWorkCount = data.zones.filter { $0.needsWork }.count

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                diagnosticBadge(
                    icon: "gauge.open.with.lines.needle.33percent",
                    value: "\(avgScore)",
                    label: "AVG SCORE",
                    color: zoneScoreColor(avgScore)
                )
                diagnosticBadge(
                    icon: "checkmark.seal.fill",
                    value: "\(definedCount)",
                    label: "DEFINED",
                    color: AppTheme.success
                )
                diagnosticBadge(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(needsWorkCount)",
                    label: "NEED WORK",
                    color: AppTheme.destructive
                )
                diagnosticBadge(
                    icon: "square.grid.3x3.fill",
                    value: "\(data.zones.count)",
                    label: "ZONES",
                    color: AppTheme.primaryAccent
                )
            }
            .padding(.horizontal, 16)
        }
        .contentMargins(.horizontal, 0)
        .padding(.top, 16)
    }

    private func diagnosticBadge(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.5)
        }
        .frame(width: 78, height: 88)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Technical Breakdown

    private func technicalBreakdownSection(_ data: HeatMapAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("TECHNICAL BREAKDOWN")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(1.2)
            }
            .padding(.top, 24)

            Text(data.overallAssessment)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(5)

            HStack(spacing: 10) {
                strengthTag(
                    icon: "arrow.up.circle.fill",
                    label: "STRONGEST",
                    value: data.strongestArea,
                    color: AppTheme.success
                )
                strengthTag(
                    icon: "exclamationmark.triangle.fill",
                    label: "WEAKEST",
                    value: data.weakestArea,
                    color: AppTheme.destructive
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private func strengthTag(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(0.8)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Zone Grid

    private func zoneGridSection(_ data: HeatMapAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("ZONE-BY-ZONE")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(1.2)
                Spacer()
                Text("Tap for details")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent.opacity(0.6))
            }
            .padding(.top, 20)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(data.zones) { zone in
                    Button {
                        showZoneDetail = zone
                    } label: {
                        zoneCard(zone)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func zoneCard(_ zone: HeatMapZone) -> some View {
        let color = zoneScoreColor(zone.definitionScore)
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(zone.definitionScore)")
                    .font(.system(size: 14, weight: .black, design: .default))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(zone.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(zone.needsWork ? "Needs work" : "Defined")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(zone.needsWork ? AppTheme.destructive : AppTheme.success)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(10)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }

    private func zoneScoreColor(_ score: Int) -> Color {
        if score >= 80 { return Color(red: 0.0, green: 1.0, blue: 0.4) }
        if score >= 65 { return AppTheme.success }
        if score >= 50 { return AppTheme.warning }
        if score >= 35 { return AppTheme.orange }
        return AppTheme.destructive
    }

    // MARK: - Technical Notes

    private func technicalNotesSection(_ data: HeatMapAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("CLINICAL NOTES")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(1.2)
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(data.technicalNotes.enumerated()), id: \.offset) { index, note in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(AppTheme.primaryAccent)
                            .frame(width: 20)
                        Text(note)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)

                    if index < data.technicalNotes.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.04))
                            .frame(height: 1)
                            .padding(.leading, 44)
                    }
                }
            }
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppTheme.border, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Error

    private var errorState: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.destructive.opacity(0.6))

            Text("Analysis Failed")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text("Could not generate heat map. Try again with a clearer photo.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button { dismiss() } label: {
                Text("Close")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryAccent)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Logic

    private func runAnalysis() async {
        statusText = "Mapping muscle zones..."
        let result = await HeatMapService.shared.analyzeForHeatMap(image)

        guard let result else {
            withAnimation {
                analysisError = true
                isAnalyzing = false
            }
            return
        }

        heatMapData = result
        statusText = "Rendering AI heat map on your photo..."
        isGeneratingImage = true
        isAnalyzing = false

        let editedImage = await HeatMapService.shared.generateHeatMapImage(image, analysis: result)
        aiEditedImage = editedImage

        withAnimation(.easeOut(duration: 0.5)) {
            isGeneratingImage = false
        }
    }
}

// MARK: - Zone Detail Sheet

struct ZoneDetailSheet: View {
    let zone: HeatMapZone

    private var scoreColor: Color {
        if zone.definitionScore >= 80 { return Color(red: 0.0, green: 1.0, blue: 0.4) }
        if zone.definitionScore >= 65 { return AppTheme.success }
        if zone.definitionScore >= 50 { return AppTheme.warning }
        if zone.definitionScore >= 35 { return AppTheme.orange }
        return AppTheme.destructive
    }

    private var gradeLabel: String {
        if zone.definitionScore >= 90 { return "ELITE" }
        if zone.definitionScore >= 75 { return "ADVANCED" }
        if zone.definitionScore >= 60 { return "DEVELOPING" }
        if zone.definitionScore >= 45 { return "EMERGING" }
        return "NEEDS FOCUS"
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(zone.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text(gradeLabel)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(scoreColor)
                    .tracking(1.5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(scoreColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: Double(zone.definitionScore) / 100.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(zone.definitionScore)")
                        .font(.system(size: 36, weight: .black, design: .default))
                        .foregroundStyle(.white)
                    Text("/ 100")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)
                    Text("AI OBSERVATION")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(AppTheme.muted)
                        .tracking(1)
                }

                Text(zone.note)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppTheme.border, lineWidth: 1)
            )
            .padding(.horizontal, 20)

            HStack(spacing: 8) {
                Image(systemName: zone.needsWork ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(zone.needsWork ? AppTheme.destructive : AppTheme.success)
                Text(zone.needsWork ? "This zone needs targeted work to improve definition" : "This zone shows strong muscle definition")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(zone.needsWork ? AppTheme.destructive : AppTheme.success)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background((zone.needsWork ? AppTheme.destructive : AppTheme.success).opacity(0.08))
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}
