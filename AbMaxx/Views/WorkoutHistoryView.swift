import SwiftUI

struct WorkoutHistoryView: View {
    @Bindable var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    private var sortedWorkouts: [CompletedWorkout] {
        vm.workoutHistory.sorted { $0.date > $1.date }
    }

    private var groupedByWeek: [(String, [CompletedWorkout])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sortedWorkouts) { workout -> String in
            let weekOfYear = calendar.component(.weekOfYear, from: workout.date)
            let year = calendar.component(.yearForWeekOfYear, from: workout.date)
            if calendar.isDate(workout.date, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            }
            let weekStart = calendar.date(from: DateComponents(weekOfYear: weekOfYear, yearForWeekOfYear: year)) ?? workout.date
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Week of \(formatter.string(from: weekStart))"
        }
        return grouped.sorted { pair1, pair2 in
            let d1 = pair1.1.first?.date ?? Date.distantPast
            let d2 = pair2.1.first?.date ?? Date.distantPast
            return d1 > d2
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if sortedWorkouts.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            statsHeader

                            ForEach(groupedByWeek, id: \.0) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(section.0.uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .tracking(1)
                                        .padding(.horizontal, 4)

                                    ForEach(section.1) { workout in
                                        WorkoutHistoryCard(workout: workout)
                                    }
                                }
                            }

                            Color.clear.frame(height: 40)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.primaryAccent)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var statsHeader: some View {
        HStack(spacing: 10) {
            StatPill(value: "\(sortedWorkouts.count)", label: "Workouts", icon: "figure.core.training", color: AppTheme.primaryAccent)
            StatPill(value: "\(totalXP)", label: "Total XP", icon: "bolt.fill", color: AppTheme.warning)
            StatPill(value: "\(vm.profile.streakDays)", label: "Streak", icon: "flame.fill", color: AppTheme.orange)
        }
    }

    private var totalXP: Int {
        sortedWorkouts.reduce(0) { $0 + $1.totalXP }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.muted)
            Text("No workouts yet")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Complete your first workout\nto start tracking your history.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .default))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }
}

struct WorkoutHistoryCard: View {
    let workout: CompletedWorkout

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: workout.date)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: workout.date)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.targetLabel)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        Label(dateString, systemImage: "calendar")
                        Label(timeString, systemImage: "clock")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("+\(workout.totalXP) XP")
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundStyle(AppTheme.primaryAccent)

                    Text(workout.difficultyLevel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(difficultyColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(14)

            Rectangle()
                .fill(AppTheme.border)
                .frame(height: 1)

            VStack(spacing: 0) {
                ForEach(workout.exercises) { ex in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.success)
                        Text(ex.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text(ex.region)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
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

    private var difficultyColor: Color {
        switch workout.difficultyLevel {
        case "Easy": return AppTheme.success
        case "Hard": return AppTheme.destructive
        default: return AppTheme.warning
        }
    }
}
