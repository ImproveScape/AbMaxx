import SwiftUI
import RevenueCat

struct PaywallView: View {
    let store: StoreViewModel
    let onSubscribe: () -> Void
    @State private var selectedPackageID: String?
    @State private var showDiscountOffer: Bool = false
    @State private var appeared: Bool = false

    private let termsURL = URL(string: "https://abmaxxterms.carrd.co")!
    private let privacyURL = URL(string: "https://abmaxxprivacypolicy.carrd.co")!

    private var currentOffering: Offering? {
        store.offerings?.current
    }

    private var discountOffering: Offering? {
        store.offerings?.offering(identifier: "discount_yearly")
    }

    private var discountYearlyPackage: Package? {
        findPackage(in: discountOffering, identifier: "$rc_annual", type: .annual) ?? discountOffering?.availablePackages.first
    }

    private var monthlyPackage: Package? {
        findPackage(in: currentOffering, identifier: "$rc_monthly", type: .monthly)
    }

    private var yearlyPackage: Package? {
        findPackage(in: currentOffering, identifier: "$rc_annual", type: .annual)
    }

    private func findPackage(in offering: Offering?, identifier: String, type: PackageType) -> Package? {
        guard let packages = offering?.availablePackages else { return nil }
        if let p = packages.first(where: { $0.identifier == identifier }) { return p }
        if let p = packages.first(where: { $0.packageType == type }) { return p }
        return nil
    }

    private var selectedIsYearly: Bool {
        selectedPackageID == yearlyPackage?.identifier || selectedPackageID == "yearly_fallback" || selectedPackageID == nil
    }

