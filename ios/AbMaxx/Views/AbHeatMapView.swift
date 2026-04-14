import SwiftUI

struct AbHeatMapView: View {
    let image: UIImage
    let scan: ScanResult?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedZone: SubscoreZone?

    private enum ViewMode: String, CaseIterable {
        case anatomy = "Heat Map"
        case photo = "Photo"
    }
    @State private var viewMode: ViewMode = .anatomy

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            if let scan {
                resultContent(scan)
            } else {
                noScanState
            }
        }
        .statusBarHidden()
        .sheet(item: $selectedZone) { zone in
            SubscoreZoneDetailSheet(zone: zone)
                .presentationDetents([.medium])
                .presentationBackground(Color(hex: "0D0D0D"))
                .presentationDragIndicator(.visible)
        }
    }

    private func resultContent(_ scan: ScanResult) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection(scan)
                anatomyDiagramSection(scan)
                legendSection
                subscoreBadgesSection(scan)
                strongestWeakestSection(scan)
                zoneCardsSection(scan)
                Color.clear.frame(height: 50)
            }
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                modePicker
                closeButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: viewMode)
    }

    private var modePicker: some View {
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

    private func headerSection(_ scan: ScanResult) -> some View {
        VStack(spacing: 0) {
            if viewMode == .photo {
                GeometryReader { geo in
                    let imageAspect = image.size.width / image.size.height
                    let viewW = geo.size.width
                    let viewH = viewW / imageAspect

                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                        LinearGradient(
                            colors: [.clear, .clear, Color.black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .allowsHitTesting(false)
                    }
                    .frame(width: viewW, height: viewH)
                }
                .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
            } else {
                Color.clear.frame(height: 52)
            }
        }
    }

    private func anatomyDiagramSection(_ scan: ScanResult) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "figure.mixed.cardio")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("MUSCLE ZONE MAP")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(1.2)
                Spacer()
                Text("Score \(scan.overallScore)")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(AppTheme.subscoreColor(for: scan.overallScore))
            }
            .padding(.horizontal, 16)
            .padding(.top, viewMode == .anatomy ? 8 : 20)

            AbsAnatomyHeatMapView(scan: scan)
                .frame(height: 420)
                .padding(.horizontal, 20)
        }
    }

    private var legendSection: some View {
        HStack(spacing: 16) {
            legendItem(color: AppTheme.success, label: "85+")
            legendItem(color: AppTheme.yellow, label: "75–84")
            legendItem(color: AppTheme.caution, label: "65–74")
            legendItem(color: AppTheme.destructive, label: "< 65")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 14, height: 14)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func subscoreBadgesSection(_ scan: ScanResult) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(scan.subscores, id: \.0) { name, score, icon in
                    subscoreBadge(name: name, score: score, icon: icon)
                }
            }
            .padding(.horizontal, 16)
        }
        .contentMargins(.horizontal, 0)
        .padding(.top, 16)
    }

    private func subscoreBadge(name: String, score: Int, icon: String) -> some View {
        let color = AppTheme.subscoreColor(for: score)
        return VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)

            Text("\(score)")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.white)

            Text(name.uppercased())
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundStyle(AppTheme.secondaryText)
                .tracking(0.3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 72, height: 82)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.25), lineWidth: 1)
        )
    }

    private func strongestWeakestSection(_ scan: ScanResult) -> some View {
        let sorted = scan.subscores.sorted { $0.1 > $1.1 }
        let strongest = sorted.first
        let weakest = sorted.last

        return HStack(spacing: 10) {
            if let s = strongest {
                tagCard(icon: "arrow.up.circle.fill", label: "STRONGEST", value: s.0, score: s.1, color: AppTheme.success)
            }
            if let w = weakest {
                tagCard(icon: "exclamationmark.triangle.fill", label: "WEAKEST", value: w.0, score: w.1, color: AppTheme.destructive)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func tagCard(icon: String, label: String, value: String, score: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(0.8)
            }
            HStack {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(score)")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(color)
            }
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

    private func zoneCardsSection(_ scan: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("ZONE BREAKDOWN")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(AppTheme.secondaryText)
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
                ForEach(scan.subscores, id: \.0) { name, score, icon in
                    Button {
                        selectedZone = SubscoreZone(name: name, score: score, icon: icon)
                    } label: {
                        zoneCard(name: name, score: score, icon: icon)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func zoneCard(name: String, score: Int, icon: String) -> some View {
        let color = AppTheme.subscoreColor(for: score)
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(score)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(gradeLabel(for: score))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(color)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(10)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }

    private func gradeLabel(for score: Int) -> String {
        if score >= 90 { return "Elite" }
        if score >= 80 { return "Advanced" }
        if score >= 70 { return "Good" }
        if score >= 60 { return "Developing" }
        return "Needs Work"
    }

    private var noScanState: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.mixed.cardio")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.primaryAccent.opacity(0.6))

            Text("No Scan Data")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text("Complete an ab scan first to view your heat map.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
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
}

struct SubscoreZone: Identifiable {
    let id = UUID()
    let name: String
    let score: Int
    let icon: String
}

struct SubscoreZoneDetailSheet: View {
    let zone: SubscoreZone

    private var color: Color {
        AppTheme.subscoreColor(for: zone.score)
    }

    private var gradeLabel: String {
        if zone.score >= 90 { return "ELITE" }
        if zone.score >= 80 { return "ADVANCED" }
        if zone.score >= 70 { return "GOOD" }
        if zone.score >= 60 { return "DEVELOPING" }
        return "NEEDS WORK"
    }

    private var descriptionText: String {
        ScanResult.scoreDescriptions[zone.name] ?? "Muscle zone measurement"
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: zone.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(color)

                Text(zone.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text(gradeLabel)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(color)
                    .tracking(1.5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: Double(zone.score) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(zone.score)")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(.white)
                    Text("/ 100")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)
                    Text("ABOUT THIS ZONE")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(AppTheme.secondaryText)
                        .tracking(1)
                }

                Text(descriptionText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 20)

            HStack(spacing: 8) {
                Image(systemName: zone.score >= 65 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                Text(zone.score >= 65 ? "This zone shows solid definition" : "This zone needs targeted work")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(color.opacity(0.08))
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}
