import SwiftUI

struct CalorieDeficitPickerSheet: View {
    @Bindable var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var customValue: String = ""
    @FocusState private var isEditing: Bool
    @State private var hapticTrigger: Int = 0

    private let presets: [(value: Int, label: String, icon: String)] = [
        (150, "Light", "hare"),
        (250, "Steady", "flame"),
        (400, "Aggressive", "bolt.fill"),
        (500, "Extreme", "bolt.horizontal.fill")
    ]

    private var currentDeficit: Int {
        Int(customValue) ?? vm.profile.selectedCalorieDeficit
    }

    private var isValid: Bool {
        guard let val = Int(customValue) else { return false }
        return val >= 50 && val <= 2000
    }

    private var bodyFat: Double {
        vm.scanResults.last?.estimatedBodyFat ?? 18.0
    }

    private var recommendedDeficit: Int {
        if bodyFat > 20 { return 400 }
        else if bodyFat > 14 { return 250 }
        else { return 150 }
    }

    private var weeklyLoss: String {
        let lbs = Double(currentDeficit) * 7.0 / 3500.0
        return String(format: "%.1f", lbs)
    }

    private var isExtremeDeficit: Bool {
        currentDeficit >= 750
    }

    private var resultingCalories: Int {
        max(0, Int(vm.profile.tdee) - currentDeficit)
    }

    private var isBelowMinimum: Bool {
        resultingCalories < 1200 && resultingCalories > 0
    }

    private var warningMessage: String? {
        if isBelowMinimum {
            return "This puts you at \(resultingCalories) cal/day — below the safe minimum of 1,200. Risk of muscle loss, fatigue & metabolic slowdown."
        } else if isExtremeDeficit {
            return "Aggressive deficits can cause muscle loss, low energy & binge cycles. Consider a moderate approach for sustainable results."
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                inputSection
                presetsGrid
                weeklyEstimate
                if let warning = warningMessage {
                    deficitWarningBanner(warning)
                }
                confirmButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(BackgroundView().ignoresSafeArea())
        .onAppear {
            let current = vm.profile.scanDeficit ?? vm.profile.selectedCalorieDeficit
            customValue = "\(current)"
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
    }


    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Daily Deficit")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text("How many calories below maintenance")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.bottom, 20)
    }

    private var inputSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("-")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryAccent)

            TextField("", text: $customValue)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused($isEditing)
                .frame(maxWidth: 160)
                .onChange(of: customValue) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue { customValue = filtered }
                    if let val = Int(filtered), val > 2000 {
                        customValue = "2000"
                    }
                }

            Text("cal")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isEditing ? AppTheme.primaryAccent.opacity(0.5) : AppTheme.border,
                            lineWidth: isEditing ? 1.5 : 1
                        )
                )
        )
        .padding(.bottom, 16)
        .onTapGesture { isEditing = true }
    }

    private var presetsGrid: some View {
        HStack(spacing: 8) {
            ForEach(presets, id: \.value) { preset in
                let isActive = customValue == "\(preset.value)"
                let isRec = preset.value == recommendedDeficit

                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        customValue = "\(preset.value)"
                        isEditing = false
                        hapticTrigger += 1
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(isActive ? AppTheme.primaryAccent.opacity(0.18) : Color.white.opacity(0.04))
                                .frame(width: 40, height: 40)
                            Image(systemName: preset.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(isActive ? AppTheme.primaryAccent : AppTheme.muted)
                        }

                        Text("\(preset.value)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(isActive ? .white : AppTheme.secondaryText)

                        Text(preset.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isActive ? AppTheme.primaryAccent : AppTheme.muted)

                        if isRec {
                            Text("REC")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(AppTheme.primaryAccent, in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isActive ? AppTheme.primaryAccent.opacity(0.06) : AppTheme.cardSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isActive ? AppTheme.primaryAccent.opacity(0.4) : AppTheme.border,
                                lineWidth: isActive ? 1.5 : 1
                            )
                    )
                }
            }
        }
        .padding(.bottom, 14)
    }

    private var weeklyEstimate: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                Text("Your new daily target: ")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Text("\(formattedCalories(max(Int(vm.profile.bmr), resultingCalories))) cal")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: resultingCalories)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )
            )

            HStack(spacing: 8) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("~\(weeklyLoss) lbs/week")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("estimated loss")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.primaryAccent.opacity(0.06), in: Capsule())
        }
    }

    private func formattedCalories(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func deficitWarningBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isBelowMinimum ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isBelowMinimum ? Color(red: 1, green: 0.3, blue: 0.3) : AppTheme.warning)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(isBelowMinimum ? "Dangerously Low" : "High Deficit")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isBelowMinimum ? Color(red: 1, green: 0.3, blue: 0.3) : AppTheme.warning)
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill((isBelowMinimum ? Color(red: 1, green: 0.3, blue: 0.3) : AppTheme.warning).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder((isBelowMinimum ? Color(red: 1, green: 0.3, blue: 0.3) : AppTheme.warning).opacity(0.25), lineWidth: 1)
                )
        )
        .padding(.top, 10)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(duration: 0.35), value: currentDeficit)
    }

    private var confirmButton: some View {
        Button {
            guard isValid else { return }
            vm.profile.selectedCalorieDeficit = currentDeficit
            vm.profile.scanDeficit = currentDeficit
            vm.recalculateNutrition()
            vm.save()
            dismiss()
        } label: {
            Text("Set Deficit")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isValid ? AppTheme.primaryAccent : AppTheme.muted.opacity(0.4), in: Capsule())
                .shadow(color: isValid ? AppTheme.primaryAccent.opacity(0.4) : .clear, radius: 14, y: 5)
        }
        .disabled(!isValid)
        .padding(.top, 6)
    }
}
