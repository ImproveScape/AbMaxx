import SwiftUI

struct ZoneExercisesSheet: View {
    let zone: AbRegion
    let score: Int
    let isWeakZone: Bool
    let weakestZoneScore: Int
    let weekInfo: AppViewModel.ZoneWeekInfo
    let currentDayNumber: Int
    @Environment(\.dismiss) private var dismiss

    private var exercises: [Exercise] {
        let pool = Exercise.exercises(for: zone)
        return Array(pool.prefix(3))
    }

    private var zoneColor: Color {
        AppTheme.subscoreColor(for: score)
    }

    private var statusLabel: String {
        if score >= 75 { return "Strong" }
        if score >= 60 { return "Developing" }
        if score >= 45 { return "Needs Work" }
        return "Weak"
    }

    private var statusColor: Color {
        if score >= 75 { return AppTheme.success }
        if score >= 60 { return AppTheme.primaryAccent }
        if score >= 45 { return AppTheme.warning }
        return AppTheme.destructive
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        zoneHeader
                        weeklyPlanCard
                        exercisesList
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: "0D0D0D"))
    }

    private var zoneHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(zoneColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: zone.icon)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(zoneColor)
            }

            VStack(spacing: 6) {
                Text(zone.rawValue)
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text("\(score)")
                        .font(.system(size: 22, weight: .black, design: .default))
                        .foregroundStyle(statusColor)

                    Text(statusLabel)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if isWeakZone {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.warning)
                    Text("Weakest zone — your plan auto-prioritizes this with extra volume")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.warning)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.warning.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.warning.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Weekly Plan Card

    private var weeklyPlanCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("YOUR PLAN FOR THIS ZONE")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(zoneColor)
                    .tracking(1)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(weekInfo.sessionsPerWeek)x this week")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(zoneColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(zoneColor.opacity(0.1))
                .clipShape(Capsule())
            }

            if !weekInfo.dayNumbers.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(zip(weekInfo.dayNumbers, weekInfo.dayLabels)), id: \.0) { dayNum, dayLabel in
                        let isToday = dayNum == currentDayNumber
                        let isPast = dayNum < currentDayNumber

                        HStack(spacing: 12) {
                            Text(dayLabel.uppercased())
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(isToday ? zoneColor : AppTheme.muted)
                                .frame(width: 32, alignment: .leading)

                            Text("Day \(dayNum)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isPast ? .white.opacity(0.4) : .white)

                            if isToday {
                                Text("TODAY")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(zoneColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(zoneColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            if isPast {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.success.opacity(0.6))
                            } else {
                                Circle()
                                    .fill(isToday ? zoneColor : zoneColor.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isToday ? zoneColor.opacity(0.06) : Color.clear)
                        .clipShape(.rect(cornerRadius: 10))
                    }
                }
            }

            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(zoneColor)
                    .frame(width: 3)

                Text(weekInfo.statusMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(zoneColor)
                    .lineSpacing(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(zoneColor.opacity(0.06))
            .clipShape(.rect(cornerRadius: 10))
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Exercises List

    private var exercisesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOP EXERCISES")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(zoneColor)
                    .tracking(1)
                Spacer()
                Text("For \(zone.rawValue)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
            }

            ForEach(exercises) { exercise in
                exerciseCard(exercise)
            }
        }
    }

    private func exerciseCard(_ exercise: Exercise) -> some View {
        VStack(spacing: 0) {
            Color(AppTheme.cardSurface)
                .frame(height: 160)
                .overlay {
                    AsyncImage(url: URL(string: exercise.demoImageURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        } else {
                            Image(systemName: exercise.region.icon)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(zoneColor.opacity(0.3))
                        }
                    }
                }
                .clipShape(.rect(cornerRadii: .init(topLeading: 16, topTrailing: 16)))

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(.white)
                        Text(exercise.reps)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Text(exercise.difficulty.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.primaryAccent.opacity(0.1))
                        .clipShape(Capsule())
                }

                Text(exercise.instructions)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
                    .lineLimit(2)

                scheduledIndicator(for: exercise)
            }
            .padding(16)
        }
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private func scheduledIndicator(for exercise: Exercise) -> some View {
        let todayHitsZone = weekInfo.dayNumbers.contains(currentDayNumber)

        return HStack(spacing: 8) {
            Image(systemName: todayHitsZone ? "checkmark.shield.fill" : "calendar.badge.clock")
                .font(.system(size: 13, weight: .bold))
            Text(todayHitsZone ? "In today's session" : "Scheduled \(weekInfo.sessionsPerWeek)x this week")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(todayHitsZone ? AppTheme.success : AppTheme.secondaryText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(
            (todayHitsZone ? AppTheme.success : Color.white)
                .opacity(todayHitsZone ? 0.1 : 0.04)
        )
        .clipShape(.rect(cornerRadius: 12))
    }
}
