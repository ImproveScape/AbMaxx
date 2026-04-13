import SwiftUI

struct BodyFatTrackerView: View {
    @Bindable var vm: AppViewModel
    @State private var animateChart: Bool = false

    private var bodyFatEntries: [BodyFatEntry] {
        vm.scanResults.sorted { $0.date < $1.date }.map { scan in
            BodyFatEntry(
                date: scan.date,
                estimatedBodyFat: BodyFatEntry.estimateFromScan(
                    overallScore: scan.overallScore,
                    gender: vm.profile.gender,
                    bodyFatCategory: vm.profile.bodyFatCategory
                )
            )
        }
    }

    private var currentEstimate: Double {
        bodyFatEntries.last?.estimatedBodyFat ?? BodyFatEntry.estimateFromScan(
            overallScore: 55,
            gender: vm.profile.gender,
            bodyFatCategory: vm.profile.bodyFatCategory
        )
    }

    private var startEstimate: Double {
        bodyFatEntries.first?.estimatedBodyFat ?? currentEstimate
    }

    private var targetBF: Double {
        switch vm.profile.goal {
        case .sixPack: return vm.profile.gender == .male ? 10 : 16
        case .visibleAbs: return vm.profile.gender == .male ? 13 : 19
        case .loseBellyFat: return vm.profile.gender == .male ? 15 : 21
        case .coreStrength: return vm.profile.gender == .male ? 15 : 21
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        currentEstimateCard
                        progressCard
                        chartCard
                        infoCard
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Body Fat %")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    withAnimation(.spring(duration: 0.8)) { animateChart = true }
                }
            }
        }
    }

    private var currentEstimateCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(String(format: "%.1f%%", currentEstimate))
                    .font(.system(size: 40, weight: .black, design: .default))
                    .foregroundStyle(.white)
                Text("Current Est.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(AppTheme.border.opacity(0.5))
                .frame(width: 1, height: 50)

            VStack(spacing: 6) {
                Text(String(format: "%.1f%%", targetBF))
                    .font(.system(size: 40, weight: .black, design: .default))
                    .foregroundStyle(AppTheme.success)
                Text("Target")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 24)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
        )
    }

    private var progressCard: some View {
        let totalDrop = startEstimate - targetBF
        let currentDrop = startEstimate - currentEstimate
        let progress = totalDrop > 0 ? min(currentDrop / totalDrop, 1.0) : 0

        return VStack(spacing: 14) {
            HStack {
                Text("Progress to Target")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.primaryAccent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.border.opacity(0.3))
                    Capsule()
                        .fill(AppTheme.accentGradient)
                        .frame(width: max(geo.size.width * progress, 6))
                }
            }
            .frame(height: 10)

            HStack {
                Text(String(format: "Started: %.1f%%", startEstimate))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
                Spacer()
                let change = currentEstimate - startEstimate
                Text(String(format: "%+.1f%%", change))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(change <= 0 ? AppTheme.success : AppTheme.destructive)
            }
        }
        .cardStyle(highlighted: true)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Trend Over Time")
                .font(.headline.bold())
                .foregroundStyle(.white)

            if bodyFatEntries.count > 1 {
                bodyFatChart
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.title2)
                        .foregroundStyle(AppTheme.muted)
                    Text("More scans needed for trend")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
            }
        }
        .cardStyle()
    }

    private var bodyFatChart: some View {
        let entries = bodyFatEntries
        let values = entries.map(\.estimatedBodyFat)
        let maxVal = (values.max() ?? 30) + 2
        let minVal = max((values.min() ?? 10) - 2, 0)
        let range = max(maxVal - minVal, 5)

        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let chartLeft: CGFloat = 36

            ZStack {
                Path { path in
                    let chartWidth = w - chartLeft - 8
                    for (index, entry) in entries.enumerated() {
                        let x = chartLeft + chartWidth * CGFloat(index) / CGFloat(max(entries.count - 1, 1))
                        let y = h - (h * CGFloat(entry.estimatedBodyFat - minVal) / CGFloat(range))
                        if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(AppTheme.primaryAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .opacity(animateChart ? 1 : 0)

                let targetY = h - (h * CGFloat(targetBF - minVal) / CGFloat(range))
                Path { path in
                    path.move(to: CGPoint(x: chartLeft, y: targetY))
                    path.addLine(to: CGPoint(x: w - 8, y: targetY))
                }
                .stroke(AppTheme.success.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))

                Text("Target")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.success)
                    .position(x: w - 30, y: targetY - 10)
            }
        }
        .frame(height: 180)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("How It Works")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            Text("Body fat % is estimated based on your scan scores, gender, and body composition category. For more accurate tracking, use calipers or a DEXA scan periodically.")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(2)
        }
        .cardStyle()
    }
}
