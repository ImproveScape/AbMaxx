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
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        weekThemeHeader
                        weakZoneCallout
                        daysGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Week \(currentWeek)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: 30, height: 30)
                            .background(AppTheme.cardSurfaceElevated)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private var weekThemeHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: weekThemeIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(themeColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(weekTheme.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(themeColor)
                    .tracking(1.5)
                Text(themeSubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(trainingDayCount)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("sessions")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(themeColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var weakZoneCallout: some View {
        let weakest = vm.weakestZoneFromScan
        let score = vm.weakestZoneScore

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppTheme.primaryAccent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR WEAK ZONE")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .tracking(1)
                Text("\(weakest.rawValue)\(score > 0 ? " · Score \(score)" : "")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Text("\(weakZoneSessionCount)x this week")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.primaryAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.primaryAccent.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    private var daysGrid: some View {
        VStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { offset in
                let dayNumber = (currentWeek - 1) * 7 + offset + 1
                let isRest = vm.isRestDay(for: dayNumber)
                let isToday = dayNumber == vm.programDayNumber
                let isPast = dayNumber < vm.programDayNumber
                let label = vm.targetLabel(for: dayNumber)
                let typeLabel = vm.dayTypeLabel(for: dayNumber)

                dayRow(
                    dayLabel: dayLabels[offset],
                    dayNumber: dayNumber,
                    isRest: isRest,
                    isToday: isToday,
                    isPast: isPast,
                    title: label,
                    typeLabel: typeLabel,
                    exercises: isRest ? [] : vm.exercisesPreview(for: dayNumber)
                )
            }
        }
    }

    private func dayRow(dayLabel: String, dayNumber: Int, isRest: Bool, isToday: Bool, isPast: Bool, title: String, typeLabel: String, exercises: [Exercise]) -> some View {
        let regions = Array(Set(exercises.map(\.region)))

        return HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(dayLabel)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(isToday ? AppTheme.primaryAccent : AppTheme.muted)
                    .tracking(0.5)
                Text("\(dayNumber)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isToday ? .white : (isPast ? .white.opacity(0.35) : .white.opacity(0.7)))
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isPast ? .white.opacity(0.4) : .white)
                        .lineLimit(1)

                    if isToday {
                        Text("TODAY")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(AppTheme.primaryAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primaryAccent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                if isRest {
                    Text("Active recovery · Stretch & hydrate")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                } else {
                    HStack(spacing: 8) {
                        Text("\(exercises.count) exercises")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)

                        if !regions.isEmpty {
                            ForEach(regions.prefix(2), id: \.self) { region in
                                Text(region.rawValue)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(regionColor(region))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(regionColor(region).opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            if isPast {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.success.opacity(0.5))
            } else if isRest {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.success.opacity(0.4))
            } else {
                typeBadge(typeLabel)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            isToday
                ? AppTheme.cardSurfaceElevated
                : AppTheme.cardSurface
        )
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isToday ? AppTheme.primaryAccent.opacity(0.3) : AppTheme.border,
                    lineWidth: isToday ? 1.5 : 1
                )
        )
        .opacity(isPast ? 0.6 : 1)
    }

    private func typeBadge(_ label: String) -> some View {
        let color: Color = {
            switch label {
            case "WEAK ZONE", "WEAK ZONES": return AppTheme.destructive
            case "FULL ABS": return AppTheme.warning
            default: return AppTheme.primaryAccent
            }
        }()

        return Text(label)
            .font(.system(size: 8, weight: .heavy))
            .foregroundStyle(color)
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    private func regionColor(_ region: AbRegion) -> Color {
        switch region {
        case .lowerAbs: return AppTheme.success
        case .obliques: return AppTheme.destructive
        case .deepCore: return Color(red: 0.6, green: 0.4, blue: 1.0)
        case .upperAbs: return AppTheme.primaryAccent
        }
    }

    private var themeColor: Color {
        switch weekInCycle {
        case 0: return AppTheme.primaryAccent
        case 1: return AppTheme.destructive
        case 2: return Color(red: 0.6, green: 0.4, blue: 1.0)
        default: return AppTheme.warning
        }
    }

    private var themeSubtitle: String {
        switch weekInCycle {
        case 0: return "Build your base with balanced zone training"
        case 1: return "Double down on your weakest zones"
        case 2: return "High variety sculpting across all zones"
        default: return "Maximum intensity before the next cycle"
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
}
