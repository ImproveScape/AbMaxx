import SwiftUI

struct NutritionSettingsView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    private let brandRed = BrandColors.red
    private let brandOrange = BrandColors.orange

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
                    sourcesAndCitationsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 60)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Color.black)
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.applyNutritionGoals()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(brandOrange)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Calorie Preview

    private var caloriePreviewCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DAILY TARGET")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(1.2)

                    Text("\(viewModel.nutritionGoals.calculatedCalorieGoal)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("calories / day")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    macroPill(label: "Protein", value: "\(Int(viewModel.nutritionGoals.calculatedProteinGoal))g", color: brandRed)
                    macroPill(label: "Carbs", value: "\(Int(viewModel.nutritionGoals.calculatedCarbsGoal))g", color: brandOrange)
                    macroPill(label: "Fat", value: "\(Int(viewModel.nutritionGoals.calculatedFatGoal))g", color: Color(red: 0.45, green: 0.55, blue: 0.95))
                }
            }

            if let weeks = viewModel.nutritionGoals.weeksToGoal {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12))
                        .foregroundStyle(brandOrange)
                    Text("~\(weeks) weeks to reach \(Int(viewModel.nutritionGoals.targetWeightLbs)) lbs")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                .padding(.top, 14)
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                Text("Mifflin-St Jeor \u{2022} BMR: \(Int(viewModel.nutritionGoals.bmr)) \u{2022} TDEE: \(Int(viewModel.nutritionGoals.tdee))")
                    .font(.system(size: 10, weight: .medium))
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.3))
            .padding(.top, 12)
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            brandRed.opacity(0.25),
                            brandOrange.opacity(0.12),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            LinearGradient(
                                colors: [brandRed.opacity(0.4), brandOrange.opacity(0.15), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .animation(.spring(duration: 0.3), value: viewModel.nutritionGoals.calculatedCalorieGoal)
    }

    private func macroPill(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.15), lineWidth: 0.5))
    }

    // MARK: - Body Stats

    private var bodyStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "figure.stand", title: "Body Stats")

            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    inputField(label: "Age", icon: "calendar") {
                        HStack(spacing: 4) {
                            TextField("", value: $viewModel.nutritionGoals.age, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .frame(width: 44)
                            Text("yrs")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sex")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack(spacing: 0) {
                            ForEach(BiologicalSex.allCases, id: \.self) { sex in
                                Button {
                                    withAnimation(.spring(duration: 0.25)) {
                                        viewModel.nutritionGoals.sex = sex
                                    }
                                } label: {
                                    Text(sex.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(viewModel.nutritionGoals.sex == sex ? .white : .secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .background {
                                            if viewModel.nutritionGoals.sex == sex {
                                                Capsule().fill(brandRed.gradient)
                                            }
                                        }
                                }
                            }
                        }
                        .background(Color.white.opacity(0.06), in: Capsule())
                    }
                }

                inputField(label: "Weight", icon: "scalemass.fill") {
                    HStack(spacing: 2) {
                        TextField("", value: $viewModel.nutritionGoals.weightLbs, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("lbs")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                inputField(label: "Height", icon: "ruler") {
                    HStack(spacing: 4) {
                        Menu {
                            Picker("", selection: $viewModel.nutritionGoals.heightFeet) {
                                ForEach(4...7, id: \.self) { ft in
                                    Text("\(ft)").tag(ft)
                                }
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text("\(viewModel.nutritionGoals.heightFeet)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("ft")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Menu {
                            Picker("", selection: $viewModel.nutritionGoals.heightInches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch)").tag(inch)
                                }
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text("\(viewModel.nutritionGoals.heightInches)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("in")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .polishedCard(cornerRadius: 22)
    }

    // MARK: - Activity Level

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "figure.run", title: "Activity Level")

            VStack(spacing: 4) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    let isSelected = viewModel.nutritionGoals.activityLevel == level
                    Button {
                        withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                            viewModel.nutritionGoals.activityLevel = level
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(isSelected ? brandOrange : .clear)
                                .frame(width: 8, height: 8)
                                .padding(4)
                                .overlay(
                                    Circle()
                                        .strokeBorder(isSelected ? brandOrange : Color.white.opacity(0.2), lineWidth: 1.5)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.rawValue)
                                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                Text(level.detail)
                                    .font(.system(size: 12))
                                    .foregroundStyle(isSelected ? brandOrange.opacity(0.8) : .secondary)
                            }

                            Spacer()

                            Text("x\(level.multiplier, specifier: "%.2f")")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(isSelected ? AnyShapeStyle(brandOrange) : AnyShapeStyle(.tertiary))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    (isSelected ? brandOrange : Color.white).opacity(0.08),
                                    in: .rect(cornerRadius: 6)
                                )
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(brandOrange.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(brandOrange.opacity(0.25), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .sensoryFeedback(.selection, trigger: viewModel.nutritionGoals.activityLevel)
                }
            }
        }
        .padding(20)
        .polishedCard(cornerRadius: 22)
    }

    // MARK: - Weight Goal

    private var weightGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "target", title: "Weight Goal")
            weightGoalTypePicker
            if viewModel.nutritionGoals.weightGoalType != .maintain {
                weightGoalDetails
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .polishedCard(cornerRadius: 22)
        .animation(.spring(duration: 0.35), value: viewModel.nutritionGoals.weightGoalType)
    }

    private var weightGoalTypePicker: some View {
        HStack(spacing: 8) {
            ForEach(WeightGoalType.allCases, id: \.self) { goalType in
                let isSelected = viewModel.nutritionGoals.weightGoalType == goalType
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        viewModel.nutritionGoals.weightGoalType = goalType
                    }
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: goalType.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(isSelected ? brandOrange : .secondary)
                            .symbolEffect(.bounce, value: isSelected)
                        Text(goalType.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isSelected ? .white : .secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isSelected ? brandOrange.opacity(0.12) : Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        isSelected ? brandOrange.opacity(0.35) : Color.white.opacity(0.06),
                                        lineWidth: isSelected ? 1 : 0.5
                                    )
                            )
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
                    TextField("", value: $viewModel.nutritionGoals.targetWeightLbs, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("lbs")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("WEEKLY RATE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(WeeklyWeightChange.allCases) { rate in
                            rateChip(for: rate)
                        }
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
            withAnimation(.spring(duration: 0.25)) {
                viewModel.nutritionGoals.weeklyChange = rate
            }
        } label: {
            VStack(spacing: 4) {
                Text(rate.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                Text("\(prefix)\(rate.dailyCalorieAdjustment) cal")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule().fill(brandRed.gradient)
                } else {
                    Capsule().fill(Color.white.opacity(0.05))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5))
                }
            }
        }
    }

    // MARK: - Macro Override

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
                        Text("Reset")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(brandRed)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(brandRed.opacity(0.1), in: Capsule())
                    }
                }
            }

            Text("Auto-calculated from your stats. Tap to override.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary.opacity(0.7))

            VStack(spacing: 8) {
                macroRow(label: "Calories", unit: "cal", color: brandOrange, binding: calorieBinding)
                macroRow(label: "Protein", unit: "g", color: brandRed, binding: proteinBinding)
                macroRow(label: "Carbs", unit: "g", color: brandOrange, binding: carbsBinding)
                macroRow(label: "Fat", unit: "g", color: Color(red: 0.45, green: 0.55, blue: 0.95), binding: fatBinding)
            }
        }
        .padding(20)
        .polishedCard(cornerRadius: 22)
    }

    private var hasCustomMacros: Bool {
        viewModel.nutritionGoals.customCalorieGoal != nil ||
        viewModel.nutritionGoals.customProteinGoal != nil ||
        viewModel.nutritionGoals.customCarbsGoal != nil ||
        viewModel.nutritionGoals.customFatGoal != nil
    }

    private var calorieBinding: Binding<Int> {
        Binding(
            get: { viewModel.nutritionGoals.customCalorieGoal ?? viewModel.nutritionGoals.calculatedCalorieGoal },
            set: { viewModel.nutritionGoals.customCalorieGoal = $0 }
        )
    }

    private var proteinBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.nutritionGoals.customProteinGoal ?? viewModel.nutritionGoals.calculatedProteinGoal) },
            set: { viewModel.nutritionGoals.customProteinGoal = Double($0) }
        )
    }

    private var carbsBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.nutritionGoals.customCarbsGoal ?? viewModel.nutritionGoals.calculatedCarbsGoal) },
            set: { viewModel.nutritionGoals.customCarbsGoal = Double($0) }
        )
    }

    private var fatBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.nutritionGoals.customFatGoal ?? viewModel.nutritionGoals.calculatedFatGoal) },
            set: { viewModel.nutritionGoals.customFatGoal = Double($0) }
        )
    }

    private func macroRow(label: String, unit: String, color: Color, binding: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.gradient)
                .frame(width: 3, height: 28)

            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 2) {
                TextField("", value: binding, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(width: 70)
                Text(unit)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.03), in: .rect(cornerRadius: 14))
    }

    // MARK: - Hydration

    private var hydrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "drop.fill", title: "Hydration Goal")

            inputField(label: "Daily Water", icon: "drop.fill") {
                HStack(spacing: 2) {
                    TextField("", value: $viewModel.nutritionGoals.waterGoalOz, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("oz")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .polishedCard(cornerRadius: 22)
    }

    // MARK: - Sources & Citations

    private var sourcesAndCitationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "book.closed.fill", title: "Sources & Citations")

            Text("All calculations and nutritional data in this app are based on peer-reviewed research and established health guidelines.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                citationRow(
                    title: "Mifflin-St Jeor Equation",
                    detail: "Used to calculate your Basal Metabolic Rate (BMR). Considered the most accurate predictive equation for estimating resting energy expenditure.",
                    source: "Mifflin MD, St Jeor ST, et al. \"A new predictive equation for resting energy expenditure in healthy individuals.\" American Journal of Clinical Nutrition, 1990; 51(2):241-7.",
                    isLast: false
                )

                citationRow(
                    title: "TDEE Activity Multipliers",
                    detail: "Activity level multipliers (1.2–1.9) applied to BMR to estimate Total Daily Energy Expenditure.",
                    source: "Harris JA, Benedict FG. \"A Biometric Study of Basal Metabolism in Man.\" Carnegie Institution of Washington, 1919. Revised activity factors from WHO/FAO/UNU Expert Consultation, 2001.",
                    isLast: false
                )

                citationRow(
                    title: "Macronutrient Distribution",
                    detail: "Default macro split: 30% protein, 40% carbs, 30% fat — optimized for active individuals and combat athletes.",
                    source: "Institute of Medicine. \"Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids.\" National Academies Press, 2005. ISSN Position Stand on Diets and Body Composition, JISSN 2017.",
                    isLast: false
                )

                citationRow(
                    title: "Caloric Deficit / Surplus",
                    detail: "Weight change estimates based on ~3,500 calories per pound of body weight, adjusted by weekly rate selection.",
                    source: "Hall KD, et al. \"Quantification of the effect of energy imbalance on bodyweight.\" The Lancet, 2011; 378(9793):826-837. Wishnofsky M. \"Caloric equivalents of gained or lost weight.\" AJCN, 1958.",
                    isLast: false
                )

                citationRow(
                    title: "Food Nutrition Data",
                    detail: "AI-powered food search references USDA FoodData Central values. Barcode scanning uses the Open Food Facts database.",
                    source: "USDA FoodData Central (fdc.nal.usda.gov). Open Food Facts (openfoodfacts.org) — open-source collaborative food products database.",
                    isLast: false
                )

                citationRow(
                    title: "Hydration Guidelines",
                    detail: "Default 128 oz (1 gallon) daily target based on recommendations for active individuals and athletes.",
                    source: "National Academies of Sciences. \"Dietary Reference Intakes for Water, Potassium, Sodium, Chloride, and Sulfate.\" 2005. ACSM Position Stand on Exercise and Fluid Replacement, 2007.",
                    isLast: true
                )
            }
            .clipShape(.rect(cornerRadius: 14))

            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow.opacity(0.8))
                Text("This app provides estimates for informational purposes only and is not a substitute for professional medical or dietary advice. Consult a healthcare provider before making significant changes to your diet.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.yellow.opacity(0.04), in: .rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.yellow.opacity(0.08), lineWidth: 0.5)
            )
        }
        .padding(20)
        .polishedCard(cornerRadius: 22)
    }

    private func citationRow(title: String, detail: String, source: String, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(source)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(brandOrange.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.03))
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 0.5)
            }
        }
    }

    // MARK: - Components

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(brandOrange)
                .frame(width: 28, height: 28)
                .background(brandOrange.opacity(0.12), in: .rect(cornerRadius: 8))
            Text(title)
                .font(.system(size: 18, weight: .bold))
        }
    }

    private func inputField<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            content()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }
}
