import SwiftUI

struct VolumeTabView: View {
    let vm: AppViewModel

    private let dayLabels: [String] = ["M", "T", "W", "T", "F", "S", "S"]

    private var todayWeekdayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func completedExerciseIds(for date: Date) -> Set<String> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = "completedExercises_\(formatter.string(from: date))"
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return []
        }
        return decoded
    }

    private var weakestRegion: AbRegion {
        vm.weakestZoneFromScan
    }

    private var zoneCards: [VolumeZoneData] {
        let exerciseIdsByRegion: [AbRegion: Set<String>] = [
            .lowerAbs: Set(Exercise.exercises(for: .lowerAbs).map(\.id)),
            .upperAbs: Set(Exercise.exercises(for: .upperAbs).map(\.id)),
            .obliques: Set(Exercise.exercises(for: .obliques).map(\.id)),
            .deepCore: Set(Exercise.exercises(for: .deepCore).map(\.id))
        ]

        let regions: [(AbRegion, Int)] = [
            (.lowerAbs, 4),
            (.upperAbs, 6),
            (.obliques, 3),
            (.deepCore, 6)
        ]

        return regions.map { region, weeklyTarget in
            let ids = exerciseIdsByRegion[region] ?? []

            var dailyCompleted: [Int] = []
            for date in weekDates {
                let completed = completedExerciseIds(for: date)
                dailyCompleted.append(completed.intersection(ids).count)
            }

            let totalDone = dailyCompleted.reduce(0, +)
            let percentage = weeklyTarget > 0 ? min(Int(Double(totalDone) / Double(weeklyTarget) * 100), 100) : 0

            return VolumeZoneData(
                region: region,
                totalDone: totalDone,
                weeklyTarget: weeklyTarget,
                percentage: percentage,
                dailyCompleted: dailyCompleted,
                isWeakest: region == weakestRegion
            )
        }
    }

    private func dotColor(for region: AbRegion) -> Color {
        AppTheme.subscoreColor(for: vm.zoneScoreForRegion(region))
    }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(zoneCards, id: \.region) { card in
                zoneCard(card)
            }
        }
    }

    private func zoneCard(_ card: VolumeZoneData) -> some View {
        let accent = dotColor(for: card.region)
        let remaining = max(card.weeklyTarget - card.totalDone, 0)

        return VStack(spacing: 16) {
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(accent)
                        .frame(width: 10, height: 10)

                    Text(card.region.rawValue)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("\(card.totalDone) of \(card.weeklyTarget)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let count = card.dailyCompleted[i]
                    let isToday = i == todayWeekdayIndex
                    let isFuture = i > todayWeekdayIndex
                    let hasWork = count > 0

                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                hasWork
                                    ? accent.opacity(0.18)
                                    : Color.white.opacity(0.04)
                            )
                            .frame(height: 52)
                            .overlay {
                                if hasWork {
                                    Text("\(count)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(accent)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        isToday ? AppTheme.primaryAccent.opacity(0.5) : Color.clear,
                                        lineWidth: isToday ? 1.5 : 0
                                    )
                            )

                        Text(dayLabels[i])
                            .font(.system(size: 12, weight: isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? AppTheme.primaryAccent : AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack {
                Text(remaining > 0 ? "\(remaining) more to hit target" : "Target reached!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(remaining > 0 ? AppTheme.secondaryText : AppTheme.success)

                Spacer()

                Text("\(card.percentage)%")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(
                        card.percentage >= 100 ? AppTheme.success
                        : (card.percentage == 0 ? AppTheme.destructive : accent)
                    )
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}

private struct VolumeZoneData {
    let region: AbRegion
    let totalDone: Int
    let weeklyTarget: Int
    let percentage: Int
    let dailyCompleted: [Int]
    let isWeakest: Bool
}
