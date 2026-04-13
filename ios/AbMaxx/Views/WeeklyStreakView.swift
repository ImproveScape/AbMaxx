import SwiftUI

struct WeeklyStreakView: View {
    let workoutHistory: [CompletedWorkout]
    let streakDays: Int
    let transformationStartDate: Date?

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let fullDayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

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

    private let circleSize: CGFloat = 42

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let date = currentWeekDays[index]
                let status = dayStatus(for: date)
                dayCircle(letter: dayLabels[index], status: status)
            }
        }
    }

    private func dayCircle(letter: String, status: DayStatus) -> some View {
        ZStack {
            switch status {
            case .completed, .restDay:
                Circle()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: circleSize, height: circleSize)
                Text(letter)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

            case .today:
                Circle()
                    .strokeBorder(AppTheme.primaryAccent, lineWidth: 2.5)
                    .frame(width: circleSize, height: circleSize)
                Text(letter)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)

            case .missed:
                Circle()
                    .fill(AppTheme.destructive.opacity(0.2))
                    .frame(width: circleSize, height: circleSize)
                Text(letter)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.destructive)

            case .future:
                Circle()
                    .fill(AppTheme.cardSurface)
                    .frame(width: circleSize, height: circleSize)
                Text(letter)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
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
