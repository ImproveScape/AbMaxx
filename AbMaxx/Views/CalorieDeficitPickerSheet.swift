import SwiftUI

struct CalorieDeficitPickerSheet: View {
    @Bindable var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    private let options: [(deficit: Int, label: String, description: String, icon: String)] = [
        (150, "Light Cut", "Preserve muscle, slow fat loss", "leaf.fill"),
        (250, "Steady Cut", "Balanced fat loss & performance", "flame.fill"),
        (400, "Aggressive Cut", "Fastest path to visible abs", "bolt.fill")
    ]

    private var bodyFat: Double {
        vm.scanResults.last?.estimatedBodyFat ?? 18.0
    }

    private var recommendedDeficit: Int {
        if bodyFat > 20 { return 400 }
        else if bodyFat > 14 { return 250 }
        else { return 150 }
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Calorie Deficit")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                Text("Based on your \(String(format: "%.0f%%", bodyFat)) body fat")
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 8)

            VStack(spacing: 10) {
                ForEach(options, id: \.deficit) { option in
                    let isSelected = vm.profile.selectedCalorieDeficit == option.deficit
                    let isRecommended = option.deficit == recommendedDeficit

                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            vm.profile.selectedCalorieDeficit = option.deficit
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? AppTheme.primaryAccent.opacity(0.15) : Color.white.opacity(0.04))
                                    .frame(width: 44, height: 44)
                                Image(systemName: option.icon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(isSelected ? AppTheme.primaryAccent : AppTheme.muted)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("-\(option.deficit) cal/day")
                                        .font(.system(.body, design: .default, weight: .bold))
                                        .foregroundStyle(.white)
                                    if isRecommended {
                                        Text("BEST")
                                            .font(.system(size: 9, weight: .heavy, design: .default))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppTheme.primaryAccent)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(option.description)
                                    .font(.system(.caption, design: .default, weight: .medium))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            ZStack {
                                Circle()
                                    .strokeBorder(isSelected ? AppTheme.primaryAccent : AppTheme.muted.opacity(0.5), lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                if isSelected {
                                    Circle()
                                        .fill(AppTheme.primaryAccent)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .padding(16)
                        .background(isSelected ? AppTheme.primaryAccent.opacity(0.06) : AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(isSelected ? AppTheme.primaryAccent.opacity(0.4) : AppTheme.border, lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                }
            }

            Button {
                vm.profile.scanDeficit = vm.profile.selectedCalorieDeficit
                vm.recalculateNutrition()
                vm.save()
                dismiss()
            } label: {
                Text("Set Deficit")
                    .font(.system(.headline, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primaryAccent)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            if let current = vm.profile.scanDeficit {
                vm.profile.selectedCalorieDeficit = current
            }
        }
    }
}
