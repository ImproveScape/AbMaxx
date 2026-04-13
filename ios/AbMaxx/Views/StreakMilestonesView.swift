import SwiftUI

nonisolated struct BadgeStyle: Sendable {
    let gradient: [Color]
    let glowColor: Color
    let ringColor: Color
    let innerRingColor: Color

    static let fire = BadgeStyle(
        gradient: [Color(red: 255/255, green: 140/255, blue: 0/255), Color(red: 220/255, green: 80/255, blue: 0/255)],
        glowColor: Color(red: 255/255, green: 120/255, blue: 0/255),
        ringColor: Color(red: 255/255, green: 180/255, blue: 60/255),
        innerRingColor: Color(red: 255/255, green: 100/255, blue: 20/255)
    )

    static let ember = BadgeStyle(
        gradient: [Color(red: 255/255, green: 100/255, blue: 20/255), Color(red: 180/255, green: 40/255, blue: 0/255)],
        glowColor: Color(red: 255/255, green: 80/255, blue: 0/255),
        ringColor: Color(red: 255/255, green: 140/255, blue: 40/255),
        innerRingColor: Color(red: 200/255, green: 60/255, blue: 10/255)
    )

    static let blaze = BadgeStyle(
        gradient: [Color(red: 255/255, green: 170/255, blue: 30/255), Color(red: 255/255, green: 100/255, blue: 0/255)],
        glowColor: Color(red: 255/255, green: 150/255, blue: 0/255),
        ringColor: Color(red: 255/255, green: 200/255, blue: 80/255),
        innerRingColor: Color(red: 255/255, green: 130/255, blue: 20/255)
    )

    static let inferno = BadgeStyle(
        gradient: [Color(red: 200/255, green: 50/255, blue: 0/255), Color(red: 140/255, green: 20/255, blue: 0/255)],
        glowColor: Color(red: 220/255, green: 60/255, blue: 0/255),
        ringColor: Color(red: 255/255, green: 100/255, blue: 40/255),
        innerRingColor: Color(red: 180/255, green: 40/255, blue: 10/255)
    )

    static let volcano = BadgeStyle(
        gradient: [Color(red: 255/255, green: 80/255, blue: 10/255), Color(red: 160/255, green: 30/255, blue: 0/255)],
        glowColor: Color(red: 255/255, green: 70/255, blue: 0/255),
        ringColor: Color(red: 255/255, green: 120/255, blue: 50/255),
        innerRingColor: Color(red: 200/255, green: 50/255, blue: 0/255)
    )

    static let phoenix = BadgeStyle(
        gradient: [Color(red: 255/255, green: 200/255, blue: 50/255), Color(red: 255/255, green: 120/255, blue: 0/255)],
        glowColor: Color(red: 255/255, green: 180/255, blue: 20/255),
        ringColor: Color(red: 255/255, green: 220/255, blue: 100/255),
        innerRingColor: Color(red: 255/255, green: 160/255, blue: 30/255)
    )

    static let eternal = BadgeStyle(
        gradient: [Color(red: 255/255, green: 210/255, blue: 50/255), Color(red: 200/255, green: 150/255, blue: 0/255)],
        glowColor: Color(red: 255/255, green: 200/255, blue: 30/255),
        ringColor: Color(red: 255/255, green: 230/255, blue: 120/255),
        innerRingColor: Color(red: 230/255, green: 180/255, blue: 20/255)
    )

    static let freshGreen = BadgeStyle(
        gradient: [Color(red: 80/255, green: 220/255, blue: 100/255), Color(red: 30/255, green: 160/255, blue: 60/255)],
        glowColor: Color(red: 60/255, green: 200/255, blue: 80/255),
        ringColor: Color(red: 120/255, green: 240/255, blue: 140/255),
        innerRingColor: Color(red: 50/255, green: 180/255, blue: 70/255)
    )

    static let leafGreen = BadgeStyle(
        gradient: [Color(red: 60/255, green: 200/255, blue: 80/255), Color(red: 20/255, green: 140/255, blue: 50/255)],
        glowColor: Color(red: 50/255, green: 180/255, blue: 70/255),
        ringColor: Color(red: 100/255, green: 230/255, blue: 120/255),
        innerRingColor: Color(red: 40/255, green: 160/255, blue: 60/255)
    )

    static let emerald = BadgeStyle(
        gradient: [Color(red: 30/255, green: 180/255, blue: 80/255), Color(red: 10/255, green: 120/255, blue: 50/255)],
        glowColor: Color(red: 30/255, green: 160/255, blue: 70/255),
        ringColor: Color(red: 80/255, green: 210/255, blue: 110/255),
        innerRingColor: Color(red: 20/255, green: 140/255, blue: 60/255)
    )

    static let forest = BadgeStyle(
        gradient: [Color(red: 20/255, green: 160/255, blue: 70/255), Color(red: 5/255, green: 100/255, blue: 40/255)],
        glowColor: Color(red: 20/255, green: 140/255, blue: 60/255),
        ringColor: Color(red: 60/255, green: 200/255, blue: 100/255),
        innerRingColor: Color(red: 15/255, green: 120/255, blue: 50/255)
    )

    static let deepGreen = BadgeStyle(
        gradient: [Color(red: 10/255, green: 140/255, blue: 60/255), Color(red: 0/255, green: 80/255, blue: 30/255)],
        glowColor: Color(red: 10/255, green: 120/255, blue: 50/255),
        ringColor: Color(red: 50/255, green: 180/255, blue: 90/255),
        innerRingColor: Color(red: 5/255, green: 100/255, blue: 40/255)
    )

    static let electricBlue = BadgeStyle(
        gradient: [Color(red: 40/255, green: 140/255, blue: 255/255), Color(red: 10/255, green: 80/255, blue: 220/255)],
        glowColor: Color(red: 30/255, green: 120/255, blue: 255/255),
        ringColor: Color(red: 100/255, green: 180/255, blue: 255/255),
        innerRingColor: Color(red: 20/255, green: 100/255, blue: 240/255)
    )

    static let royalBlue = BadgeStyle(
        gradient: [Color(red: 20/255, green: 100/255, blue: 255/255), Color(red: 5/255, green: 50/255, blue: 180/255)],
        glowColor: Color(red: 15/255, green: 80/255, blue: 240/255),
        ringColor: Color(red: 70/255, green: 150/255, blue: 255/255),
        innerRingColor: Color(red: 10/255, green: 70/255, blue: 220/255)
    )

    static let deepBlue = BadgeStyle(
        gradient: [Color(red: 10/255, green: 70/255, blue: 200/255), Color(red: 0/255, green: 30/255, blue: 140/255)],
        glowColor: Color(red: 10/255, green: 60/255, blue: 180/255),
        ringColor: Color(red: 50/255, green: 120/255, blue: 240/255),
        innerRingColor: Color(red: 5/255, green: 50/255, blue: 160/255)
    )

    static let midnight = BadgeStyle(
        gradient: [Color(red: 5/255, green: 40/255, blue: 160/255), Color(red: 0/255, green: 15/255, blue: 100/255)],
        glowColor: Color(red: 5/255, green: 35/255, blue: 140/255),
        ringColor: Color(red: 30/255, green: 90/255, blue: 220/255),
        innerRingColor: Color(red: 0/255, green: 25/255, blue: 120/255)
    )

    static let sapphire = BadgeStyle(
        gradient: [Color(red: 15/255, green: 60/255, blue: 200/255), Color(red: 5/255, green: 20/255, blue: 120/255)],
        glowColor: Color(red: 10/255, green: 50/255, blue: 180/255),
        ringColor: Color(red: 40/255, green: 100/255, blue: 240/255),
        innerRingColor: Color(red: 5/255, green: 35/255, blue: 150/255)
    )

    static let teal = BadgeStyle(
        gradient: [Color(red: 0/255, green: 200/255, blue: 190/255), Color(red: 0/255, green: 140/255, blue: 140/255)],
        glowColor: Color(red: 0/255, green: 180/255, blue: 170/255),
        ringColor: Color(red: 60/255, green: 230/255, blue: 220/255),
        innerRingColor: Color(red: 0/255, green: 160/255, blue: 155/255)
    )

    static let aqua = BadgeStyle(
        gradient: [Color(red: 20/255, green: 180/255, blue: 220/255), Color(red: 0/255, green: 120/255, blue: 170/255)],
        glowColor: Color(red: 10/255, green: 160/255, blue: 200/255),
        ringColor: Color(red: 80/255, green: 210/255, blue: 240/255),
        innerRingColor: Color(red: 5/255, green: 140/255, blue: 185/255)
    )

    static let ocean = BadgeStyle(
        gradient: [Color(red: 0/255, green: 160/255, blue: 200/255), Color(red: 0/255, green: 100/255, blue: 150/255)],
        glowColor: Color(red: 0/255, green: 140/255, blue: 180/255),
        ringColor: Color(red: 50/255, green: 190/255, blue: 230/255),
        innerRingColor: Color(red: 0/255, green: 120/255, blue: 165/255)
    )

    static let gold = BadgeStyle(
        gradient: [Color(red: 255/255, green: 215/255, blue: 0/255), Color(red: 200/255, green: 160/255, blue: 0/255)],
        glowColor: Color(red: 255/255, green: 200/255, blue: 0/255),
        ringColor: Color(red: 255/255, green: 235/255, blue: 100/255),
        innerRingColor: Color(red: 230/255, green: 180/255, blue: 0/255)
    )

    static let champion = BadgeStyle(
        gradient: [Color(red: 255/255, green: 200/255, blue: 0/255), Color(red: 180/255, green: 130/255, blue: 0/255)],
        glowColor: Color(red: 240/255, green: 180/255, blue: 0/255),
        ringColor: Color(red: 255/255, green: 225/255, blue: 80/255),
        innerRingColor: Color(red: 210/255, green: 155/255, blue: 0/255)
    )

    static let legendary = BadgeStyle(
        gradient: [Color(red: 220/255, green: 170/255, blue: 0/255), Color(red: 160/255, green: 110/255, blue: 0/255)],
        glowColor: Color(red: 200/255, green: 150/255, blue: 0/255),
        ringColor: Color(red: 255/255, green: 210/255, blue: 60/255),
        innerRingColor: Color(red: 180/255, green: 130/255, blue: 0/255)
    )
}