    var body: some View {
        ZStack {
            if store.isLoading && store.offerings == nil {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(AppTheme.primaryAccent)
                    Text("Loading plans...")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }
            } else if showDiscountOffer {
                discountOfferView
            } else {
                regularPaywall
            }
        }
        .animation(.spring(duration: 0.5), value: showDiscountOffer)
        .onAppear {
            selectedPackageID = yearlyPackage?.identifier ?? "yearly_fallback"
        }
        .onChange(of: store.offerings) { _, _ in
            if selectedPackageID == "yearly_fallback", let yp = yearlyPackage {
                selectedPackageID = yp.identifier
            }
        }
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium { onSubscribe() }
        }
        .onChange(of: store.userCancelledPurchase) { _, cancelled in
            if cancelled {
                store.userCancelledPurchase = false
                withAnimation(.spring(duration: 0.5)) {
                    showDiscountOffer = true
                }
            }
        }
        .alert("Error", isPresented: .init(
            get: { store.error != nil },
            set: { if !$0 { store.error = nil } }
        )) {
            Button("OK") { store.error = nil }
        } message: {
            Text(store.error ?? "")
        }
    }

    private func purchaseSelected() {
        guard let id = selectedPackageID else { return }
        var pkg: Package?
        if id == yearlyPackage?.identifier || id == "yearly_fallback" {
            pkg = yearlyPackage
        } else if id == monthlyPackage?.identifier || id == "monthly_fallback" {
            pkg = monthlyPackage
        } else {
            let allPackages = currentOffering?.availablePackages ?? []
            pkg = allPackages.first { $0.identifier == id }
        }
        if pkg == nil {
            let allPackages = currentOffering?.availablePackages ?? []
            if id.contains("yearly") || id.contains("annual") {
                pkg = allPackages.first { $0.storeProduct.subscriptionPeriod?.unit == .year }
            } else {
                pkg = allPackages.first { $0.storeProduct.subscriptionPeriod?.unit == .month }
            }
        }
        guard let package = pkg else {
            if store.offerings == nil {
                store.error = "Still loading plans. Please wait a moment and try again."
                Task { await store.fetchOfferings() }
            } else {
                let pkgCount = currentOffering?.availablePackages.count ?? 0
                let pkgIds = currentOffering?.availablePackages.map { $0.identifier }.joined(separator: ", ") ?? "none"
                store.error = "Plan not found. Offering has \(pkgCount) packages: [\(pkgIds)]. Please check RevenueCat dashboard."
            }
            return
        }
        Task { await store.purchase(package: package) }
    }

    // MARK: - Regular Paywall

    private var regularPaywall: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            VStack(spacing: 6) {
                Text("Transform your abs")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                HStack(spacing: 0) {
                    Text("with ")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("ABMAXX")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
            }
            .multilineTextAlignment(.center)

            Spacer().frame(height: 20)

            socialProofBadges

            Spacer().frame(height: 36)

            featureChecklist

            Spacer()

            VStack(spacing: 16) {
                planSelector

                cancelAnytimeLabel

                ctaButton

                priceSummaryLabel

                footerLinks
            }
            .padding(.bottom, 12)
        }
        .onAppear { appeared = true }
    }

    // MARK: - Social Proof Badges

    private var socialProofBadges: some View {
        HStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 1, green: 0.78, blue: 0.2))
                VStack(alignment: .leading, spacing: 0) {
                    Text("1K+")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("5-Star Reviews")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Capsule()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 28)

            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Top 30")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Fitness Apps")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Feature Checklist

    private var featureChecklist: some View {
        VStack(alignment: .leading, spacing: 28) {
            featureRow(title: "Simple, Guided Routines", subtitle: "Know exactly what to do every day.")
            featureRow(title: "Get Your Dream Abs", subtitle: "Train with precision. See results faster.")
            featureRow(title: "Track Your Transformation", subtitle: "Watch your abs transform over time.")
        }
        .padding(.horizontal, 32)
    }

    private func featureRow(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.primaryAccent)
                .frame(width: 24, height: 24)
                .offset(y: 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    // MARK: - Plan Selector

    private var yearlyCardID: String {
        yearlyPackage?.identifier ?? "yearly_fallback"
    }

    private var monthlyCardID: String {
        monthlyPackage?.identifier ?? "monthly_fallback"
    }

    private var monthlyCardSelected: Bool {
        monthlyPackage != nil ? (selectedPackageID == monthlyPackage?.identifier) : (selectedPackageID == "monthly_fallback")
    }

    private var planSelector: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.snappy(duration: 0.25)) { selectedPackageID = monthlyCardID }
            } label: {
                VStack(spacing: 4) {
                    Text("MONTHLY")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(monthlyCardSelected ? .white : AppTheme.secondaryText)
                    HStack(spacing: 0) {
                        Text("$2.77")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(monthlyCardSelected ? .white : AppTheme.secondaryText)
                        +
                        Text(" / week")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(monthlyCardSelected ? .white.opacity(0.7) : AppTheme.muted)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(monthlyCardSelected ? Color.white.opacity(0.06) : Color.white.opacity(0.02))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            monthlyCardSelected ? AppTheme.primaryAccent.opacity(0.5) : Color.white.opacity(0.06),
                            lineWidth: monthlyCardSelected ? 1.5 : 1
                        )
                )
                .overlay(alignment: .topTrailing) {
                    if monthlyCardSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.primaryAccent)
                            .padding(8)
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: selectedPackageID)

            Button {
                withAnimation(.snappy(duration: 0.25)) { selectedPackageID = yearlyCardID }
            } label: {
                VStack(spacing: 0) {
                    Text("SAVE 75%")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AppTheme.primaryAccent)
                        .clipShape(.capsule)
                        .offset(y: -8)

                    VStack(spacing: 4) {
                        Text("YEARLY")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(selectedIsYearly ? .white : AppTheme.secondaryText)
                        HStack(spacing: 0) {
                            Text("$0.67")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(selectedIsYearly ? .white : AppTheme.secondaryText)
                            +
                            Text(" / week")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(selectedIsYearly ? .white.opacity(0.7) : AppTheme.muted)
                        }
                    }
                    .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selectedIsYearly
                            ? LinearGradient(colors: [AppTheme.primaryAccent.opacity(0.15), AppTheme.primaryAccent.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.02), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            selectedIsYearly ? AppTheme.primaryAccent : Color.white.opacity(0.06),
                            lineWidth: selectedIsYearly ? 2 : 1
                        )
                )
                .overlay(alignment: .topTrailing) {
                    if selectedIsYearly {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.primaryAccent)
                            .padding(8)
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: selectedPackageID)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Cancel Anytime

    private var cancelAnytimeLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.primaryAccent)
            Text("Cancel anytime, No Commitment")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button(action: purchaseSelected) {
            HStack(spacing: 8) {
                if store.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start My Transformation")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppTheme.primaryAccent)
            .clipShape(.rect(cornerRadius: 14))
        }
        .disabled(store.isPurchasing)
        .padding(.horizontal, 24)
    }

    // MARK: - Price Summary

    private var priceSummaryLabel: some View {
        Group {
            if selectedIsYearly {
                Text("Just $34.99 a year ($2.91/mo)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            } else {
                Text("Just $11.99 billed monthly")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        HStack(spacing: 0) {
            Link("Privacy Policy", destination: privacyURL)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.muted.opacity(0.7))
            Text("  \u{2022}  ")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted.opacity(0.4))
            Link("Terms of Service", destination: termsURL)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.muted.opacity(0.7))
            Text("  \u{2022}  ")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted.opacity(0.4))
            Button("Restore") {
                Task { await store.restore() }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppTheme.muted.opacity(0.7))
        }
    }

    // MARK: - Discount Offer (after cancel)

    private var discountOfferView: some View {
        VStack(spacing: 0) {
                HStack {
                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            showDiscountOffer = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer().frame(height: 16)

                PreloadedImage(urlString: "https://r2-pub.rork.com/projects/ef37pg3laezo1t2hj7mt0/assets/26816233-f129-427e-920c-25245ea7785b.png")
                    .frame(width: 110, height: 110)

                Spacer().frame(height: 16)

                Text("LIMITED TIME OFFER")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(2)

                Spacer().frame(height: 8)

                Text("90% OFF")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)

                Spacer().frame(height: 32)

                VStack(alignment: .leading, spacing: 16) {
                    discountFeatureRow("Lowest price ever, limited offer")
                    discountFeatureRow("AI-powered ab scan & tracking")
                    discountFeatureRow("Personalized ab training plans")
                    discountFeatureRow("Nutrition guidance for visible abs")
                    discountFeatureRow("Unlimited progress analysis")
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("$34.99")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .strikethrough(color: AppTheme.destructive)
                        Text("$0.38/week")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Spacer().frame(height: 14)

                    Button(action: {
                        if let discountPkg = discountYearlyPackage {
                            Task { await store.purchase(package: discountPkg) }
                        } else if let yearlyPkg = yearlyPackage {
                            Task { await store.purchase(package: yearlyPkg) }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if store.isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Claim Your Offer")
                                    .font(.system(size: 17, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.accentGradient)
                        .clipShape(.capsule)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 6)
                    }
                    .disabled(store.isPurchasing || (discountYearlyPackage == nil && yearlyPackage == nil))
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 12)

                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            showDiscountOffer = false
                        }
                    } label: {
                        Text("I'd rather pay full price")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.clear)
                            .clipShape(.capsule)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 12)

                    Text("Billed yearly at $19.99 per year")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)

                    Spacer().frame(height: 8)

                    HStack(spacing: 0) {
                        Link("Terms", destination: termsURL)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.muted.opacity(0.6))
                        Text("  ·  ")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.muted.opacity(0.4))
                        Link("Privacy Policy", destination: privacyURL)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.muted.opacity(0.6))
                        Text("  ·  ")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.muted.opacity(0.4))
                        Button("Restore") {
                            Task { await store.restore() }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.muted.opacity(0.6))
                    }
                }
                .padding(.bottom, 16)
        }
    }

    private func discountFeatureRow(_ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.primaryAccent)
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}
