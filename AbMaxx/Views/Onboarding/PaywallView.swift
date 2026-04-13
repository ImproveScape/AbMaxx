import SwiftUI
import RevenueCat

struct PaywallView: View {
    let store: StoreViewModel
    let onSubscribe: () -> Void
    @State private var selectedPackageID: String?
    @State private var showDiscountOffer: Bool = false
    @State private var appeared: Bool = false
    @State private var showRestoreSuccess: Bool = false

    private let termsURL = URL(string: "https://abmaxxterms.carrd.co")!
    private let privacyURL = URL(string: "https://abmaxxprivacypolicy.carrd.co")!

    private var currentOffering: Offering? {
        store.offerings?.current
    }

    private var discountOffering: Offering? {
        let allOfferings: [String: Offering] = store.offerings?.all ?? [:]
        return allOfferings["discount_yearly"]
    }

    private var monthlyPackage: Package? {
        findPackage(in: currentOffering, identifier: "$rc_monthly", type: .monthly)
    }

    private var yearlyPackage: Package? {
        findPackage(in: currentOffering, identifier: "$rc_annual", type: .annual)
    }

    private var discountYearlyPackage: Package? {
        let result = findPackage(in: discountOffering, identifier: "$rc_annual", type: .annual)
        if result != nil { return result }
        return discountOffering?.availablePackages.first
    }

    private func findPackage(in offering: Offering?, identifier: String, type: PackageType) -> Package? {
        guard let packages = offering?.availablePackages else { return nil }
        if let p = packages.first(where: { $0.identifier == identifier }) { return p }
        if let p = packages.first(where: { $0.packageType == type }) { return p }
        return nil
    }

    private var selectedIsYearly: Bool {
        let yID = yearlyPackage?.identifier
        let dID = discountYearlyPackage?.identifier
        return selectedPackageID == yID || selectedPackageID == dID || selectedPackageID == "yearly_fallback" || selectedPackageID == nil
    }

    private var priceSummaryText: String {
        if selectedIsYearly {
            return "Just $34.99 a year ($2.91/mo)"
        } else {
            return "Just $11.99 Per Month"
        }
    }

