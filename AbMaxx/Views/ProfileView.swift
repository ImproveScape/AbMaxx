import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Bindable var vm: AppViewModel
    var store: StoreViewModel?
    var onSignOut: (() -> Void)?
    var onDeleteAccount: (() -> Void)?
    @State private var showDeleteAlert: Bool = false
    @State private var showLeaderboard: Bool = false
    @State private var showSettings: Bool = false
    @State private var badgePageIndex: Int = 0
    @State private var badgePulse: Bool = false
    @State private var badgeScrollID: Int?
    @State private var showBadgeLadder: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker: Bool = false

    private var abMaxxScore: Int {
        vm.latestScan?.overallScore ?? 0
    }

    private var currentTierIndex: Int {
        let score = abMaxxScore
        guard score >= RankTier.allTiers.first!.minScore else { return -1 }
        return RankTier.currentTierIndex(for: score)
    }

    private var joinDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let date = vm.profile.transformationStartDate ?? Date()
        return formatter.string(from: date)
    }

    private var targetBF: Double {
        switch vm.profile.goal {
        case .sixPack: return vm.profile.gender == .male ? 10 : 16
        case .visibleAbs: return vm.profile.gender == .male ? 13 : 19
        case .loseBellyFat: return vm.profile.gender == .male ? 15 : 21
        case .coreStrength: return vm.profile.gender == .male ? 15 : 21
        }
    }

    private var goalLabel: String {
        switch vm.profile.goal {
        case .sixPack: return "Six-Pack"
        case .visibleAbs: return "Visible Abs"
        case .loseBellyFat: return "Lose Fat"
        case .coreStrength: return "Core Strength"
        }
    }

    private var goalIcon: String {
        vm.profile.goal.icon
    }

    private var currentBodyFat: String {
        if let scan = vm.latestScan {
            return String(format: "%.0f%%", scan.estimatedBodyFat)
        }
        return vm.profile.bodyFatCategory.rangeText
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                backgroundGlow

                ScrollView {
                    VStack(spacing: 24) {
                        PageHeader(
                            title: "Profile",
                            trailing: AnyView(
                                HStack(spacing: 12) {
                                    Button {} label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.7))
                                            .frame(width: 40, height: 40)
                                            .background(AppTheme.cardSurfaceElevated)
                                            .clipShape(Circle())
                                            .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
                                    }
                                    Button { showSettings = true } label: {
                                        Image(systemName: "gearshape.fill")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.7))
                                            .frame(width: 40, height: 40)
                                            .background(AppTheme.cardSurfaceElevated)
                                            .clipShape(Circle())
                                            .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
                                    }
                                }
                            )
                        )
                        .padding(.horizontal, 16)
                        profileHeader
                        badgesRow
                        leaderboardSection
                        Color.clear.frame(height: 100)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    badgePulse = true
                }
                if !unlockedBadges.isEmpty {
                    let currentIdx = unlockedBadges.firstIndex(where: { $0.id == currentTierIndex }) ?? unlockedBadges.count - 1
                    badgePageIndex = currentIdx
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        vm.saveProfileImage(image)
                    }
                }
            }
            .navigationDestination(isPresented: $showLeaderboard) {
                LeaderboardView(vm: vm)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(vm: vm, store: store, onSignOut: onSignOut, onDeleteAccount: onDeleteAccount)
            }
            .sheet(isPresented: $showBadgeLadder) {
                BadgeLadderView(currentScore: abMaxxScore)
            }
        }
    }

    private var backgroundGlow: some View {
        StandardBackgroundOrbs()
    }

    private var profileHeader: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottom) {
                    if let profileImage = vm.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [AppTheme.primaryAccent.opacity(0.8), AppTheme.secondaryAccent.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primaryAccent.opacity(0.6), AppTheme.secondaryAccent.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [AppTheme.primaryAccent.opacity(0.8), AppTheme.secondaryAccent.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 38, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            )
                            .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20)
                    }

                    Circle()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                        .overlay(Circle().strokeBorder(AppTheme.background, lineWidth: 2))
                        .offset(y: 6)
                }
            }

            VStack(spacing: 6) {
                Text(vm.profile.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text("Joined \(joinDateText)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }

            journeyStatsRow
        }
    }

    private var journeyStatsRow: some View {
        HStack(spacing: 12) {
            journeyStat(
                icon: "flame.fill",
                value: "\(vm.profile.streakDays)",
                label: "Day Streak",
                color: AppTheme.orange
            )
            journeyStat(
                icon: "figure.core.training",
                value: "\(vm.totalExercisesCompleted)",
                label: "Workouts",
                color: AppTheme.primaryAccent
            )
            journeyStat(
                icon: "calendar",
                value: daysOnProgram,
                label: "Days In",
                color: AppTheme.success
            )
        }
        .padding(.horizontal, 16)
    }

    private var daysOnProgram: String {
        guard let start = vm.profile.transformationStartDate else { return "0" }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return "\(max(days, 0))"
    }

    private func journeyStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
    }

    private var goalTargetsSection: some View {
        HStack(spacing: 12) {
            goalPill(
                icon: goalIcon,
                label: goalLabel,
                gradient: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.7)]
            )

            goalPill(
                icon: "percent",
                label: "\(String(format: "%.0f", targetBF))% BF Goal",
                gradient: [AppTheme.orange, AppTheme.orange.opacity(0.7)]
            )

            if let scan = vm.latestScan {
                goalPill(
                    icon: "ruler",
                    label: "\(String(format: "%.0f%%", scan.estimatedBodyFat)) Now",
                    gradient: [AppTheme.success, AppTheme.success.opacity(0.7)]
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private func goalPill(icon: String, label: String, gradient: [Color]) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(gradient.first ?? .white)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [gradient.first!.opacity(0.15), gradient.first!.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var unlockedBadges: [RankTier] {
        RankTier.allTiers.filter { $0.id <= currentTierIndex }
    }

    private var allTiers: [RankTier] {
        RankTier.allTiers
    }

    private var badgesRow: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Rank")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showBadgeLadder = true
                } label: {
                    HStack(spacing: 4) {
                        Text("All Ranks")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.muted)
                }
            }
            .padding(.horizontal, 16)

            if currentTierIndex < 0 {
                VStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.muted.opacity(0.5))
                    Text("Score 45+ to unlock your first rank")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 16))
                .padding(.horizontal, 16)
            } else {
                compactBadgeStrip
            }
        }
    }

    private var compactBadgeStrip: some View {
        let currentTier = RankTier.allTiers[currentTierIndex]
        let nextTier: RankTier? = currentTierIndex + 1 < RankTier.allTiers.count ? RankTier.allTiers[currentTierIndex + 1] : nil

        return VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [currentTier.color1.opacity(0.25), currentTier.color1.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)
                        .scaleEffect(badgePulse ? 1.05 : 1.0)

                    RankBadgeImage(tier: currentTier, isUnlocked: true, size: 60)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(currentTier.name.uppercased())
                        .font(.system(size: 15, weight: .black, design: .default))
                        .tracking(2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [currentTier.color1, currentTier.color2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("OVR \(abMaxxScore) · Top \(currentTier.topPercent)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)

                    if let next = nextTier {
                        let progress = Double(abMaxxScore - currentTier.minScore) / Double(next.minScore - currentTier.minScore)
                        VStack(alignment: .leading, spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.06))
                                        .frame(height: 5)
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [currentTier.color1, currentTier.color2],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(geo.size.width * min(progress, 1.0), 4), height: 5)
                                }
                            }
                            .frame(height: 5)

                            Text("\(next.minScore - abMaxxScore) pts to \(next.name)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)

            if unlockedBadges.count > 1 {
                Divider()
                    .background(AppTheme.border)

                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(unlockedBadges.reversed()) { tier in
                            let isCurrent = tier.id == currentTierIndex
                            VStack(spacing: 4) {
                                RankBadgeImage(tier: tier, isUnlocked: true, size: isCurrent ? 36 : 30)
                                    .opacity(isCurrent ? 1.0 : 0.5)
                                if isCurrent {
                                    Circle()
                                        .fill(tier.color1)
                                        .frame(width: 4, height: 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .contentMargins(.horizontal, 0)
                .scrollIndicators(.hidden)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardSurface)
                .shadow(color: currentTier.color1.opacity(0.1), radius: 10, y: 4)
        )
        .padding(.horizontal, 16)
    }

    private var achievementsSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Achievements")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(achievementDays, id: \.day) { item in
                        achievementDayCard(day: item.day, isUnlocked: item.isUnlocked, isCurrent: item.isCurrent)
                    }
                }
                .padding(.horizontal, 16)
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)
        }
    }

    private struct AchievementDay {
        let day: Int
        let isUnlocked: Bool
        let isCurrent: Bool
    }

    private var achievementDays: [AchievementDay] {
        let streak = vm.profile.streakDays
        let milestones = [0, 1, 2, 3, 5, 7, 10, 14, 21, 30, 45, 60, 90, 120, 180, 365]
        return milestones.map { day in
            AchievementDay(
                day: day,
                isUnlocked: streak >= day,
                isCurrent: streak == day || (day == milestones.last(where: { $0 <= streak }) ?? 0 && streak >= day && (milestones.first(where: { $0 > streak }) ?? Int.max) > day)
            )
        }
    }

    private func achievementDayCard(day: Int, isUnlocked: Bool, isCurrent: Bool) -> some View {
        VStack(spacing: 8) {
            Text("DAY")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isUnlocked ? AppTheme.secondaryText : AppTheme.muted.opacity(0.5))

            Text("\(day)")
                .font(.system(size: 28, weight: .black, design: .default))
                .foregroundStyle(isUnlocked ? AppTheme.orange : AppTheme.muted.opacity(0.4))

            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.muted.opacity(0.4))
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.success.opacity(0.7))
            }
        }
        .frame(width: 80, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    isUnlocked
                        ? LinearGradient(colors: [AppTheme.cardSurfaceElevated, AppTheme.cardSurface], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [AppTheme.cardSurface.opacity(0.5), AppTheme.cardSurface.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                )
        )
        .shadow(color: Color.black.opacity(isUnlocked ? 0.15 : 0.05), radius: 4, y: 2)
    }

    // MARK: - Leaderboard Section

    private var leaderboardSection: some View {
        Button {
            showLeaderboard = true
        } label: {
            VStack(spacing: 0) {
                HStack {
                    Text("Leaderboard")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .padding(.bottom, 14)

                VStack(spacing: 0) {
                    ForEach(Array(LeaderboardMember.celebrities.prefix(3).enumerated()), id: \.element.id) { index, member in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(leaderboardMedalColor(index).opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(leaderboardMedalColor(index).opacity(0.3), lineWidth: 1)
                                    )
                                Text(leaderboardMedalEmoji(index))
                                    .font(.system(size: 20))
                            }

                            Text("#\(index + 1)")
                                .font(.system(size: 13, weight: .bold, design: .default))
                                .foregroundStyle(AppTheme.secondaryText)

                            Spacer()

                            HStack(spacing: 5) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.primaryAccent)
                                Text("\(member.score)")
                                    .font(.system(size: 14, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppTheme.primaryAccent.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.vertical, 12)

                        if index < 2 {
                            Rectangle()
                                .fill(AppTheme.border)
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cardSurfaceElevated)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, y: 3)
                )

                HStack(spacing: 12) {
                    Text("#\(formatUserRank())")
                        .font(.system(size: 12, weight: .black, design: .default))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AppTheme.primaryAccent))

                    if let profileImage = vm.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(AppTheme.primaryAccent.opacity(0.4), lineWidth: 1.5))
                    }

                    Text("You")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("\(abMaxxScore)")
                            .font(.system(size: 14, weight: .bold, design: .default))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 14)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        )
        .padding(.horizontal, 16)
    }

    private func leaderboardMedalColor(_ index: Int) -> Color {
        switch index {
        case 0: return AppTheme.warning
        case 1: return Color(red: 0.7, green: 0.72, blue: 0.78)
        case 2: return AppTheme.orange
        default: return AppTheme.muted
        }
    }

    private func leaderboardMedalEmoji(_ index: Int) -> String {
        switch index {
        case 0: return "\u{1F451}"
        case 1: return "\u{1F948}"
        case 2: return "\u{1F949}"
        default: return ""
        }
    }

    private func formatUserRank() -> String {
        let userScore = abMaxxScore
        let higherCount = LeaderboardMember.celebrities.filter { $0.score > userScore }.count
        let rank = higherCount + 1
        if rank >= 1000 {
            return String(format: "%.0fk", Double(rank) / 1000.0)
        }
        return "\(rank)"
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.callout.bold())
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(.title3, design: .default, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .glassCard()
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    var value: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.primaryAccent.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.primaryAccent)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
                if !value.isEmpty {
                    Text(value)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.muted.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
