import SwiftUI

struct ScanPrepView: View {
    let username: String
    let onContinue: () -> Void

    @State private var showTitle: Bool = false
    @State private var showAbsModel: Bool = false
    @State private var activeSegment: Int = -1
    @State private var showFeatures: Bool = false
    @State private var showButton: Bool = false
    @State private var pulseGlow: Bool = false
    @State private var scanLineY: CGFloat = -1.0
    @State private var scanActive: Bool = false
    @State private var segmentsRevealed: Set<Int> = []
    @State private var ringRotation: Double = 0
    @State private var hapticTrigger: Int = 0

    private let segments: [(name: String, icon: String)] = [
        ("Upper Abs", "arrow.up.circle.fill"),
        ("Mid Core", "circle.grid.cross.fill"),
        ("Lower Abs", "arrow.down.circle.fill"),
        ("Left Obliques", "arrow.left.circle.fill"),
        ("Right Obliques", "arrow.right.circle.fill"),
        ("Deep Core", "target"),
    ]

    var body: some View {
        ZStack {
            backgroundEffects

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                if showTitle {
                    titleSection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer().frame(height: 28)

                if showAbsModel {
                    absVisualization
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                Spacer().frame(height: 32)

                if showFeatures {
                    featureCards
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                if showButton {
                    scanButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 50)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
        .onAppear { startSequence() }
    }

    private var backgroundEffects: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primaryAccent.opacity(0.06))
                .frame(width: 500, height: 500)
                .blur(radius: 160)
                .offset(y: -100)
                .scaleEffect(pulseGlow ? 1.12 : 0.92)

            Circle()
                .fill(AppTheme.primaryAccent.opacity(0.03))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -60, y: 280)

            Circle()
                .fill(Color(red: 0.1, green: 0.3, blue: 1.0).opacity(0.04))
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: 100, y: -250)
        }
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseGlow)
    }

    private var titleSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("AI ABS SCAN")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(AppTheme.primaryAccent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(AppTheme.primaryAccent.opacity(0.1))
            .clipShape(.capsule)

            Text("We Need to Map\nYour Core")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Our AI scan maps all 6 zones of your core —\nengineered for your abs, and yours only.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)
        }
    }

    private var absVisualization: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.primaryAccent.opacity(0.06), lineWidth: 1)
                .frame(width: 230, height: 230)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .stroke(AppTheme.primaryAccent.opacity(0.03), lineWidth: 1)
                .frame(width: 270, height: 270)
                .rotationEffect(.degrees(-ringRotation * 0.7))

            absGrid
                .overlay(scanLineEffect)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            ForEach(0..<6, id: \.self) { idx in
                if segmentsRevealed.contains(idx) {
                    segmentIndicator(idx: idx)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
            }
        }
        .frame(height: 220)
    }

    private func absCellFill(isActive: Bool, isScanning: Bool) -> Color {
        if isActive { return AppTheme.primaryAccent.opacity(0.25) }
        if isScanning { return AppTheme.primaryAccent.opacity(0.12) }
        return Color.white.opacity(0.03)
    }

    private func absCellBorder(isActive: Bool, isScanning: Bool) -> Color {
        if isActive { return AppTheme.primaryAccent.opacity(0.6) }
        if isScanning { return AppTheme.primaryAccent.opacity(0.3) }
        return Color.white.opacity(0.05)
    }

    @ViewBuilder
    private func absCell(idx: Int) -> some View {
        let isActive = segmentsRevealed.contains(idx)
        let isScanning = activeSegment == idx

        RoundedRectangle(cornerRadius: 10)
            .fill(absCellFill(isActive: isActive, isScanning: isScanning))
            .frame(width: 60, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(absCellBorder(isActive: isActive, isScanning: isScanning), lineWidth: 1.5)
            )
            .overlay {
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .shadow(color: isActive ? AppTheme.primaryAccent.opacity(0.35) : .clear, radius: 12)
            .scaleEffect(isScanning ? 1.08 : 1.0)
            .animation(.spring(duration: 0.4, bounce: 0.3), value: isActive)
            .animation(.spring(duration: 0.3), value: isScanning)
    }

    private var absGrid: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) { absCell(idx: 0); absCell(idx: 1) }
            HStack(spacing: 3) { absCell(idx: 2); absCell(idx: 3) }
            HStack(spacing: 3) { absCell(idx: 4); absCell(idx: 5) }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
                )
        )
    }

    private var scanLineEffect: some View {
        VStack {
            if scanActive {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.primaryAccent.opacity(0),
                                AppTheme.primaryAccent.opacity(0.4),
                                AppTheme.primaryAccent.opacity(0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.6), radius: 6)
                    .offset(y: scanLineY * 160)
            }
        }
    }

    private func segmentIndicator(idx: Int) -> some View {
        let positions: [CGSize] = [
            CGSize(width: -80, height: -70),
            CGSize(width: 80, height: -70),
            CGSize(width: -80, height: 0),
            CGSize(width: 80, height: 0),
            CGSize(width: -80, height: 70),
            CGSize(width: 80, height: 70),
        ]
        let pos = idx < positions.count ? positions[idx] : .zero

        return HStack(spacing: 4) {
            Circle()
                .fill(AppTheme.primaryAccent)
                .frame(width: 5, height: 5)
            Text(segments[idx].name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .offset(pos)
    }

    private var featureCards: some View {
        VStack(spacing: 10) {
            featureRow(
                icon: "target",
                title: "Precision Targeting",
                subtitle: "Identifies weak zones generic programs miss"
            )
            featureRow(
                icon: "waveform.path.ecg",
                title: "Custom Program Built",
                subtitle: "Every exercise matched to your weak points"
            )
            featureRow(
                icon: "bolt.fill",
                title: "Faster Results",
                subtitle: "Train what matters — skip what doesn't"
            )
        }
        .padding(.horizontal, 24)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
                )
        )
    }

    private var scanButton: some View {
        Button(action: {
            hapticTrigger += 1
            onContinue()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 16, weight: .bold))
                    .symbolEffect(.pulse, options: .repeating)
                Text("Scan My Abs")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppTheme.primaryAccent)
            .clipShape(.capsule)
            .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 28, y: 8)
        }
        .padding(.horizontal, 24)
    }

    private func startSequence() {
        pulseGlow = true

        Task {
            withAnimation(.spring(duration: 0.6)) { showTitle = true }
            try? await Task.sleep(for: .milliseconds(400))

            withAnimation(.spring(duration: 0.7, bounce: 0.2)) { showAbsModel = true }
            try? await Task.sleep(for: .milliseconds(300))

            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }

            scanActive = true

            for i in 0..<6 {
                activeSegment = i
                hapticTrigger += 1

                withAnimation(.easeInOut(duration: 0.8)) {
                    scanLineY = CGFloat(i) / 5.0
                }

                try? await Task.sleep(for: .milliseconds(450))

                let _ = withAnimation(.spring(duration: 0.4, bounce: 0.35)) {
                    segmentsRevealed.insert(i)
                }

                try? await Task.sleep(for: .milliseconds(200))
            }

            activeSegment = -1
            scanActive = false

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.5)) { showFeatures = true }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.5, bounce: 0.25)) { showButton = true }
        }
    }
}
