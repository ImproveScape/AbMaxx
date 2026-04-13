import SwiftUI

struct VolumeTabView: View {
    let vm: AppViewModel

    private var latestScan: ScanResult? {
        vm.scanResults.sorted { $0.date < $1.date }.last
    }

    private var previousScan: ScanResult? {
        let sorted = vm.scanResults.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }
        return sorted[sorted.count - 2]
    }

    private var weeklyWorkoutDays: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        var count = 0
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            let key = "completedExercises_\(formatter.string(from: day))"
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: data),
               !decoded.isEmpty {
                count += 1
            }
        }
        return count
    }

    private var weeklyExerciseCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        var count = 0
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            let key = "completedExercises_\(formatter.string(from: day))"
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
                count += decoded.count
            }
        }
        return count
    }

    private var estimatedWeeklyMinutes: Int {
        weeklyExerciseCount * 3
    }

    private var totalReps: Int {
        vm.totalExercisesCompleted * 15
    }

    private var zoneWorkThisWeek: [(String, Int, Color, Int)] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var upperCount = 0
        var lowerCount = 0
        var obliqueCount = 0
        var deepCoreCount = 0

        let upperIds = Set(Exercise.exercises(for: .upperAbs).map(\.id))
        let lowerIds = Set(Exercise.exercises(for: .lowerAbs).map(\.id))
        let obliqueIds = Set(Exercise.exercises(for: .obliques).map(\.id))
        let deepCoreIds = Set(Exercise.exercises(for: .deepCore).map(\.id))

        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            let key = "completedExercises_\(formatter.string(from: day))"
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
                upperCount += decoded.intersection(upperIds).count
                lowerCount += decoded.intersection(lowerIds).count
                obliqueCount += decoded.intersection(obliqueIds).count
                deepCoreCount += decoded.intersection(deepCoreIds).count
            }
        }

        let upperScore = latestScan?.upperAbsScore ?? 0
        let lowerScore = latestScan?.lowerAbsScore ?? 0
        let obliqueScore = latestScan?.obliquesScore ?? 0
        let deepCoreScore = latestScan?.deepCoreScore ?? 0

        return [
            ("Upper Abs", upperCount, AppTheme.primaryAccent, upperScore),
            ("Lower Abs", lowerCount, AppTheme.success, lowerScore),
            ("Obliques", obliqueCount, AppTheme.orange, obliqueScore),
            ("Deep Core", deepCoreCount, Color(red: 0.6, green: 0.4, blue: 1.0), deepCoreScore)
        ]
    }

    private var dayLabels: [String] { ["M", "T", "W", "T", "F", "S", "S"] }

    private var todayWeekdayIndex: Int {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    private var weekActivityData: [Bool] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var activity: [Bool] = []
        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) else {
                activity.append(false)
                continue
            }
            let key = "completedExercises_\(formatter.string(from: day))"
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: data),
               !decoded.isEmpty {
                activity.append(true)
            } else {
                activity.append(false)
            }
        }
        return activity
    }

    var body: some View {
        VStack(spacing: 20) {
            statsOverview
            weekActivityStrip
            zoneBreakdownSection
            effortVsResultSection
        }
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statCard(
                value: "\(weeklyWorkoutDays)",
                label: "DAYS TRAINED",
                sublabel: "this week",
                icon: "calendar",
                color: AppTheme.primaryAccent
            )
            statCard(
                value: "\(weeklyExerciseCount)",
                label: "EXERCISES",
                sublabel: "this week",
                icon: "figure.core.training",
                color: AppTheme.success
            )
            statCard(
                value: "\(vm.profile.streakDays)",
                label: "DAY STREAK",
                sublabel: "current",
                icon: "flame.fill",
                color: AppTheme.orange
            )
            statCard(
                value: "\(estimatedWeeklyMinutes)",
                label: "MINUTES",
                sublabel: "this week",
                icon: "clock.fill",
                color: AppTheme.warning
            )
        }
    }

    private func statCard(value: String, label: String, sublabel: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(0.5)
            }

            Text(value)
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(.white)

            Text(sublabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Week Activity Strip

    private var weekActivityStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THIS WEEK")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(AppTheme.muted)
                .tracking(1)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let active = weekActivityData[i]
                    let isToday = i == todayWeekdayIndex
                    let isFuture = i > todayWeekdayIndex

                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    active ? AppTheme.success.opacity(0.2)
                                    : (isFuture ? AppTheme.cardSurfaceElevated : AppTheme.destructive.opacity(0.08))
                                )
                                .frame(height: 44)

                            if active {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.success)
                            } else if isFuture {
                                Circle()
                                    .fill(AppTheme.muted.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            } else {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.destructive.opacity(0.4))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isToday ? AppTheme.primaryAccent.opacity(0.5) : Color.clear,
                                    lineWidth: isToday ? 1.5 : 0
                                )
                        )

                        Text(dayLabels[i])
                            .font(.system(size: 11, weight: isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? AppTheme.primaryAccent : AppTheme.secondaryText)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Zone Breakdown

    private var zoneBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ZONE WORK THIS WEEK")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(AppTheme.muted)
                .tracking(1)

            VStack(spacing: 0) {
                ForEach(Array(zoneWorkThisWeek.enumerated()), id: \.offset) { index, zone in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(zone.2)
                            .frame(width: 10, height: 10)

                        Text(zone.0)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        Text("Score: \(zone.3)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)

                        Text("\(zone.1) done")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(zone.1 > 0 ? zone.2 : AppTheme.muted)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    if index < zoneWorkThisWeek.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.04))
                            .frame(height: 1)
                    }
                }
            }
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Effort vs Result

    private var effortVsResultSection: some View {
        let hasScans = vm.scanResults.count >= 2

        return VStack(alignment: .leading, spacing: 12) {
            Text("EFFORT VS RESULTS")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(AppTheme.muted)
                .tracking(1)

            if hasScans, let latest = latestScan, let prev = previousScan {
                let scoreChange = latest.overallScore - prev.overallScore
                let bfChange = latest.estimatedBodyFat - prev.estimatedBodyFat

                VStack(spacing: 14) {
                    HStack(spacing: 16) {
                        effortMetric(
                            label: "Score Change",
                            value: scoreChange >= 0 ? "+\(scoreChange)" : "\(scoreChange)",
                            color: scoreChange >= 0 ? AppTheme.success : AppTheme.destructive,
                            icon: scoreChange >= 0 ? "arrow.up.right" : "arrow.down.right"
                        )
                        effortMetric(
                            label: "Body Fat",
                            value: String(format: "%+.1f%%", bfChange),
                            color: bfChange <= 0 ? AppTheme.success : AppTheme.destructive,
                            icon: bfChange <= 0 ? "arrow.down.right" : "arrow.up.right"
                        )
                    }

                    let totalWorkouts = vm.totalExercisesCompleted
                    let weeksOnProgram = max(vm.scanResults.count, 1)

                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("\(totalWorkouts) exercises across \(weeksOnProgram) weeks — averaging \(totalWorkouts / max(weeksOnProgram, 1)) per week")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.primaryAccent.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 10))
                }
                .padding(16)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.muted.opacity(0.4))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Need 2+ scans")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Complete your next scan to see how your effort translates to results")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
            }
        }
    }

    private func effortMetric(label: String, value: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.5)

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}
