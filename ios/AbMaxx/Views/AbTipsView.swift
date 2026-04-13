import SwiftUI

struct AbTipsView: View {
    @State private var selectedCategory: AbTip.TipCategory?
    @State private var expandedTipId: String?
    @Environment(\.dismiss) private var dismiss

    private var filteredTips: [AbTip] {
        if let cat = selectedCategory {
            return AbTip.tips(for: cat)
        }
        return AbTip.allTips
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        dailyTipCard
                        categoryFilter
                        tipsList
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Ab Tips")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var dailyTipCard: some View {
        let tip = AbTip.dailyTip(for: Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.warning)
                Text("Tip of the Day")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text(tip.category.rawValue)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryAccent.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(tip.title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(tip.body)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.warning.opacity(0.3), lineWidth: 1)
        )
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryPill(label: "All", category: nil)
                ForEach(AbTip.TipCategory.allCases, id: \.self) { cat in
                    categoryPill(label: cat.rawValue, category: cat)
                }
            }
        }
        .contentMargins(.horizontal, 0)
    }

    private func categoryPill(label: String, category: AbTip.TipCategory?) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            withAnimation(.spring(duration: 0.3)) { selectedCategory = category }
        } label: {
            HStack(spacing: 6) {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .font(.caption2.bold())
                }
                Text(label)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.muted)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? AppTheme.primaryAccent : AppTheme.cardSurface)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(isSelected ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.5), lineWidth: 1)
            )
        }
    }

    private var tipsList: some View {
        VStack(spacing: 12) {
            ForEach(filteredTips) { tip in
                tipCard(tip: tip)
            }
        }
    }

    private func tipCard(tip: AbTip) -> some View {
        let isExpanded = expandedTipId == tip.id
        return Button {
            withAnimation(.spring(duration: 0.35)) {
                expandedTipId = isExpanded ? nil : tip.id
            }
        } label: {
            VStack(alignment: .leading, spacing: isExpanded ? 12 : 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(categoryColor(tip.category).opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: tip.icon)
                            .font(.body.bold())
                            .foregroundStyle(categoryColor(tip.category))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text(tip.category.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }

                if isExpanded {
                    Text(tip.body)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineSpacing(3)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
            )
        }
    }

    private func categoryColor(_ category: AbTip.TipCategory) -> Color {
        switch category {
        case .training: return AppTheme.primaryAccent
        case .nutrition: return AppTheme.success
        case .recovery: return AppTheme.purple
        case .mindset: return AppTheme.orange
        }
    }
}
