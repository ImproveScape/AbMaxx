import SwiftUI

struct FoodDetailView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var entry: FoodEntry
    @State private var quantityText: String
    @State private var hasChanges: Bool = false
    @State private var aiHealthScore: Int?
    @State private var aiHealthLabel: String?
    @State private var aiHealthDescription: String?
    @State private var isEnriching: Bool = false
    @State private var showFullHealthScore: Bool = false

    private let brandRed = Color(red: 0.95, green: 0.23, blue: 0.15)
    private let brandOrange = Color(red: 1.0, green: 0.45, blue: 0.18)
    private let cardBg = Color(white: 0.1)
    private let cardRadius: CGFloat = 20

    init(viewModel: NutritionViewModel, entry: FoodEntry) {
        self.viewModel = viewModel
        self._entry = State(initialValue: entry)
        self._quantityText = State(initialValue: String(format: entry.quantity == floor(entry.quantity) ? "%.0f" : "%.1f", entry.quantity))
    }

    private var healthScore: Int {
        aiHealthScore ?? viewModel.healthScore(for: entry)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                calorieCard
                healthScoreCard
                macroBreakdownCard
                quantityCard
                micronutrientsCard
                deleteButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if hasChanges {
                    Button("Save") {
                        viewModel.updateFoodEntry(entry)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(brandRed)
                }
            }
        }
        .task {
            await enrichEntry()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(mealColor.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: entry.mealType.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(mealColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(entry.mealType.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(mealColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(mealColor.opacity(0.1))
                        .clipShape(Capsule())

                    Text(entry.servingSize)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Calorie Card

    private var calorieCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Calories")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.adjustedCalories)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    Text("kcal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: min(Double(entry.adjustedCalories) / Double(max(1, viewModel.dailyCalorieGoal)), 1.0))
                    .stroke(
                        AngularGradient(
                            colors: [brandOrange, brandRed, brandRed],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text("\(Int(Double(entry.adjustedCalories) / Double(max(1, viewModel.dailyCalorieGoal)) * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("daily")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(cardBg, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5))
    }

    // MARK: - Health Score

    private var healthScoreCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemFill), lineWidth: 6)
                        .frame(width: 64, height: 64)

                    if isEnriching && aiHealthScore == nil {
                        ProgressView()
                            .frame(width: 64, height: 64)
                    } else {
                        Circle()
                            .trim(from: 0, to: Double(healthScore) / 100.0)
                            .stroke(
                                scoreColor,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 64, height: 64)
                            .rotationEffect(.degrees(-90))

                        Text("\(healthScore)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreColor)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Score")
                        .font(.system(size: 17, weight: .semibold))

                    if isEnriching && aiHealthScore == nil {
                        Text("Analyzing...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(scoreLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(scoreColor)

                        if !showFullHealthScore {
                            Text(scoreDescription)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }

                Spacer()

                if !isEnriching || aiHealthScore != nil {
                    Button {
                        withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                            showFullHealthScore.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(showFullHealthScore ? 180 : 0))
                    }
                }
            }

            if showFullHealthScore {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .overlay(Color.white.opacity(0.06))
                        .padding(.top, 14)

                    Text(scoreDescription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    healthScoreBreakdown
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .padding(18)
        .background(cardBg, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5))
    }

    private var healthScoreBreakdown: some View {
        VStack(spacing: 8) {
            healthFactorRow(
                icon: "fork.knife",
                label: "Protein ratio",
                detail: proteinRatioDetail,
                isPositive: proteinRatioPositive
            )
            healthFactorRow(
                icon: "drop.fill",
                label: "Fat content",
                detail: fatContentDetail,
                isPositive: fatContentPositive
            )
            healthFactorRow(
                icon: "leaf.fill",
                label: "Fiber",
                detail: "\(String(format: "%.1f", entry.fiber))g per serving",
                isPositive: entry.fiber > 3
            )
            healthFactorRow(
                icon: "cube.fill",
                label: "Sugar",
                detail: "\(String(format: "%.1f", entry.sugar))g per serving",
                isPositive: entry.sugar < 10
            )
            healthFactorRow(
                icon: "bolt.fill",
                label: "Sodium",
                detail: "\(Int(entry.sodium))mg per serving",
                isPositive: entry.sodium < 600
            )
        }
    }

    private func healthFactorRow(icon: String, label: String, detail: String, isPositive: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isPositive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(isPositive ? .green : .orange)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var proteinRatioDetail: String {
        let totalCal = (entry.protein * 4) + (entry.carbs * 4) + (entry.fat * 9)
        guard totalCal > 0 else { return "No data" }
        let pct = Int((entry.protein * 4) / totalCal * 100)
        return "\(pct)% of calories from protein"
    }

    private var proteinRatioPositive: Bool {
        let totalCal = (entry.protein * 4) + (entry.carbs * 4) + (entry.fat * 9)
        guard totalCal > 0 else { return false }
        return (entry.protein * 4) / totalCal > 0.15
    }

    private var fatContentDetail: String {
        let totalCal = (entry.protein * 4) + (entry.carbs * 4) + (entry.fat * 9)
        guard totalCal > 0 else { return "No data" }
        let pct = Int((entry.fat * 9) / totalCal * 100)
        return "\(pct)% of calories from fat"
    }

    private var fatContentPositive: Bool {
        let totalCal = (entry.protein * 4) + (entry.carbs * 4) + (entry.fat * 9)
        guard totalCal > 0 else { return true }
        return (entry.fat * 9) / totalCal < 0.45
    }

    // MARK: - Macros

    private var macroBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macronutrients")
                .font(.system(size: 17, weight: .semibold))

            let totalGrams = entry.adjustedProtein + entry.adjustedCarbs + entry.adjustedFat
            let proteinPct = totalGrams > 0 ? entry.adjustedProtein / totalGrams : 0
            let carbsPct = totalGrams > 0 ? entry.adjustedCarbs / totalGrams : 0
            let fatPct = totalGrams > 0 ? entry.adjustedFat / totalGrams : 0

            GeometryReader { geo in
                HStack(spacing: 2) {
                    if proteinPct > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: max(4, geo.size.width * proteinPct))
                    }
                    if carbsPct > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(brandOrange)
                            .frame(width: max(4, geo.size.width * carbsPct))
                    }
                    if fatPct > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple)
                            .frame(width: max(4, geo.size.width * fatPct))
                    }
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())

            HStack(spacing: 0) {
                macroDetail(
                    label: "Protein",
                    value: entry.adjustedProtein,
                    color: .blue,
                    percentage: Int(proteinPct * 100)
                )
                Spacer()
                macroDetail(
                    label: "Carbs",
                    value: entry.adjustedCarbs,
                    color: brandOrange,
                    percentage: Int(carbsPct * 100)
                )
                Spacer()
                macroDetail(
                    label: "Fat",
                    value: entry.adjustedFat,
                    color: .purple,
                    percentage: Int(fatPct * 100)
                )
            }
        }
        .padding(18)
        .background(cardBg, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5))
    }

    private func macroDetail(label: String, value: Double, color: Color, percentage: Int) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(String(format: "%.1fg", value))
                .font(.system(size: 18, weight: .bold, design: .rounded))

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Text("\(percentage)%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Quantity

    private var quantityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Servings")
                .font(.system(size: 17, weight: .semibold))

            HStack(spacing: 16) {
                Button {
                    adjustQuantity(by: -0.5)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(entry.quantity > 0.5 ? brandRed : Color(.systemFill))
                }
                .disabled(entry.quantity <= 0.5)

                VStack(spacing: 2) {
                    TextField("1", text: $quantityText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .onChange(of: quantityText) { _, newValue in
                            if let val = Double(newValue), val > 0 {
                                entry.quantity = val
                                hasChanges = true
                            }
                        }
                    Text(entry.servingSize)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Button {
                    adjustQuantity(by: 0.5)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(brandRed)
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { preset in
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            entry.quantity = preset
                            quantityText = preset == floor(preset) ? String(format: "%.0f", preset) : String(format: "%.1f", preset)
                            hasChanges = true
                        }
                    } label: {
                        Text(preset == floor(preset) ? String(format: "%.0f", preset) : String(format: "%.1f", preset))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(entry.quantity == preset ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                if entry.quantity == preset {
                                    brandRed
                                } else {
                                    Color(.tertiarySystemGroupedBackground)
                                }
                            }
                            .clipShape(.rect(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(18)
        .background(cardBg, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5))
    }

    // MARK: - Micronutrients

    private var micronutrientsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Micronutrients")
                .font(.system(size: 17, weight: .semibold))

            VStack(spacing: 0) {
                microRow(icon: "leaf.fill", label: "Fiber", value: entry.fiber * entry.quantity, unit: "g", dailyValue: 28, color: .green)
                Divider().padding(.leading, 40)
                microRow(icon: "square.stack.fill", label: "Sugar", value: entry.sugar * entry.quantity, unit: "g", dailyValue: 50, color: .pink)
                Divider().padding(.leading, 40)
                microRow(icon: "drop.fill", label: "Sodium", value: entry.sodium * entry.quantity, unit: "mg", dailyValue: 2300, color: .orange)
                Divider().padding(.leading, 40)
                microRow(icon: "bolt.fill", label: "Potassium", value: entry.potassium * entry.quantity, unit: "mg", dailyValue: 4700, color: .teal)
                Divider().padding(.leading, 40)
                microRow(icon: "heart.fill", label: "Cholesterol", value: entry.cholesterol * entry.quantity, unit: "mg", dailyValue: 300, color: .red)
                Divider().padding(.leading, 40)
                microRow(icon: "eye.fill", label: "Vitamin A", value: entry.vitaminA * entry.quantity, unit: "mcg", dailyValue: 900, color: .yellow)
                Divider().padding(.leading, 40)
                microRow(icon: "sun.max.fill", label: "Vitamin C", value: entry.vitaminC * entry.quantity, unit: "mg", dailyValue: 90, color: .orange)
                Divider().padding(.leading, 40)
                microRow(icon: "shield.fill", label: "Calcium", value: entry.calcium * entry.quantity, unit: "mg", dailyValue: 1300, color: .gray)
                Divider().padding(.leading, 40)
                microRow(icon: "atom", label: "Iron", value: entry.iron * entry.quantity, unit: "mg", dailyValue: 18, color: .brown)
            }
        }
        .padding(18)
        .background(cardBg, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5))
    }

    private func microRow(icon: String, label: String, value: Double, unit: String, dailyValue: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.1))
                .clipShape(.rect(cornerRadius: 7))

            Text(label)
                .font(.system(size: 15))

            Spacer()

            let dvPercent = dailyValue > 0 ? Int((value / dailyValue) * 100) : 0

            HStack(spacing: 8) {
                Text(formatMicroValue(value, unit: unit))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("\(dvPercent)% DV")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 52, alignment: .trailing)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.removeFoodEntry(entry)
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                Text("Delete Entry")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.08))
            .clipShape(.rect(cornerRadius: 14))
        }
    }

    // MARK: - Helpers

    private func adjustQuantity(by amount: Double) {
        withAnimation(.spring(duration: 0.25)) {
            let newVal = max(0.5, entry.quantity + amount)
            entry.quantity = newVal
            quantityText = newVal == floor(newVal) ? String(format: "%.0f", newVal) : String(format: "%.1f", newVal)
            hasChanges = true
        }
    }

    private var mealColor: Color {
        switch entry.mealType {
        case .breakfast: brandOrange
        case .lunch: .green
        case .dinner: .blue
        case .snack: .purple
        case .preworkout: brandRed
        case .postworkout: .teal
        }
    }

    private var scoreColor: Color {
        if healthScore >= 75 { return .green }
        if healthScore >= 50 { return .yellow }
        if healthScore >= 25 { return .orange }
        return .red
    }

    private var scoreLabel: String {
        if let label = aiHealthLabel { return label }
        if healthScore >= 75 { return "Excellent" }
        if healthScore >= 50 { return "Good" }
        if healthScore >= 25 { return "Fair" }
        return "Poor"
    }

    private var scoreDescription: String {
        if let desc = aiHealthDescription { return desc }
        if healthScore >= 75 { return "Great nutritional balance for training" }
        if healthScore >= 50 { return "Decent choice, room for improvement" }
        if healthScore >= 25 { return "Consider healthier alternatives" }
        return "High in processed ingredients"
    }

    private func enrichEntry() async {
        isEnriching = true
        defer { isEnriching = false }

        let result = await viewModel.nutritionService.enrichFoodEntry(
            name: entry.name,
            calories: entry.calories,
            protein: entry.protein,
            carbs: entry.carbs,
            fat: entry.fat,
            servingSize: entry.servingSize
        )

        guard let result else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            aiHealthScore = result.healthScore
            aiHealthLabel = result.healthLabel
            aiHealthDescription = result.healthDescription
            entry.fiber = result.fiber
            entry.sugar = result.sugar
            entry.sodium = result.sodium
            entry.potassium = result.potassium
            entry.cholesterol = result.cholesterol
            entry.vitaminA = result.vitaminA
            entry.vitaminC = result.vitaminC
            entry.calcium = result.calcium
            entry.iron = result.iron
            entry.vitaminD = result.vitaminD ?? 0
            entry.vitaminE = result.vitaminE ?? 0
            entry.vitaminK = result.vitaminK ?? 0
            entry.vitaminB6 = result.vitaminB6 ?? 0
            entry.vitaminB12 = result.vitaminB12 ?? 0
            entry.folate = result.folate ?? 0
            entry.magnesium = result.magnesium ?? 0
            entry.zinc = result.zinc ?? 0
            entry.phosphorus = result.phosphorus ?? 0
            entry.thiamin = result.thiamin ?? 0
            entry.riboflavin = result.riboflavin ?? 0
            entry.niacin = result.niacin ?? 0
            entry.manganese = result.manganese ?? 0
            entry.selenium = result.selenium ?? 0
            entry.copper = result.copper ?? 0
            hasChanges = true
        }
    }

    private func formatMicroValue(_ value: Double, unit: String) -> String {
        if value == 0 { return "0\(unit)" }
        if value < 1 { return String(format: "%.1f%@", value, unit) }
        return "\(Int(value))\(unit)"
    }
}
