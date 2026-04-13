import SwiftUI
import RevenueCat

struct ManageSubscriptionView: View {
    @Bindable var store: StoreViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var customerInfo: CustomerInfo?
    @State private var isLoading: Bool = true
    @State private var showCancelInfo: Bool = false

    private var activeEntitlement: EntitlementInfo? {
        customerInfo?.entitlements["Premium"]
    }

    private var planName: String {
        guard let entitlement = activeEntitlement else { return "No Active Plan" }
        let id = entitlement.productIdentifier.lowercased()
        if id.contains("year") || id.contains("annual") {
            return "Yearly Plan"
        } else if id.contains("month") {
            return "Monthly Plan"
        }
        return "Premium"
    }

    private var planPrice: String {
        guard let entitlement = activeEntitlement else { return "" }
        let id = entitlement.productIdentifier.lowercased()
        if id.contains("year") || id.contains("annual") {
            return "$34.99/year"
        } else if id.contains("month") {
            return "$11.99/month"
        }
        return ""
    }

    private var expirationText: String {
        guard let date = activeEntitlement?.expirationDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Renews \(formatter.string(from: date))"
    }

    private var isActive: Bool {
        activeEntitlement?.isActive == true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            currentPlanCard
                            manageActions
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Manage Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
            .alert("Cancel Subscription", isPresented: $showCancelInfo) {
                Button("Open Settings", role: .destructive) {
                    openSubscriptionSettings()
                }
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("To cancel your subscription, you'll be taken to your Apple ID subscription settings where you can manage or cancel your plan.")
            }
        }
        .presentationDragIndicator(.visible)
        .task {
            await loadCustomerInfo()
        }
    }

    private var currentPlanCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent.opacity(0.3), AppTheme.secondaryAccent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                Image(systemName: isActive ? "crown.fill" : "xmark.circle")
                    .font(.title2)
                    .foregroundStyle(isActive ? AppTheme.warning : AppTheme.muted)
            }

            VStack(spacing: 6) {
                Text(planName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                if !planPrice.isEmpty {
                    Text(planPrice)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                }

                if !expirationText.isEmpty {
                    Text(expirationText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            if isActive {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.success)
                    Text("Active")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.success)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.success.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
    }

    private var manageActions: some View {
        VStack(spacing: 0) {
            Button {
                openSubscriptionSettings()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.primaryAccent.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.primaryAccent)
                    }
                    Text("Change Plan")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.muted.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Divider().overlay(AppTheme.border.opacity(0.3)).padding(.leading, 56)

            Button {
                showCancelInfo = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.destructive.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "xmark.circle")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.destructive)
                    }
                    Text("Cancel Subscription")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.destructive)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.muted.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
    }

    private func loadCustomerInfo() async {
        isLoading = true
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {}
        isLoading = false
    }

    private func openSubscriptionSettings() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}