struct StreakMilestonesView: View {
    @Bindable var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var appearAnimated: Bool = false

    private var milestones: [AppMilestone] {
        AppMilestone.allShuffled(
            streakDays: vm.profile.streakDays,
            totalExercises: vm.totalExercisesCompleted,
            totalScans: vm.scanResults.count,
            totalMealsLogged: vm.effectiveTotalMealsLogged,
            totalWorkoutSessions: vm.workoutHistory.count,
            waterGoalDaysHit: vm.waterGoalDaysHit,
            daysOnProgram: vm.profile.daysOnProgram
        )
    }

    private var unlockedCount: Int {
        milestones.filter(\.isUnlocked).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                streakHeader
                    .padding(.top, 8)

                milestonesGrid
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .premiumBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Milestones")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appearAnimated = true
            }
        }
    }

    private var streakHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.orange.opacity(0.08))
                    .frame(width: 110, height: 110)

                Circle()
                    .strokeBorder(AppTheme.orange.opacity(0.25), lineWidth: 2.5)
                    .frame(width: 110, height: 110)

                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(AppTheme.orange)
                        .symbolEffect(.pulse, options: .repeating.speed(0.5))

                    Text("\(vm.profile.streakDays)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)

                    Text("day streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Text("\(unlockedCount) of \(milestones.count) Milestones Unlocked")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var milestonesGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]

        return LazyVGrid(columns: columns, spacing: 32) {
            ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                premiumBadgeView(milestone, index: index)
            }
        }
    }

    @ViewBuilder
    private func premiumBadgeView(_ milestone: AppMilestone, index: Int) -> some View {
        let size: CGFloat = 88
        let unlocked = milestone.isUnlocked
        let style = milestone.badgeStyle

        VStack(spacing: 10) {
            ZStack {
                if unlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [style.glowColor.opacity(0.25), style.glowColor.opacity(0)],
                                center: .center,
                                startRadius: size * 0.3,
                                endRadius: size * 0.75
                            )
                        )
                        .frame(width: size + 24, height: size + 24)

                    if let url = milestone.imageURL {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: size, height: size)
                            } else if phase.error != nil {
                                fallbackBadge(milestone: milestone, style: style, size: size, unlocked: true)
                            } else {
                                Circle()
                                    .fill(style.gradient.first?.opacity(0.3) ?? Color.clear)
                                    .frame(width: size, height: size)
                                    .overlay {
                                        ProgressView()
                                            .tint(.white.opacity(0.5))
                                    }
                            }
                        }
                    } else {
                        fallbackBadge(milestone: milestone, style: style, size: size, unlocked: true)
                    }
                } else {
                    if let url = milestone.imageURL {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: size, height: size)
                                    .saturation(0)
                                    .opacity(0.25)
                            } else if phase.error != nil {
                                fallbackBadge(milestone: milestone, style: style, size: size, unlocked: false)
                            } else {
                                Circle()
                                    .fill(Color(red: 30/255, green: 35/255, blue: 50/255))
                                    .frame(width: size, height: size)
                            }
                        }
                    } else {
                        fallbackBadge(milestone: milestone, style: style, size: size, unlocked: false)
                    }
                }
            }
            .shadow(
                color: unlocked ? style.glowColor.opacity(0.35) : .clear,
                radius: 14,
                y: 4
            )

            VStack(spacing: 3) {
                Text(milestone.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(unlocked ? .white : AppTheme.muted.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(milestone.subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(unlocked ? AppTheme.secondaryText : AppTheme.muted.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(appearAnimated ? 1 : 0)
        .offset(y: appearAnimated ? 0 : 12)
        .animation(.spring(duration: 0.4).delay(Double(index) * 0.02), value: appearAnimated)
    }

    @ViewBuilder
    private func fallbackBadge(milestone: AppMilestone, style: BadgeStyle, size: CGFloat, unlocked: Bool) -> some View {
        if unlocked {
            Circle()
                .fill(
                    LinearGradient(
                        colors: style.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: size, height: size)

            VStack(spacing: 1) {
                Image(systemName: milestone.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.4), radius: 3, y: 2)

                if let num = milestone.badgeNumber {
                    Text(num)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.3), radius: 1, y: 1)
                }
            }
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 30/255, green: 35/255, blue: 50/255),
                            Color(red: 20/255, green: 24/255, blue: 38/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Circle()
                .strokeBorder(
                    Color(red: 45/255, green: 50/255, blue: 70/255).opacity(0.5),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)

            VStack(spacing: 1) {
                Image(systemName: milestone.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(red: 60/255, green: 65/255, blue: 85/255))

                if let num = milestone.badgeNumber {
                    Text(num)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 55/255, green: 60/255, blue: 80/255))
                }
            }
        }
    }
}

