import SwiftUI

struct NutritionSettingsView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    caloriePreviewCard
                    bodyStatsSection
                    activitySection
                    weightGoalSection
                    macroOverrideSection
                    hydrationSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 60)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background {
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    StandardBackgroundOrbs()
                }
            }
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.secondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.applyNutritionGoals()
                        dismiss()
                    } label: {
                        Text("Save").font(.system(size: 16, weight: .semibold)).foregroundStyle(AppTheme.primaryAccent)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var caloriePreviewCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DAILY TARGET").font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.5)).tracking(1.2)
                    Text("\(viewModel.nutritionGoals.calculatedCalorieGoal)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded)).foregroundStyle(.white).contentTransition(.numericText())
                    Text("calories / day").font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    macroPill(label: "Protein", value: "\(Int(viewModel.nutritionGoals.calculatedProteinGoal))g", color: AppTheme.primaryAccent)
                    macroPill(label: "Carbs", value: "\(Int(viewModel.nutritionGoals.calculatedCarbsGoal))g", color: AppTheme.success)
                    macroPill(label: "Fat", value: "\(Int(viewModel.nutritionGoals.calculatedFatGoal))g", color: AppTheme.warning)
                }
            }

            if let weeks = viewModel.nutritionGoals.weeksToGoal {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock").font(.system(size: 12)).foregroundStyle(AppTheme.primaryAccent)
                    Text("~\(weeks) weeks to reach \(Int(viewModel.nutritionGoals.targetWeightLbs)) lbs")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                .padding(.top, 14)
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle").font(.system(size: 10))
                Text("Mifflin-St Jeor \u{2022} BMR: \(Int(viewModel.nutritionGoals.bmr)) \u{2022} TDEE: \(Int(viewModel.nutritionGoals.tdee))")
                    .font(.system(size: 10, weight: .medium))
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.3))
            .padding(.top, 12)
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 22).fill(
                LinearGradient(colors: [AppTheme.primaryAccent.opacity(0.25), AppTheme.primaryAccent.opacity(0.12), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(
                LinearGradient(colors: [AppTheme.primaryAccent.opacity(0.4), AppTheme.primaryAccent.opacity(0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1
            ))
        }
        .animation(.spring(duration: 0.3), value: viewModel.nutritionGoals.calculatedCalorieGoal)
    }

    private func macroPill(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.5))
            Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.15), lineWidth: 0.5))
    }

    private var bodyStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "figure.stand", title: "Body Stats")
            VStack(spacing: 10) {
                inputField(label: "Age", icon: "calendar") {
                    HStack(spacing: 4) {
                        TextField("", value: $viewModel.nutritionGoals.age, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            .font(.system(size: 18, weight: .bold, design: .rounded)).frame(width: 44)
                        Text("yrs").font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText).fixedSize()
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sex").font(.system(size: 11, weight: .semibold)).foregroundStyle(AppTheme.secondaryText).textCase(.uppercase).tracking(0.5)
                    HStack(spacing: 0) {
                        ForEach(BiologicalSex.allCases, id: \.self) { sex in
                            Button {
                                withAnimation(.spring(duration: 0.25)) { viewModel.nutritionGoals.sex = sex }
                            } label: {
                                Text(sex.rawValue).font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(viewModel.nutritionGoals.sex == sex ? .white : AppTheme.secondaryText)
                                    .frame(maxWidth: .infinity).padding(.vertical, 11)
                                    .background { if viewModel.nutritionGoals.sex == sex { Capsule().fill(AppTheme.primaryAccent.gradient) } }
                            }
                        }
                    }
                    .background(AppTheme.border, in: Capsule())
                }
                inputField(label: "Weight", icon: "scalemass.fill") {
                    HStack(spacing: 2) {
                        TextField("", value: $viewModel.nutritionGoals.weightLbs, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("lbs").font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                    }
                }
                inputField(label: "Height", icon: "ruler") {
                    HStack(spacing: 4) {
                        Menu {
                            Picker("", selection: $viewModel.nutritionGoals.heightFeet) {
                                ForEach(4...7, id: \.self) { ft in Text("\(ft)").tag(ft) }
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text("\(viewModel.nutritionGoals.heightFeet)").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.primaryText)
                                Text("ft").font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        Menu {
                            Picker("", selection: $viewModel.nutritionGoals.heightInches) {
                                ForEach(0...11, id: \.self) { inch in Text("\(inch)").tag(inch) }
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text("\(viewModel.nutritionGoals.heightInches)").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.primaryText)
                                Text("in").font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "figure.run", title: "Activity Level")
            VStack(spacing: 4) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    let isSelected = viewModel.nutritionGoals.activityLevel == level
                    Button {
                        withAnimation(.spring(duration: 0.3, bounce: 0.15)) { viewModel.nutritionGoals.activityLevel = level }
                    } label: {
                        HStack(spacing: 14) {
                            Circle().fill(isSelected ? AppTheme.primaryAccent : .clear).frame(width: 8, height: 8).padding(4)
                                .overlay(Circle().strokeBorder(isSelected ? AppTheme.primaryAccent : AppTheme.muted, lineWidth: 1.5))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.rawValue).font(.system(size: 15, weight: isSelected ? .bold : .medium)).foregroundStyle(isSelected ? AppTheme.primaryText : AppTheme.primaryText)
                                Text(level.detail).font(.system(size: 12)).foregroundStyle(isSelected ? AppTheme.primaryAccent.opacity(0.8) : AppTheme.secondaryText)
                            }
                            Spacer()
                            Text("x\(level.multiplier, specifier: "%.2f")")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(isSelected ? AnyShapeStyle(AppTheme.primaryAccent) : AnyShapeStyle(AppTheme.muted))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background((isSelected ? AppTheme.primaryAccent : Color.white).opacity(0.08), in: .rect(cornerRadius: 6))
                        }
                        .padding(.vertical, 12).padding(.horizontal, 14)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14).fill(AppTheme.primaryAccent.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppTheme.blueBorder, lineWidth: 0.5))
                            }
                        }
                    }
                    .sensoryFeedback(.selection, trigger: viewModel.nutritionGoals.activityLevel)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    private var weightGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "target", title: "Weight Goal")
            weightGoalTypePicker
            if viewModel.nutritionGoals.weightGoalType != .maintain {
                weightGoalDetails.transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .cardStyle()
        .animation(.spring(duration: 0.35), value: viewModel.nutritionGoals.weightGoalType)
    }

    private var weightGoalTypePicker: some View {
        HStack(spacing: 8) {
            ForEach(WeightGoalType.allCases, id: \.self) { goalType in
                let isSelected = viewModel.nutritionGoals.weightGoalType == goalType
                Button {
                    withAnimation(.spring(duration: 0.25)) { viewModel.nutritionGoals.weightGoalType = goalType }
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: goalType.icon).font(.system(size: 24)).foregroundStyle(isSelected ? AppTheme.primaryAccent : AppTheme.secondaryText)
                            .symbolEffect(.bounce, value: isSelected)
                        Text(goalType.rawValue).font(.system(size: 11, weight: .bold)).foregroundStyle(isSelected ? AppTheme.primaryText : AppTheme.secondaryText).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16).fill(isSelected ? AppTheme.primaryAccent.opacity(0.12) : AppTheme.border)
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(isSelected ? AppTheme.blueBorder : AppTheme.border, lineWidth: isSelected ? 1 : 0.5))
                    }
                }
                .sensoryFeedback(.selection, trigger: viewModel.nutritionGoals.weightGoalType)
            }
        }
    }

    private var weightGoalDetails: some View {
        VStack(spacing: 12) {
            inputField(label: "Target Weight", icon: "flag.fill") {
                HStack(spacing: 2) {
                    TextField("", value: $viewModel.nutritionGoals.targetWeightLbs, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("lbs").font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("WEEKLY RATE").font(.system(size: 11, weight: .bold)).foregroundStyle(AppTheme.secondaryText).tracking(0.5)
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(WeeklyWeightChange.allCases) { rate in rateChip(for: rate) }
                    }
                }
                .contentMargins(.horizontal, 0)
                .scrollIndicators(.hidden)
            }
        }
    }

    private func rateChip(for rate: WeeklyWeightChange) -> some View {
        let isSelected = viewModel.nutritionGoals.weeklyChange == rate
        let prefix = viewModel.nutritionGoals.weightGoalType == .cut ? "-" : "+"
        return Button {
            withAnimation(.spring(duration: 0.25)) { viewModel.nutritionGoals.weeklyChange = rate }
        } label: {
            VStack(spacing: 4) {
                Text(rate.rawValue).font(.system(size: 12, weight: .bold)).foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                Text("\(prefix)\(rate.dailyCalorieAdjustment) cal").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(isSelected ? .white.opacity(0.7) : AppTheme.muted)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background {
                if isSelected { Capsule().fill(AppTheme.primaryAccent.gradient) }
                else { Capsule().fill(AppTheme.border).overlay(Capsule().strokeBorder(AppTheme.border, lineWidth: 0.5)) }
            }
        }
    }

    private var macroOverrideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(icon: "chart.pie.fill", title: "Macro Targets")
                Spacer()
                if hasCustomMacros {
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            viewModel.nutritionGoals.customCalorieGoal = nil
                            viewModel.nutritionGoals.customProteinGoal = nil
                            viewModel.nutritionGoals.customCarbsGoal = nil
                            viewModel.nutritionGoals.customFatGoal = nil
                        }
                    } label: {
                        Text("Reset").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.primaryAccent)
                            .padding(.horizontal, 12).padding(.vertical, 5).background(AppTheme.primaryAccent.opacity(0.1), in: Capsule())
                    }
                }
            }
            Text("Auto-calculated from your stats. Tap to override.").font(.system(size: 12)).foregroundStyle(AppTheme.muted)
            VStack(spacing: 8) {
                macroRow(label: "Calories", unit: "cal", color: AppTheme.primaryAccent, binding: calorieBinding)
                macroRow(label: "Protein", unit: "g", color: AppTheme.primaryAccent, binding: proteinBinding)
                macroRow(label: "Carbs", unit: "g", color: AppTheme.success, binding: carbsBinding)
                macroRow(label: "Fat", unit: "g", color: AppTheme.warning, binding: fatBinding)
            }
        }
        .padding(20)
        .cardStyle()
    }

    private var hasCustomMacros: Bool {
        viewModel.nutritionGoals.customCalorieGoal != nil || viewModel.nutritionGoals.customProteinGoal != nil ||
        viewModel.nutritionGoals.customCarbsGoal != nil || viewModel.nutritionGoals.customFatGoal != nil
    }

    private var calorieBinding: Binding<Int> {
        Binding(get: { viewModel.nutritionGoals.customCalorieGoal ?? viewModel.nutritionGoals.calculatedCalorieGoal }, set: { viewModel.nutritionGoals.customCalorieGoal = $0 })
    }
    private var proteinBinding: Binding<Int> {
        Binding(get: { Int(viewModel.nutritionGoals.customProteinGoal ?? viewModel.nutritionGoals.calculatedProteinGoal) }, set: { viewModel.nutritionGoals.customProteinGoal = Double($0) })
    }
    private var carbsBinding: Binding<Int> {
        Binding(get: { Int(viewModel.nutritionGoals.customCarbsGoal ?? viewModel.nutritionGoals.calculatedCarbsGoal) }, set: { viewModel.nutritionGoals.customCarbsGoal = Double($0) })
    }
    private var fatBinding: Binding<Int> {
        Binding(get: { Int(viewModel.nutritionGoals.customFatGoal ?? viewModel.nutritionGoals.calculatedFatGoal) }, set: { viewModel.nutritionGoals.customFatGoal = Double($0) })
    }

    private func macroRow(label: String, unit: String, color: Color, binding: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2).fill(color.gradient).frame(width: 3, height: 28)
            Text(label).font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
            Spacer()
            HStack(spacing: 2) {
                TextField("", value: binding, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    .font(.system(size: 18, weight: .bold, design: .rounded)).frame(width: 70)
                Text(unit).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.vertical, 10).padding(.horizontal, 14)
        .background(AppTheme.cardSurfaceElevated.opacity(0.5), in: .rect(cornerRadius: 14))
    }

    private var hydrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "drop.fill", title: "Hydration Goal")
            inputField(label: "Daily Water", icon: "drop.fill") {
                HStack(spacing: 2) {
                    TextField("", value: $viewModel.nutritionGoals.waterGoalOz, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("oz").font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(AppTheme.primaryAccent)
                .frame(width: 28, height: 28).background(AppTheme.primaryAccent.opacity(0.12), in: .rect(cornerRadius: 8))
            Text(title).font(.system(size: 18, weight: .bold)).foregroundStyle(AppTheme.primaryText)
        }
    }

    private func inputField<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText).frame(width: 22)
            Text(label).font(.system(size: 15, weight: .medium)).foregroundStyle(AppTheme.primaryText)
            Spacer()
            content()
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .background(AppTheme.cardSurfaceElevated.opacity(0.5), in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppTheme.border, lineWidth: 0.5))
    }
}
