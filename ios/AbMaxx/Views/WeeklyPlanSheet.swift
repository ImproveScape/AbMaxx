import SwiftUI

struct WeeklyPlanSheet: View {
    let vm: AppViewModel
    let currentWeek: Int
    @Environment(\.dismiss) private var dismiss

    private let dayLabels = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

    private var weekInCycle: Int {
        ((currentWeek - 1) % 4)
    }

    private var weekTheme: String {
        AppViewModel.weekTheme(for: weekInCycle)
    }

    private var weekThemeIcon: String {
        AppViewModel.weekThemeIcon(for: weekInCycle)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        heroHeader
                        daysGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Week \(currentWeek)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: 30, height: 30)
                            .background(AppTheme.cardSurfaceElevated)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: weekThemeIcon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(themeColor)
                        Text(weekTheme.uppercased())
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(themeColor)
                            .tracking(1.2)
                    }

                    Text(themeSubtitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 16)

                VStack(spacing: 3) {
                    Text("\(trainingDayCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("sessions")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            let weakest = vm.weakestZoneFromScan

            HStack(spacing: 10) {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.15))
                    .frame(width: 6, height: 6)
                Text("Targeting \(weakest.rawValue)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(weakZoneSessionCount)x this week")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.primaryAccent.opacity(0.06))
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

    // MARK: - Days Grid

    @State private var expandedDay: Int? = nil

    private var daysGrid: some View {
        VStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { offset in
                let dayNumber = (currentWeek - 1) * 7 + offset + 1
                let isRest = vm.isRestDay(for: dayNumber)
                let isToday = dayNumber == vm.programDayNumber
                let isPast = dayNumber < vm.programDayNumber
                let label = vm.targetLabel(for: dayNumber)
                let typeLabel = vm.dayTypeLabel(for: dayNumber)
                let exercises = isRest ? [] : vm.exercisesPreview(for: dayNumber)

                VStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            expandedDay = expandedDay == dayNumber ? nil : dayNumber
                        }
                    } label: {
                        dayCard(
                            dayLabel: dayLabels[offset],
                            isRest: isRest,
                            isToday: isToday,
                            isPast: isPast,
                            title: label,
                            typeLabel: typeLabel,
                            exercises: exercises
                        )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: expandedDay)

                    if expandedDay == dayNumber && !exercises.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(exercises) { ex in
                                HStack(spacing: 12) {
                                    Image(systemName: ex.region.icon)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(regionColor(ex.region))
                                        .frame(width: 28, height: 28)
                                        .background(regionColor(ex.region).opacity(0.12))
                                        .clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ex.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                        Text(vm.progressiveRepsString(for: ex, dayNumber: dayNumber))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                    Spacer()
                                    Text(ex.region.rawValue)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(regionColor(ex.region))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(regionColor(ex.region).opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }

                            volumeIndicator(for: dayNumber)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 12))
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    private func regionColor(_ region: AbRegion) -> Color {
        AppTheme.subscoreColor(for: vm.zoneScoreForRegion(region))
    }

    private func dayCard(dayLabel: String, isRest: Bool, isToday: Bool, isPast: Bool, title: String, typeLabel: String, exercises: [Exercise]) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 3) {
                Text(dayLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isToday ? AppTheme.primaryAccent : AppTheme.muted)
                    .tracking(0.5)

                if isToday {
                    Circle()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(isPast ? .white.opacity(0.4) : .white)
                    .lineLimit(1)

                if isRest {
                    Text("Recovery day")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.success.opacity(0.6))
                } else {
                    Text("\(exercises.count) exercises")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Spacer(minLength: 8)

            if isPast {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.success.opacity(0.5))
            } else if isRest {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.success.opacity(0.35))
            } else {
                typePill(typeLabel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            isToday
                ? AppTheme.cardElevated
                : AppTheme.card
        )
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isToday ? AppTheme.primaryAccent.opacity(0.3) : AppTheme.cardBorder,
                    lineWidth: isToday ? 1.5 : 1
                )
        )

        .opacity(isPast ? 0.55 : 1)
    }

    private func typePill(_ label: String) -> some View {
        let color: Color = {
            switch label {
            case "WEAK ZONE", "WEAK ZONES": return AppTheme.destructive
            case "FULL ABS": return AppTheme.warning
            default: return AppTheme.primaryAccent
            }
        }()

        return Text(label)
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(color)
            .tracking(0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Theme

    private var themeColor: Color {
        switch weekInCycle {
        case 0: return AppTheme.primaryAccent
        case 1: return AppTheme.warning
        case 2: return AppTheme.destructive
        default: return AppTheme.success
        }
    }

    private var themeSubtitle: String {
        switch weekInCycle {
        case 0: return "Build your base — 4 exercises per session"
        case 1: return "Volume up — 5 exercises, extra set per move"
        case 2: return "Push harder — increased reps & intensity"
        default: return "Active recovery — 3 exercises, reduced volume"
        }
    }

    private var trainingDayCount: Int {
        (0..<7).filter { !vm.isRestDay(for: (currentWeek - 1) * 7 + $0 + 1) }.count
    }

    private var weakZoneSessionCount: Int {
        let weakest = vm.weakestZoneFromScan
        var count = 0
        for offset in 0..<7 {
            let dayNumber = (currentWeek - 1) * 7 + offset + 1
            let exercises = vm.exercisesPreview(for: dayNumber)
            if exercises.contains(where: { $0.region == weakest }) {
                count += 1
            }
        }
        return count
    }

    private func volumeIndicator(for dayNumber: Int) -> some View {
        let wic = ((dayNumber - 1) / 7) % 4
        let label: String
        let icon: String
        let color: Color
        switch wic {
        case 0:
            label = "Base volume"
            icon = "equal.circle.fill"
            color = AppTheme.primaryAccent
        case 1:
            label = "+1 set per exercise"
            icon = "plus.circle.fill"
            color = AppTheme.warning
        case 2:
            label = "+25% reps & harder exercises"
            icon = "arrow.up.circle.fill"
            color = AppTheme.destructive
        default:
            label = "Reduced volume — recovery"
            icon = "minus.circle.fill"
            color = AppTheme.success
        }
        return HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color.opacity(0.8))
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(color.opacity(0.06))
        .clipShape(.rect(cornerRadius: 6))
    }
}
