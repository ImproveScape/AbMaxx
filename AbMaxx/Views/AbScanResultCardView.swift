import SwiftUI

struct AbScanResultCardView: View {
    let scan: ScanResult
    let onSave: () -> Void
    let onShare: () -> Void
    let onDismiss: () -> Void
    @State private var appeared: Bool = false
    @State private var scoreCountUp: Int = 0

    private let cardBackground = AppTheme.cardSurface
    private let cardBorder = AppTheme.border
    private let greenAccent = AppTheme.success

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    resultCard
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    Button(action: onDismiss) {
                        Text("Continue")
                    }
                    .buttonStyle(GlowButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.spring(duration: 1.0)) { appeared = true }
            animateScore()
        }
    }

    private var resultCard: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primaryAccent.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.body.bold())
                            .foregroundStyle(AppTheme.primaryAccent)
                    }
                    Text("AbMaxx")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            userPhotoSection

            abmaxxScoreSection

            HStack(spacing: 12) {
                statBox(title: "BODY FAT", value: String(format: "%.1f%%", scan.estimatedBodyFat), isNumber: false)
                statBox(title: "ABS STRUCTURE", value: scan.absStructure.rawValue, isNumber: false)
            }
            .padding(.horizontal, 20)

            if let verdict = scan.coachVerdict, !verdict.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("COACH VERDICT")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.secondaryText)
                            .tracking(1)
                    }
                    Text(verdict)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.primaryAccent.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }

            subscoresGrid
                .padding(.horizontal, 20)

            Text("ABMAXX")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.muted.opacity(0.5))
                .tracking(4)
                .padding(.top, 4)

            actionButtons
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                colors: [cardBorder.opacity(0.8), cardBorder.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: AppTheme.primaryAccent.opacity(0.1), radius: 40)
        )
    }

    private var userPhotoSection: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 130, height: 130)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.cardSurfaceElevated,
                            AppTheme.cardSurface
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 120)

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.primaryAccent.opacity(0.6))
        }
        .shadow(color: AppTheme.primaryAccent.opacity(0.2), radius: 20)
    }

    private var abmaxxScoreSection: some View {
        VStack(spacing: 6) {
            Text("\(scoreCountUp)")
                .font(.system(size: 72, weight: .black, design: .default))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: scoreCountUp)

            Text("ABMAXX SCORE")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.muted)
                .tracking(3)
        }
    }

    private func statBox(title: String, value: String, isNumber: Bool) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.secondaryText)
                .tracking(1)

            if isNumber {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(greenAccent)
            } else {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(cardBorder.opacity(0.6), lineWidth: 1)
                )
        )
    }

    private var subscoresGrid: some View {
        let items: [(String, Int)] = [
            ("UPPER ABS", scan.definition),
            ("LOWER ABS", scan.thickness),
            ("OBLIQUES", scan.obliques),
            ("DEEP CORE", scan.aesthetic),
            ("SYMMETRY", scan.symmetry),
            ("V TAPER", scan.frame)
        ]

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                subscoreRow(label: item.0, score: item.1, delay: Double(index) * 0.1)
            }
        }
    }

    private func subscoreRow(label: String, score: Int, delay: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(1)
                Spacer()
                Text("\(score)")
                    .font(.subheadline.bold())
                    .foregroundStyle(greenAccent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.muted.opacity(0.3))
                        .frame(height: 5)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [greenAccent.opacity(0.8), greenAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: appeared ? geo.size.width * Double(score) / 100.0 : 0, height: 5)
                        .animation(.spring(duration: 1.0).delay(delay + 0.3), value: appeared)
                }
            }
            .frame(height: 5)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onSave) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.subheadline.bold())
                    Text("Save")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(cardBorder.opacity(0.6), lineWidth: 1)
                        )
                )
            }

            Button(action: onShare) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline.bold())
                    Text("Share")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(cardBorder.opacity(0.6), lineWidth: 1)
                        )
                )
            }
        }
    }

    private func animateScore() {
        let target = scan.overallScore
        let steps = 30
        let interval = 1.0 / Double(steps)
        for i in 0...steps {
            let value = Int(Double(target) * Double(i) / Double(steps))
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                scoreCountUp = value
            }
        }
    }
}
