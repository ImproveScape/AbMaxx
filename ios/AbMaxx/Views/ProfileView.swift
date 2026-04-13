import SwiftUI
import PhotosUI
import StoreKit

struct ProfileView: View {
    @Bindable var vm: AppViewModel
    var store: StoreViewModel?

    @State private var showSettings: Bool = false
    @State private var showEditProfile: Bool = false
    @State private var showBadgeLadder: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var abMaxxScore: Int {
        vm.latestScan?.overallScore ?? 0
    }

    private var currentTierIndex: Int {
        let score = abMaxxScore
        guard let firstTier = RankTier.allTiers.first, score >= firstTier.minScore else { return -1 }
        return RankTier.currentTierIndex(for: score)
    }

    private var joinDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let date = vm.profile.transformationStartDate ?? Date()
        return formatter.string(from: date)
    }

    private var totalWorkouts: Int {
        vm.workoutHistory.count
    }

    private var daysOnProgram: Int {
        vm.profile.daysOnProgram
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.top, 32)
                        .padding(.bottom, 40)

                    statsRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 36)

                    generalSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    aboutSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                }
            }
            .scrollIndicators(.hidden)
            .premiumBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        vm.saveProfileImage(image)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(vm: vm, store: store)
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(vm: vm)
            }
            .sheet(isPresented: $showBadgeLadder) {
                BadgeLadderView(currentScore: abMaxxScore)
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let profileImage = vm.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppTheme.card)
                            .frame(width: 90, height: 90)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(AppTheme.muted)
                            )
                    }

                    Circle()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                        .overlay(Circle().strokeBorder(AppTheme.background, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(spacing: 6) {
                Text(vm.profile.displayName)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)

                Text("Member since \(joinDateText)")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.muted)
            }

            if currentTierIndex >= 0 {
                let currentTier = RankTier.allTiers[currentTierIndex]
                Button { showBadgeLadder = true } label: {
                    HStack(spacing: 8) {
                        RankBadgeImage(tier: currentTier, isUnlocked: true, size: 20)
                        Text(currentTier.name.uppercased())
                            .font(.system(size: 15, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [currentTier.color1, currentTier.color2],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(currentTier.color1.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(currentTier.color1.opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(icon: "flame.fill", iconColor: AppTheme.caution, value: "\(vm.profile.streakDays)", label: "STREAK")
            statDivider
            statItem(icon: "dumbbell.fill", iconColor: AppTheme.primaryAccent, value: "\(totalWorkouts)", label: "WORKOUTS")
            statDivider
            statItem(icon: "calendar", iconColor: AppTheme.success, value: "\(daysOnProgram)", label: "DAYS")
        }
        .padding(.vertical, 20)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
    }

    private func statItem(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.08 * 11)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(AppTheme.cardBorder)
            .frame(width: 0.5, height: 44)
    }

    // MARK: - General Section

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GENERAL")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.10 * 13)
                .padding(.leading, 4)
                .padding(.top, 20)

            VStack(spacing: 0) {
                profileMenuRow(
                    icon: "person.text.rectangle",
                    title: "Edit Profile",
                    showChevron: true
                ) {
                    showEditProfile = true
                }

                menuDivider

                profileMenuRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    trailing: vm.notificationsEnabled ? "On" : "Off",
                    showChevron: true
                ) {
                    if vm.notificationsEnabled {
                        SmartNotificationService.shared.disableAllNotifications()
                        vm.notificationsEnabled = false
                        UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                    } else {
                        vm.requestNotificationPermission()
                    }
                }

                menuDivider

                profileMenuRow(
                    icon: "rosette",
                    title: "All Ranks",
                    showChevron: true
                ) {
                    showBadgeLadder = true
                }
            }
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ABOUT")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.10 * 13)
                .padding(.leading, 4)
                .padding(.top, 20)

            VStack(spacing: 0) {
                profileMenuRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    showChevron: true
                ) {
                    sendSupportEmail()
                }

                menuDivider

                profileMenuRow(
                    icon: "lock.shield",
                    title: "Privacy Policy",
                    showChevron: true
                ) {
                    openURL("https://abmaxxprivacypolicy.carrd.co")
                }

                menuDivider

                profileMenuRow(
                    icon: "doc.text",
                    title: "Terms of Service",
                    showChevron: true
                ) {
                    openURL("https://abmaxxterms.carrd.co")
                }

                menuDivider

                profileMenuRow(
                    icon: "star.fill",
                    title: "Rate AbMaxx",
                    showChevron: true
                ) {
                    requestReview()
                }

                menuDivider

                profileMenuRow(
                    icon: "square.and.arrow.up",
                    title: "Share App",
                    showChevron: true
                ) {
                    shareApp()
                }
            }
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Menu Row

    private func profileMenuRow(
        icon: String,
        title: String,
        trailing: String = "",
        showChevron: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                if !trailing.isEmpty {
                    Text(trailing)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(AppTheme.cardBorder)
            .frame(height: 0.5)
            .padding(.leading, 54)
    }

    // MARK: - Actions

    private func sendSupportEmail() {
        let subject = "AbMaxx Support Request"
        let email = "support@abmaxxapp.com"
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            AppStore.requestReview(in: scene)
        }
    }

    private func shareApp() {
        let text = "Check out AbMaxx — the ultimate ab training app!"
        let url = URL(string: "https://apps.apple.com/app/abmaxx")!
        let activityVC = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
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
