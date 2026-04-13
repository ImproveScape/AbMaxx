import SwiftUI
import RevenueCat
import StoreKit

struct SettingsView: View {
    @Bindable var vm: AppViewModel
    var store: StoreViewModel?

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert: Bool = false
    @State private var showFinalDeleteAlert: Bool = false
    @State private var showManageSubscription: Bool = false
    @State private var isDeleting: Bool = false
    @State private var showEditProfile: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        profileCard
                        settingsSection
                        supportSection
                        dangerSection
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Yes, Delete My Account", role: .destructive) {
                    showFinalDeleteAlert = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account, all your data, and cancel your subscription. This cannot be undone.")
            }
            .alert("Are you absolutely sure?", isPresented: $showFinalDeleteAlert) {
                Button("Delete Everything", role: .destructive) {
                    performDeleteAccount()
                }
                Button("Keep My Account", role: .cancel) {}
            } message: {
                Text("This is your last chance. All workout history, scans, progress, and subscription data will be permanently erased.")
            }
            .sheet(isPresented: $showManageSubscription) {
                if let store {
                    ManageSubscriptionView(store: store)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(vm: vm)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var profileCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent.opacity(0.3), AppTheme.secondaryAccent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .overlay(Circle().strokeBorder(AppTheme.primaryAccent.opacity(0.3), lineWidth: 2))
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.primaryAccent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(vm.profile.displayName)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(vm.profile.isSubscribed ? AppTheme.success : AppTheme.muted)
                    Text(vm.profile.isSubscribed ? "Premium Member" : "Free")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(vm.profile.isSubscribed ? AppTheme.success : AppTheme.muted)
                }
            }

            Spacer()
        }
        .cardStyle(highlighted: true)
        .padding(.horizontal, 16)
    }

    private var settingsSection: some View {
        VStack(spacing: 10) {
            Text("Settings")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ProfileRow(icon: "person.text.rectangle", title: "Edit Profile") {
                    showEditProfile = true
                }
                Rectangle().fill(AppTheme.cardBorder).frame(height: 0.5).padding(.leading, 56)
                ProfileRow(icon: "bell.fill", title: "Notifications", value: vm.notificationsEnabled ? "On" : "Off") {
                    toggleNotifications()
                }
            }
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }

    private var supportSection: some View {
        VStack(spacing: 10) {
            Text("Support")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ProfileRow(icon: "questionmark.circle", title: "Help & Support") {
                    sendSupportEmail()
                }
                Rectangle().fill(AppTheme.cardBorder).frame(height: 0.5).padding(.leading, 56)
                ProfileRow(icon: "lock.shield", title: "Privacy Policy") {
                    openURL("https://abmaxxprivacypolicy.carrd.co")
                }
                Rectangle().fill(AppTheme.cardBorder).frame(height: 0.5).padding(.leading, 56)
                ProfileRow(icon: "doc.text", title: "Terms of Service") {
                    openURL("https://abmaxxterms.carrd.co")
                }
                Rectangle().fill(AppTheme.cardBorder).frame(height: 0.5).padding(.leading, 56)
                ProfileRow(icon: "star.fill", title: "Rate Us") {
                    requestReview()
                }
                Rectangle().fill(AppTheme.cardBorder).frame(height: 0.5).padding(.leading, 56)
                ProfileRow(icon: "square.and.arrow.up", title: "Share App") {
                    shareApp()
                }
            }
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }

    private var dangerSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                ProfileRow(icon: "creditcard", title: "Manage Subscription") {
                    showManageSubscription = true
                }
                Rectangle().fill(AppTheme.cardBorder).frame(height: 0.5).padding(.leading, 56)

                Button { showDeleteAlert = true } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.destructive.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "trash.fill")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.destructive)
                        }
                        Text("Delete Account")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.destructive)
                        Spacer()
                        if isDeleting {
                            ProgressView()
                                .tint(AppTheme.destructive)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .disabled(isDeleting)
            }
            .background(AppTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }

    private func toggleNotifications() {
        if vm.notificationsEnabled {
            SmartNotificationService.shared.disableAllNotifications()
            vm.notificationsEnabled = false
            UserDefaults.standard.set(false, forKey: "notificationsEnabled")
        } else {
            vm.requestNotificationPermission()
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func sendSupportEmail() {
        let subject = "AbMaxx Support Request"
        let email = "support@abmaxxapp.com"
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            AppStore.requestReview(in: scene)
        }
    }

    private func shareApp() {
        let text = "Check out AbMaxx — the ultimate ab training app! 💪🔥"
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

    private func performDeleteAccount() {
        isDeleting = true
        Task {
            await AuthenticationService.shared.deleteAccount()
            do {
                if !Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY.isEmpty || !Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY.isEmpty {
                    _ = try await Purchases.shared.logOut()
                }
            } catch {}
            vm.resetAllData()
            isDeleting = false
            dismiss()
        }
    }
}
