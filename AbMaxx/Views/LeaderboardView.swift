import SwiftUI

struct LeaderboardView: View {
    @Bindable var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var liveMembers: [LeaderboardMember] = []
    @State private var isLoading: Bool = true

    private var members: [LeaderboardMember] {
        let base = liveMembers.isEmpty ? LeaderboardMember.celebrities : liveMembers
        let sorted = base.sorted { $0.score > $1.score }
        let uid = deviceId
        if sorted.contains(where: { $0.id == uid }) {
            return sorted
        }
        let userScore = vm.latestScan?.overallScore ?? 0
        let userMember = LeaderboardMember(
            id: uid,
            name: vm.profile.displayName.isEmpty ? "You" : vm.profile.displayName,
            score: userScore,
            streakDays: vm.profile.streakDays,
            initials: makeUserInitials(),
            color: "blue"
        )
        var result = sorted
        let insertIndex = result.firstIndex(where: { $0.score < userScore }) ?? result.endIndex
        result.insert(userMember, at: insertIndex)
        return result
    }

    private func makeUserInitials() -> String {
        let name = vm.profile.displayName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var deviceId: String {
        DeviceIdentityService.shared.deviceId
    }

    private var userRank: Int {
        let userScore = vm.latestScan?.overallScore ?? 0
        if let idx = members.firstIndex(where: { $0.id == deviceId }) {
            return idx + 1
        }
        let higherCount = members.filter { $0.score > userScore }.count
        return higherCount + 1
    }

    private var userScore: Int {
        vm.latestScan?.overallScore ?? 0
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            StandardBackgroundOrbs()

            if isLoading {
                ProgressView()
                    .tint(AppTheme.primaryAccent)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Top AbMaxx members ranked by overall score")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        podiumSection

                        rankingList

                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom) {
                    userRankBar
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Leaderboard")
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await refreshLeaderboard() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
            }
        }
        .task {
            await refreshLeaderboard()
        }
    }

    private func refreshLeaderboard() async {
        isLoading = liveMembers.isEmpty
        let fetched = await LeaderboardService.shared.fetchLeaderboard()
        liveMembers = fetched
        isLoading = false
    }

    // MARK: - Podium

    private var podiumSection: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if members.count >= 3 {
                podiumSlot(member: members[1], rank: 2, podiumHeight: 90)
                podiumSlot(member: members[0], rank: 1, podiumHeight: 120)
                podiumSlot(member: members[2], rank: 3, podiumHeight: 70)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func podiumSlot(member: LeaderboardMember, rank: Int, podiumHeight: CGFloat) -> some View {
        let ringColor = podiumAccentColor(rank)
        let size: CGFloat = rank == 1 ? 78 : 62
        let isCurrentUser = member.id == deviceId

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(ringColor.opacity(0.3), lineWidth: 3)
                    .frame(width: size + 6, height: size + 6)

                Circle()
                    .stroke(ringColor, lineWidth: 3)
                    .frame(width: size + 6, height: size + 6)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ringColor.opacity(0.25), ringColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)

                Text(member.initials.isEmpty ? "\(rank)" : member.initials)
                    .font(.system(size: rank == 1 ? 22 : 17, weight: .bold, design: .default))
                    .foregroundStyle(.white)
            }
            .shadow(color: ringColor.opacity(0.3), radius: 12)

            Text(rankEmoji(rank))
                .font(.system(size: 16))

            Text(truncatedName(member.name))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isCurrentUser ? AppTheme.primaryAccent : .white.opacity(0.7))
                .lineLimit(1)

            Text("\(member.score)")
                .font(.system(size: 18, weight: .black, design: .default))
                .foregroundStyle(.white)

            Text("Score")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [ringColor.opacity(0.2), ringColor.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: podiumHeight)
                    .overlay(
                        UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                            .strokeBorder(ringColor.opacity(0.25), lineWidth: 1)
                    )

                Text("\(rank)")
                    .font(.system(size: 32, weight: .black, design: .default))
                    .foregroundStyle(ringColor.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ranking List

    private var rankingList: some View {
        VStack(spacing: 10) {
            ForEach(Array(members.dropFirst(3).enumerated()), id: \.element.id) { index, member in
                let rank = index + 4
                let isCurrentUser = member.id == deviceId
                let memberColor = colorForMember(member)

                HStack(spacing: 14) {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 28)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [memberColor.opacity(0.25), memberColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(member.initials.isEmpty ? "\(rank)" : member.initials)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(memberColor.opacity(0.2), lineWidth: 1)
                        )

                    Text(member.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isCurrentUser ? AppTheme.primaryAccent : .white)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("\(member.score)")
                            .font(.system(size: 14, weight: .bold, design: .default))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(AppTheme.primaryAccent.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .strokeBorder(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(isCurrentUser ? AppTheme.primaryAccent.opacity(0.06) : AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isCurrentUser ? AppTheme.primaryAccent.opacity(0.2) : AppTheme.border, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - User Rank Bar

    private var userRankBar: some View {
        HStack(spacing: 14) {
            Text("#\(formatNumber(userRank))")
                .font(.system(size: 13, weight: .black, design: .default))
                .foregroundStyle(.white)
                .frame(width: 40)

            if let profileImage = vm.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(AppTheme.primaryAccent.opacity(0.5), lineWidth: 2)
                    )
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent.opacity(0.4), AppTheme.primaryAccent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(AppTheme.primaryAccent.opacity(0.3), lineWidth: 1.5)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(vm.profile.displayName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text("AbMaxx Member")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("\(userScore)")
                    .font(.system(size: 15, weight: .black, design: .default))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppTheme.primaryAccent.opacity(0.12))
                    .overlay(
                        Capsule()
                            .strokeBorder(AppTheme.primaryAccent.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 12/255, green: 14/255, blue: 36/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(AppTheme.primaryAccent.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "\u{1F451}"
        case 2: return "\u{1F948}"
        case 3: return "\u{1F949}"
        default: return ""
        }
    }

    private func podiumAccentColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return AppTheme.warning
        case 2: return Color(red: 0.7, green: 0.72, blue: 0.78)
        case 3: return AppTheme.orange
        default: return AppTheme.primaryAccent
        }
    }

    private func colorForMember(_ member: LeaderboardMember) -> Color {
        switch member.color {
        case "blue": return AppTheme.primaryAccent
        case "green": return AppTheme.success
        case "orange": return AppTheme.orange
        case "red": return AppTheme.destructive
        case "purple": return Color.purple
        case "pink": return Color.pink
        case "teal": return Color.teal
        case "indigo": return Color.indigo
        default: return AppTheme.primaryAccent
        }
    }

    private func truncatedName(_ name: String) -> String {
        if name.count > 10 {
            return String(name.prefix(9)) + "..."
        }
        return name
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            let k = Double(num) / 1000.0
            return String(format: "%.0fk", k)
        }
        return "\(num)"
    }
}
