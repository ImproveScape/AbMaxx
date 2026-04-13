import SwiftUI

struct WeeklyStreakView: View {
    let workoutHistory: [CompletedWorkout]
    let streakDays: Int
    let transformationStartDate: Date?

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var currentWeekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let sundayOffset = -(weekday - 1)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: sundayOffset + $0, to: today) }
    }

    private var workoutDatesSet: Set<DateComponents> {
        let calendar = Calendar.current
        var set = Set<DateComponents>()
        for workout in workoutHistory {
            let comps = calendar.dateComponents([.year, .month, .day], from: workout.date)
            set.insert(comps)
        }
        return set
    }

    private var completedCount: Int {
        currentWeekDays.filter { dayStatus(for: $0) == .completed || dayStatus(for: $0) == .restDay }.count
    }

    private func dayStatus(for date: Date) -> DayStatus {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let day = calendar.startOfDay(for: date)

        if day > today { return .future }
        if day == today { return .today }

        if let start = transformationStartDate, day < calendar.startOfDay(for: start) {
            return .future
        }

        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        if workoutDatesSet.contains(comps) {
            return .completed
        }

        let dayNum = programDayNumber(for: date)
        if dayNum > 0 {
            let diw = (dayNum - 1) % 7
            if diw == 3 || diw == 6 {
                return .restDay
            }
        }

        return .missed
    }

    private func programDayNumber(for date: Date) -> Int {
        guard let start = transformationStartDate else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: date)).day ?? 0
        return max(days + 1, 0)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.orange)
                    Text("\(streakDays) day streak")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                Spacer()
                Text("\(completedCount)/7 this week")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    let date = currentWeekDays[index]
                    let status = dayStatus(for: date)
                    dayCell(label: dayLabels[index], status: status)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private func dayCell(label: String, status: DayStatus) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(status == .today ? .white : AppTheme.muted)

            ZStack {
                switch status {
                case .completed, .restDay:
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 42, height: 42)
                        .shadow(color: AppTheme.success.opacity(0.3), radius: 6, y: 2)
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)

                case .today:
                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Circle()
                        .strokeBorder(AppTheme.primaryAccent, lineWidth: 2.5)
                        .frame(width: 42, height: 42)
                    Circle()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: 10, height: 10)

                case .missed:
                    Circle()
                        .fill(AppTheme.destructive.opacity(0.1))
                        .frame(width: 42, height: 42)
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.destructive.opacity(0.6))

                case .future:
                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 42, height: 42)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                        .frame(width: 42, height: 42)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private enum DayStatus {
    case completed
    case missed
    case today
    case restDay
    case future
}
