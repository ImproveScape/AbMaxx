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
                BackgroundView().ignoresSafeArea()

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
                                        NavigationLink(value: workout.id) {
                                            WorkoutHistoryCard(workout: workout)
                                        }
                                        .buttonStyle(.plain)
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
            .navigationDestination(for: UUID.self) { workoutId in
                if let workout = vm.workoutHistory.first(where: { $0.id == workoutId }) {
                    WorkoutDetailView(workout: workout)
                }
            }
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
            StatPill(value: "\(vm.profile.streakDays)", label: "Streak", icon: "flame.fill", color: AppTheme.orange)
        }
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

struct WorkoutDetailView: View {
    let workout: CompletedWorkout
    @Environment(\.dismiss) private var dismiss

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: workout.date)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: workout.date)
    }

    private var difficultyColor: Color {
        switch workout.difficultyLevel {
        case "Easy": return AppTheme.success
        case "Hard": return AppTheme.destructive
        default: return AppTheme.warning
        }
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 14) {
                        Text(workout.targetLabel)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)

                        HStack(spacing: 16) {
                            Label(dateString, systemImage: "calendar")
                            Label(timeString, systemImage: "clock")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)

                        HStack(spacing: 12) {
                            StatChip(label: "Difficulty", value: workout.difficultyLevel, color: difficultyColor)
                            StatChip(label: "Exercises", value: "\(workout.exercises.count)", color: AppTheme.primaryAccent)
                            StatChip(label: "Duration", value: "~\(workout.durationMinutes)m", color: AppTheme.warning)
                        }
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("EXERCISES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .tracking(1)
                            .padding(.horizontal, 4)

                        ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.success.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(AppTheme.success)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                    HStack(spacing: 8) {
                                        Text(exercise.reps)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.secondaryText)
                                        Text("·")
                                            .foregroundStyle(AppTheme.muted)
                                        Text(exercise.region)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(AppTheme.primaryAccent)
                                    }
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.success)
                            }
                            .padding(14)
                            .background(AppTheme.cardSurface)
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(AppTheme.border, lineWidth: 1)
                            )
                        }
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatChip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}