nonisolated struct AppMilestone: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let badgeStyle: BadgeStyle
    let isUnlocked: Bool
    let badgeNumber: String?
    let imageName: String?

    var imageURL: URL? {
        guard let imageName else { return nil }
        let projectId = Config.EXPO_PUBLIC_PROJECT_ID
        guard !projectId.isEmpty else { return nil }
        return URL(string: "https://rork.app/pa/\(projectId)/\(imageName)")
    }

    init(id: String, title: String, subtitle: String, icon: String, badgeStyle: BadgeStyle, isUnlocked: Bool, badgeNumber: String? = nil, imageName: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badgeStyle = badgeStyle
        self.isUnlocked = isUnlocked
        self.badgeNumber = badgeNumber
        self.imageName = imageName
    }

    static func allShuffled(
        streakDays: Int,
        totalExercises: Int,
        totalScans: Int,
        totalMealsLogged: Int,
        totalWorkoutSessions: Int,
        waterGoalDaysHit: Int,
        daysOnProgram: Int
    ) -> [AppMilestone] {
        let all = Self.all(
            streakDays: streakDays,
            totalExercises: totalExercises,
            totalScans: totalScans,
            totalMealsLogged: totalMealsLogged,
            totalWorkoutSessions: totalWorkoutSessions,
            waterGoalDaysHit: waterGoalDaysHit,
            daysOnProgram: daysOnProgram
        )
        let order: [String] = [
            "meal_1", "streak_7", "water_3", "exercise_10", "scan_1", "session_5",
            "streak_3", "meal_5", "exercise_50", "water_14", "streak_14", "session_15",
            "scan_5", "meal_25", "streak_30", "exercise_100", "meal_50", "scan_10",
            "streak_60", "exercise_250", "session_50", "meal_100", "streak_100",
            "scan_30", "exercise_500", "streak_365", "program_90"
        ]
        return order.compactMap { id in all.first(where: { $0.id == id }) }
    }

    static func all(
        streakDays: Int,
        totalExercises: Int,
        totalScans: Int,
        totalMealsLogged: Int,
        totalWorkoutSessions: Int,
        waterGoalDaysHit: Int,
        daysOnProgram: Int
    ) -> [AppMilestone] {
        return [
            AppMilestone(
                id: "streak_3",
                title: "Rookie",
                subtitle: "3 day streak",
                icon: "flame.fill",
                badgeStyle: .fire,
                isUnlocked: streakDays >= 3,
                badgeNumber: "3",
                imageName: "milestone_rookie_3day"
            ),
            AppMilestone(
                id: "streak_7",
                title: "Getting Serious",
                subtitle: "7 day streak",
                icon: "flame.circle.fill",
                badgeStyle: .ember,
                isUnlocked: streakDays >= 7,
                badgeNumber: "7",
                imageName: "milestone_getting_serious"
            ),
            AppMilestone(
                id: "streak_14",
                title: "Locked In",
                subtitle: "14 day streak",
                icon: "lock.fill",
                badgeStyle: .blaze,
                isUnlocked: streakDays >= 14,
                badgeNumber: "14",
                imageName: "milestone_locked_in"
            ),
            AppMilestone(
                id: "streak_30",
                title: "Monthly Beast",
                subtitle: "30 day streak",
                icon: "calendar.badge.checkmark",
                badgeStyle: .inferno,
                isUnlocked: streakDays >= 30,
                badgeNumber: "30",
                imageName: "milestone_monthly_beast"
            ),
            AppMilestone(
                id: "streak_60",
                title: "Iron Will",
                subtitle: "60 day streak",
                icon: "hands.clap.fill",
                badgeStyle: .volcano,
                isUnlocked: streakDays >= 60,
                badgeNumber: "60",
                imageName: "milestone_iron_will_blue_accent"
            ),
            AppMilestone(
                id: "streak_100",
                title: "Triple Digits",
                subtitle: "100 day streak",
                icon: "bolt.heart.fill",
                badgeStyle: .phoenix,
                isUnlocked: streakDays >= 100,
                badgeNumber: "100",
                imageName: "milestone_triple_digits"
            ),
            AppMilestone(
                id: "streak_365",
                title: "No Days Off",
                subtitle: "365 day streak",
                icon: "crown.fill",
                badgeStyle: .eternal,
                isUnlocked: streakDays >= 365,
                badgeNumber: "365",
                imageName: "milestone_no_days_off"
            ),
            AppMilestone(
                id: "meal_1",
                title: "First Bite",
                subtitle: "Logged first meal",
                icon: "fork.knife",
                badgeStyle: .freshGreen,
                isUnlocked: totalMealsLogged >= 1,
                imageName: "milestone_first_meal"
            ),
            AppMilestone(
                id: "meal_5",
                title: "Fuel Up",
                subtitle: "Logged 5 meals",
                icon: "leaf.fill",
                badgeStyle: .leafGreen,
                isUnlocked: totalMealsLogged >= 5,
                badgeNumber: "5",
                imageName: "milestone_fuel_up"
            ),
            AppMilestone(
                id: "meal_25",
                title: "Nutrition Ninja",
                subtitle: "Logged 25 meals",
                icon: "carrot.fill",
                badgeStyle: .emerald,
                isUnlocked: totalMealsLogged >= 25,
                badgeNumber: "25",
                imageName: "milestone_nutrition_ninja"
            ),
            AppMilestone(
                id: "meal_50",
                title: "Fuel Master",
                subtitle: "Logged 50 meals",
                icon: "takeoutbag.and.cup.and.straw.fill",
                badgeStyle: .forest,
                isUnlocked: totalMealsLogged >= 50,
                badgeNumber: "50",
                imageName: "milestone_fuel_master"
            ),
            AppMilestone(
                id: "meal_100",
                title: "The Logfather",
                subtitle: "Logged 100 meals",
                icon: "chart.bar.doc.horizontal.fill",
                badgeStyle: .deepGreen,
                isUnlocked: totalMealsLogged >= 100,
                badgeNumber: "100",
                imageName: "milestone_logfather"
            ),
            AppMilestone(
                id: "exercise_10",
                title: "First Steps",
                subtitle: "10 exercises done",
                icon: "figure.core.training",
                badgeStyle: .electricBlue,
                isUnlocked: totalExercises >= 10,
                badgeNumber: "10",
                imageName: "milestone_first_steps"
            ),
            AppMilestone(
                id: "exercise_50",
                title: "Core Crusher",
                subtitle: "50 exercises done",
                icon: "bolt.fill",
                badgeStyle: .royalBlue,
                isUnlocked: totalExercises >= 50,
                badgeNumber: "50",
                imageName: "milestone_core_crusher"
            ),
            AppMilestone(
                id: "exercise_100",
                title: "Ab Machine",
                subtitle: "100 exercises done",
                icon: "figure.strengthtraining.traditional",
                badgeStyle: .deepBlue,
                isUnlocked: totalExercises >= 100,
                badgeNumber: "100",
                imageName: "milestone_ab_machine"
            ),
            AppMilestone(
                id: "exercise_250",
                title: "Unstoppable",
                subtitle: "250 exercises crushed",
                icon: "bolt.circle.fill",
                badgeStyle: .midnight,
                isUnlocked: totalExercises >= 250,
                badgeNumber: "250",
                imageName: "milestone_unstoppable"
            ),
            AppMilestone(
                id: "exercise_500",
                title: "Elite Athlete",
                subtitle: "500 exercises total",
                icon: "star.circle.fill",
                badgeStyle: .sapphire,
                isUnlocked: totalExercises >= 500,
                badgeNumber: "500",
                imageName: "milestone_elite_athlete"
            ),
            AppMilestone(
                id: "session_5",
                title: "Committed",
                subtitle: "5 sessions complete",
                icon: "checkmark.seal.fill",
                badgeStyle: .teal,
                isUnlocked: totalWorkoutSessions >= 5,
                badgeNumber: "5",
                imageName: "milestone_committed"
            ),
            AppMilestone(
                id: "session_15",
                title: "Disciplined",
                subtitle: "15 sessions complete",
                icon: "trophy.fill",
                badgeStyle: .gold,
                isUnlocked: totalWorkoutSessions >= 15,
                badgeNumber: "15",
                imageName: "milestone_disciplined"
            ),
            AppMilestone(
                id: "session_50",
                title: "Warrior",
                subtitle: "50 sessions complete",
                icon: "medal.fill",
                badgeStyle: .champion,
                isUnlocked: totalWorkoutSessions >= 50,
                badgeNumber: "50",
                imageName: "milestone_warrior"
            ),
            AppMilestone(
                id: "scan_1",
                title: "First Scan",
                subtitle: "Completed first scan",
                icon: "viewfinder",
                badgeStyle: .aqua,
                isUnlocked: totalScans >= 1,
                imageName: "milestone_first_scan"
            ),
            AppMilestone(
                id: "scan_5",
                title: "Progress Tracker",
                subtitle: "Completed 5 scans",
                icon: "viewfinder.circle.fill",
                badgeStyle: .ocean,
                isUnlocked: totalScans >= 5,
                badgeNumber: "5",
                imageName: "milestone_progress_tracker"
            ),
            AppMilestone(
                id: "scan_10",
                title: "Dedicated Scanner",
                subtitle: "Completed 10 scans",
                icon: "camera.metering.spot",
                badgeStyle: .teal,
                isUnlocked: totalScans >= 10,
                badgeNumber: "10",
                imageName: "milestone_dedicated_scanner"
            ),
            AppMilestone(
                id: "water_3",
                title: "Hydrated",
                subtitle: "Water goal 3 days",
                icon: "drop.fill",
                badgeStyle: .aqua,
                isUnlocked: waterGoalDaysHit >= 3,
                badgeNumber: "3",
                imageName: "milestone_hydrated_v2"
            ),
            AppMilestone(
                id: "water_14",
                title: "Water Warrior",
                subtitle: "Water goal 14 days",
                icon: "drop.circle.fill",
                badgeStyle: .ocean,
                isUnlocked: waterGoalDaysHit >= 14,
                badgeNumber: "14",
                imageName: "milestone_water_warrior"
            ),
            AppMilestone(
                id: "program_90",
                title: "90 Day Transform",
                subtitle: "90 days on program",
                icon: "crown.fill",
                badgeStyle: .legendary,
                isUnlocked: daysOnProgram >= 90,
                badgeNumber: "90",
                imageName: "milestone_90_day_transform"
            ),
            AppMilestone(
                id: "scan_30",
                title: "Scan Master",
                subtitle: "Completed 30 scans",
                icon: "camera.viewfinder",
                badgeStyle: .teal,
                isUnlocked: totalScans >= 30,
                badgeNumber: "30",
                imageName: "milestone_scan_master"
            ),
        ]
    }
}
