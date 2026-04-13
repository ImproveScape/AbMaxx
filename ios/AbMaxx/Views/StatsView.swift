import SwiftUI

struct StatsView: View {
    @Bindable var vm: AppViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        PageHeader(title: "My Stats")
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        if let scan = vm.latestScan {
                            latestScanCard(scan)
                            regionBreakdown(scan)
                            phaseGrowthChart
                        } else {
                            noScanView
                        }

                        Color.clear.frame(height: 100)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func latestScanCard(_ scan: ScanResult) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text("Latest Scan")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text(scan.date, style: .date)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.cardSurfaceElevated)
                    .clipShape(Capsule())
            }

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 6)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: Double(scan.overallScore) / 100.0)
                        .stroke(
                            AngularGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent, AppTheme.tertiaryAccent, AppTheme.primaryAccent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text("\(scan.overallScore)")
                            .font(.system(size: 28, weight: .black, design: .default))
                            .foregroundStyle(.white)
                        Text("Score")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(scan.subscores, id: \.0) { name, score, icon in
                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 9))
                                .foregroundStyle(AppTheme.primaryAccent)
                                .frame(width: 14)
                            Text(name)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text("\(score)")
                                .font(.caption2.bold())
                                .foregroundStyle(AppTheme.scoreColor(for: score))
                        }
                    }
                }
            }
        }
        .cardStyle(highlighted: true)
        .padding(.horizontal, 16)
    }

    private func regionBreakdown(_ scan: ScanResult) -> some View {
        VStack(spacing: 12) {
            Text("Ab Regions")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(scan.regions, id: \.0) { name, score, icon in
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 3)
                                .frame(width: 48, height: 48)
                            Circle()
                                .trim(from: 0, to: Double(score) / 100.0)
                                .stroke(AppTheme.scoreColor(for: score), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 48, height: 48)
                                .rotationEffect(.degrees(-90))
                            Image(systemName: icon)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.scoreColor(for: score))
                        }
                        Text(name)
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(score)")
                            .font(.system(.subheadline, design: .default, weight: .black))
                            .foregroundStyle(AppTheme.scoreColor(for: score))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glassCard()
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var phaseGrowthChart: some View {
        VStack(spacing: 12) {
            Text("Phase Growth")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            if vm.scanResults.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(AppTheme.muted)
                    Text("Complete scans to see growth")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(vm.scanResults) { scan in
                        VStack(spacing: 6) {
                            Text("\(scan.overallScore)")
                                .font(.caption2.bold())
                                .foregroundStyle(AppTheme.scoreColor(for: scan.overallScore))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.scoreColor(for: scan.overallScore), AppTheme.scoreColor(for: scan.overallScore).opacity(0.2)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .frame(height: CGFloat(scan.overallScore) * 1.3)
                            Text("P\(scan.phase + 1)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160)
                .padding(.vertical, 6)
            }
        }
        .cardStyle()
        .padding(.horizontal, 16)
    }

    private var noScanView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.primaryAccent.opacity(0.5))
            }
            Text("No Scan Data Yet")
                .font(.headline.bold())
                .foregroundStyle(.white)
            Text("Complete your first scan to see stats")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.vertical, 50)
        .padding(.horizontal, 40)
    }
}