    var body: some View {
        ZStack {
            if store.isLoading && store.offerings == nil {
                loadingView
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
        .onChange(of: store.userDidCancel) { _, cancelled in
            if cancelled {
                store.userDidCancel = false
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

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppTheme.primaryAccent)
            Text("Loading plans...")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
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
            pkg = allPackages.first(where: { $0.identifier == id })
        }
        guard let package = pkg else {
            if store.offerings == nil {
                store.error = "Still loading plans. Please wait a moment and try again."
                Task { await store.fetchOfferings() }
            } else {
                store.error = "Plan not found. Please try again."
            }
            return
        }
        Task {
            await store.purchase(package: package)
            if store.isPremium { onSubscribe() }
        }
    }

    private func purchaseDiscounted() {
        if let discountPkg = discountYearlyPackage {
            Task {
                await store.purchase(package: discountPkg)
                if store.isPremium { onSubscribe() }
            }
        } else if let yearlyPkg = yearlyPackage {
            Task {
                await store.purchase(package: yearlyPkg)
                if store.isPremium { onSubscribe() }
            }
        }
    }

    // MARK: - Regular Paywall

    private var regularPaywall: some View {
        ZStack {
            Color(red: 6/255, green: 10/255, blue: 28/255).ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 15/255, green: 40/255, blue: 120/255).opacity(0.8),
                    Color(red: 10/255, green: 25/255, blue: 80/255).opacity(0.5),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 20/255, green: 50/255, blue: 140/255).opacity(0.35),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 48)

                regularTitle

                Spacer().frame(height: 32)

                featureChecklist
                    .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                socialProofBadges

                Spacer()

                planBoxes
                    .padding(.horizontal, 24)

                Spacer().frame(height: 14)

                cancelAnytimeLabel

                Spacer().frame(height: 16)

                regularBottomSection
            }
        }
        .onAppear { appeared = true }
    }

    private var regularTitle: some View {
        VStack(spacing: 0) {
            (Text("Transform your abs\nwith ")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(.white)
            +
            Text("AbMaxx")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(AppTheme.primaryAccent))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
        }
    }

    private var featureChecklist: some View {
        VStack(alignment: .leading, spacing: 22) {
            paywallFeature(
                title: "Simple, Guided Routines",
                subtitle: "Know exactly what to do every day."
            )
            paywallFeature(
                title: "Get Your Dream Abs",
                subtitle: "Train with precision. See results faster."
            )
            paywallFeature(
                title: "Track Your Transformation",
                subtitle: "Watch your abs transform over time."
            )
        }
    }

    private func paywallFeature(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var cancelAnytimeLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
            Text("Cancel anytime, No Commitment")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var regularBottomSection: some View {
        VStack(spacing: 10) {
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
                .padding(.vertical, 17)
                .background(AppTheme.accentGradient)
                .clipShape(.rect(cornerRadius: 14))
                .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 16, y: 6)
            }
            .disabled(store.isPurchasing)
            .padding(.horizontal, 24)

            HStack(spacing: 4) {
                Link("Privacy Policy", destination: privacyURL)
                Text("\u{2022}")
                    .foregroundStyle(AppTheme.muted.opacity(0.4))
                Link("Terms of Service", destination: termsURL)
                Text("\u{2022}")
                    .foregroundStyle(AppTheme.muted.opacity(0.4))
                Button {
                    Task {
                        await store.restore()
                        if store.isPremium { onSubscribe() }
                    }
                } label: {
                    if store.isRestoring {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(AppTheme.muted)
                    } else {
                        Text("Restore")
                    }
                }
                .disabled(store.isRestoring)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppTheme.muted.opacity(0.5))

            Text(priceSummaryText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Social Proof

    private var socialProofBadges: some View {
        HStack(spacing: 16) {
            socialBadge(
                icon: "star.fill",
                iconColor: Color(red: 255/255, green: 200/255, blue: 50/255),
                topText: "1K+",
                bottomText: "5-Star Reviews"
            )

            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 32)

            socialBadge(
                icon: "trophy.fill",
                iconColor: AppTheme.primaryAccent,
                topText: "Top 30",
                bottomText: "Fitness Apps"
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func socialBadge(icon: String, iconColor: Color, topText: String, bottomText: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 1) {
                Text(topText)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                Text(bottomText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    // MARK: - Plan Boxes (Side by Side)

    private var planBoxes: some View {
        HStack(spacing: 12) {
            monthlyPlanBox
            yearlyPlanBox
        }
    }

    private var monthlyPlanBox: some View {
        let mPkg = monthlyPackage
        let cardID = mPkg?.identifier ?? "monthly_fallback"
        let isSelected: Bool = mPkg != nil ? (selectedPackageID == mPkg?.identifier) : (selectedPackageID == "monthly_fallback")

        return Button {
            withAnimation(.snappy(duration: 0.25)) { selectedPackageID = cardID }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text("MONTHLY")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : AppTheme.secondaryText)
                    .tracking(0.8)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$2.77")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                    Text("/ week")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : AppTheme.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
            .background(Color.white.opacity(isSelected ? 0.08 : 0.04))
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? AppTheme.primaryAccent : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .sensoryFeedback(.selection, trigger: selectedPackageID)
    }

    private var yearlyPlanBox: some View {
        let cardID = yearlyPackage?.identifier ?? "yearly_fallback"
        let isSelected = selectedIsYearly

        return Button {
            withAnimation(.snappy(duration: 0.25)) { selectedPackageID = cardID }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text("YEARLY")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : AppTheme.secondaryText)
                    .tracking(0.8)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$0.67")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                    Text("/ week")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : AppTheme.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [AppTheme.primaryAccent.opacity(0.15), AppTheme.primaryAccent.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.04), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? AppTheme.primaryAccent : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .padding(10)
                }
            }
            .overlay(alignment: .top) {
                Text("SAVE 75%")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryAccent)
                    .clipShape(.rect(cornerRadius: 8))
                    .offset(y: -10)
            }
            .shadow(color: isSelected ? AppTheme.primaryAccent.opacity(0.2) : .clear, radius: 16, y: 4)
        }
        .sensoryFeedback(.selection, trigger: selectedPackageID)
    }

    // MARK: - Discount Offer

    private var discountOfferView: some View {
        ZStack {
            Color(red: 6/255, green: 10/255, blue: 28/255).ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 15/255, green: 40/255, blue: 120/255).opacity(0.8),
                    Color(red: 10/255, green: 25/255, blue: 80/255).opacity(0.5),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 20/255, green: 50/255, blue: 140/255).opacity(0.35),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                discountTopBar

                Spacer().frame(height: 16)

                discountHeroSection

                Spacer().frame(height: 32)

                discountFeatureList

                Spacer()

                discountBottomSection
            }
        }
    }

    private var discountTopBar: some View {
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
    }

    private var discountHeroSection: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: "https://r2-pub.rork.com/projects/ef37pg3laezo1t2hj7mt0/assets/26816233-f129-427e-920c-25245ea7785b.png")) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
            }
            .frame(width: 110, height: 110)

            Spacer().frame(height: 8)

            Text("LIMITED TIME OFFER")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(AppTheme.secondaryText)
                .tracking(2)

            Text("43% OFF")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(AppTheme.primaryAccent)
        }
    }

    private var discountFeatureList: some View {
        VStack(alignment: .leading, spacing: 16) {
            DiscountFeatureCheck(text: "Lowest price ever, limited offer")
            DiscountFeatureCheck(text: "AI-powered ab scan & tracking")
            DiscountFeatureCheck(text: "Personalized ab training plans")
            DiscountFeatureCheck(text: "Nutrition guidance for visible abs")
            DiscountFeatureCheck(text: "Unlimited progress analysis")
        }
        .padding(.horizontal, 32)
    }

    private var discountBottomSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("$34.99")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
                    .strikethrough(color: AppTheme.destructive)
                Text("$19.99/year")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
            }

            Spacer().frame(height: 14)

            Button(action: purchaseDiscounted) {
                HStack(spacing: 8) {
                    if store.isPurchasing {
                        ProgressView()
                            .tint(Color(red: 6/255, green: 10/255, blue: 28/255))
                    } else {
                        Text("CLAIM YOUR OFFER")
                            .font(.system(size: 17, weight: .heavy))
                    }
                }
                .foregroundStyle(Color(red: 6/255, green: 10/255, blue: 28/255))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 16))
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
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppTheme.secondaryText.opacity(0.35), lineWidth: 1.5)
                    )
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            Text("Billed yearly at $19.99 per year")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.muted)

            Spacer().frame(height: 8)

            discountFooterLinks
        }
        .padding(.bottom, 16)
    }

    private var discountFooterLinks: some View {
        HStack(spacing: 0) {
            Link("Terms", destination: termsURL)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.muted.opacity(0.6))
            Text("  \u{00B7}  ")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted.opacity(0.4))
            Link("Privacy Policy", destination: privacyURL)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.muted.opacity(0.6))
            Text("  \u{00B7}  ")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted.opacity(0.4))
            Button {
                Task {
                    await store.restore()
                    if store.isPremium { onSubscribe() }
                }
            } label: {
                if store.isRestoring {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(AppTheme.muted)
                } else {
                    Text("Restore")
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppTheme.muted.opacity(0.6))
            .disabled(store.isRestoring)
        }
    }
}

struct PaywallFeatureRow: View {
    var icon: String = "checkmark"
    let text: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.primaryAccent.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.primaryAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
        }
    }
}

struct DiscountFeatureCheck: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.primaryAccent)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }
}

struct AccountabilityStat: View {
    let value: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .default))
                .foregroundStyle(color)
                .frame(width: 60)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(2)
            Spacer()
        }
        .padding(14)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }
}
