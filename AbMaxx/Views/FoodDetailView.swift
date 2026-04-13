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

    init(viewModel: NutritionViewModel, entry: FoodEntry) {
        self.viewModel = viewModel
        self._entry = State(initialValue: entry)
        self._quantityText = State(initialValue: String(format: entry.quantity == floor(entry.quantity) ? "%.0f" : "%.1f", entry.quantity))
    }

    private var healthScore: Int { aiHealthScore ?? viewModel.healthScore(for: entry) }

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
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                StandardBackgroundOrbs()
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if hasChanges {
                    Button("Save") { viewModel.updateFoodEntry(entry); dismiss() }
                        .font(.system(size: 16, weight: .semibold)).foregroundStyle(AppTheme.primaryAccent)
                }
            }
        }
        .task { await enrichEntry() }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.primaryAccent.opacity(0.12)).frame(width: 52, height: 52)
                Image(systemName: "fork.knife").font(.system(size: 22)).foregroundStyle(AppTheme.primaryAccent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name).font(.system(size: 20, weight: .bold)).foregroundStyle(AppTheme.primaryText).lineLimit(2)
                Text(entry.servingSize).font(.system(size: 13)).foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var calorieCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Calories").font(.system(size: 14, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.adjustedCalories)").font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.primaryText).contentTransition(.numericText())
                    Text("kcal").font(.system(size: 16, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                }
            }
            Spacer()
            ZStack {
                Circle().stroke(AppTheme.muted.opacity(0.3), lineWidth: 8).frame(width: 80, height: 80)
                Circle().trim(from: 0, to: min(Double(entry.adjustedCalories) / Double(max(1, viewModel.dailyCalorieGoal)), 1.0))
                    .stroke(AngularGradient(colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.6), AppTheme.primaryAccent], center: .center), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80).rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text("\(Int(Double(entry.adjustedCalories) / Double(max(1, viewModel.dailyCalorieGoal)) * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.primaryText)
                    Text("daily").font(.system(size: 9, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    private var healthScoreCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(AppTheme.muted.opacity(0.3), lineWidth: 6).frame(width: 64, height: 64)
                    if isEnriching && aiHealthScore == nil {
                        ProgressView().frame(width: 64, height: 64)
                    } else {
                        Circle().trim(from: 0, to: Double(healthScore) / 100.0)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 64, height: 64).rotationEffect(.degrees(-90))
                        Text("\(healthScore)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(scoreColor)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Score").font(.system(size: 17, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
                    if isEnriching && aiHealthScore == nil {
                        Text("Analyzing...").font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                    } else {
                        Text(scoreLabel).font(.system(size: 13, weight: .medium)).foregroundStyle(scoreColor)
                        if !showFullHealthScore {
                            Text(scoreDescription).font(.system(size: 12)).foregroundStyle(AppTheme.secondaryText).lineLimit(2)
                        }
                    }
                }
                Spacer()
                if !isEnriching || aiHealthScore != nil {
                    Button {
                        withAnimation(.spring(duration: 0.35, bounce: 0.15)) { showFullHealthScore.toggle() }
                    } label: {
                        Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.secondaryText)
                            .rotationEffect(.degrees(showFullHealthScore ? 180 : 0))
                    }
                }
            }
            if showFullHealthScore {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().overlay(AppTheme.border).padding(.top, 14)
                    Text(scoreDescription).font(.system(size: 14, weight: .medium)).foregroundStyle(AppTheme.secondaryText).fixedSize(horizontal: false, vertical: true)
                }
                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
            }
        }
        .padding(18)
        .cardStyle()
    }

    private var macroBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macronutrients").font(.system(size: 17, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
            let totalGrams = entry.adjustedProtein + entry.adjustedCarbs + entry.adjustedFat
            let proteinPct = totalGrams > 0 ? entry.adjustedProtein / totalGrams : 0
            let carbsPct = totalGrams > 0 ? entry.adjustedCarbs / totalGrams : 0
            let fatPct = totalGrams > 0 ? entry.adjustedFat / totalGrams : 0

            GeometryReader { geo in
                HStack(spacing: 2) {
                    if proteinPct > 0 { RoundedRectangle(cornerRadius: 4).fill(AppTheme.primaryAccent).frame(width: max(4, geo.size.width * proteinPct)) }
                    if carbsPct > 0 { RoundedRectangle(cornerRadius: 4).fill(AppTheme.success).frame(width: max(4, geo.size.width * carbsPct)) }
                    if fatPct > 0 { RoundedRectangle(cornerRadius: 4).fill(AppTheme.warning).frame(width: max(4, geo.size.width * fatPct)) }
                }
            }
            .frame(height: 10).clipShape(Capsule())

            HStack(spacing: 0) {
                macroDetail(label: "Protein", value: entry.adjustedProtein, color: AppTheme.primaryAccent, percentage: Int(proteinPct * 100))
                Spacer()
                macroDetail(label: "Carbs", value: entry.adjustedCarbs, color: AppTheme.success, percentage: Int(carbsPct * 100))
                Spacer()
                macroDetail(label: "Fat", value: entry.adjustedFat, color: AppTheme.warning, percentage: Int(fatPct * 100))
            }
        }
        .padding(18)
        .cardStyle()
    }

    private func macroDetail(label: String, value: Double, color: Color, percentage: Int) -> some View {
        VStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(String(format: "%.1fg", value)).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.primaryText)
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
            Text("\(percentage)%").font(.system(size: 11, weight: .semibold)).foregroundStyle(color)
        }
    }

    private var quantityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Servings").font(.system(size: 17, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
            HStack(spacing: 16) {
                Button { adjustQuantity(by: -0.5) } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 32)).foregroundStyle(entry.quantity > 0.5 ? AppTheme.primaryAccent : AppTheme.muted)
                }
                .disabled(entry.quantity <= 0.5)
                VStack(spacing: 2) {
                    TextField("1", text: $quantityText).font(.system(size: 28, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.primaryText)
                        .keyboardType(.decimalPad).frame(width: 80)
                        .onChange(of: quantityText) { _, newValue in
                            if let val = Double(newValue), val > 0 { entry.quantity = val; hasChanges = true }
                        }
                    Text(entry.servingSize).font(.system(size: 12)).foregroundStyle(AppTheme.secondaryText)
                }
                Button { adjustQuantity(by: 0.5) } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 32)).foregroundStyle(AppTheme.primaryAccent)
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
                            .foregroundStyle(entry.quantity == preset ? .white : AppTheme.primaryText)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background {
                                if entry.quantity == preset {
                                    RoundedRectangle(cornerRadius: 10).fill(AppTheme.primaryAccent)
                                } else {
                                    RoundedRectangle(cornerRadius: 10).fill(AppTheme.cardSurfaceElevated)
                                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AppTheme.border, lineWidth: 0.5))
                                }
                            }
                            .clipShape(.rect(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(18)
        .cardStyle()
    }

    private var micronutrientsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Micronutrients").font(.system(size: 17, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
            VStack(spacing: 0) {
                microRow(icon: "leaf.fill", label: "Fiber", value: entry.fiber * entry.quantity, unit: "g", dailyValue: 28, color: AppTheme.success)
                Divider().overlay(AppTheme.border).padding(.leading, 40)
                microRow(icon: "square.stack.fill", label: "Sugar", value: entry.sugar * entry.quantity, unit: "g", dailyValue: 50, color: .pink)
                Divider().overlay(AppTheme.border).padding(.leading, 40)
                microRow(icon: "drop.fill", label: "Sodium", value: entry.sodium * entry.quantity, unit: "mg", dailyValue: 2300, color: AppTheme.warning)
                Divider().overlay(AppTheme.border).padding(.leading, 40)
                microRow(icon: "bolt.fill", label: "Potassium", value: entry.potassium * entry.quantity, unit: "mg", dailyValue: 4700, color: .teal)
                Divider().overlay(AppTheme.border).padding(.leading, 40)
                microRow(icon: "heart.fill", label: "Cholesterol", value: entry.cholesterol * entry.quantity, unit: "mg", dailyValue: 300, color: AppTheme.destructive)
            }
        }
        .padding(18)
        .cardStyle()
    }

    private func microRow(icon: String, label: String, value: Double, unit: String, dailyValue: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(color)
                .frame(width: 26, height: 26).background(color.opacity(0.1)).clipShape(.rect(cornerRadius: 7))
            Text(label).font(.system(size: 15)).foregroundStyle(AppTheme.primaryText)
            Spacer()
            let dvPercent = dailyValue > 0 ? Int((value / dailyValue) * 100) : 0
            HStack(spacing: 8) {
                Text(formatMicroValue(value, unit: unit)).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(AppTheme.primaryText)
                Text("\(dvPercent)% DV").font(.system(size: 11, weight: .medium)).foregroundStyle(AppTheme.secondaryText).frame(width: 52, alignment: .trailing)
            }
        }
        .padding(.vertical, 10)
    }

    private var deleteButton: some View {
        Button(role: .destructive) { viewModel.removeFoodEntry(entry); dismiss() } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill").font(.system(size: 14))
                Text("Delete Entry").font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(AppTheme.destructive).frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(AppTheme.destructive.opacity(0.08)).clipShape(.rect(cornerRadius: 14))
        }
    }

    private func adjustQuantity(by amount: Double) {
        withAnimation(.spring(duration: 0.25)) {
            let newVal = max(0.5, entry.quantity + amount)
            entry.quantity = newVal
            quantityText = newVal == floor(newVal) ? String(format: "%.0f", newVal) : String(format: "%.1f", newVal)
            hasChanges = true
        }
    }

    private var scoreColor: Color {
        if healthScore >= 75 { return AppTheme.success }; if healthScore >= 50 { return AppTheme.warning }
        if healthScore >= 25 { return AppTheme.orange }; return AppTheme.destructive
    }

    private var scoreLabel: String {
        if let label = aiHealthLabel { return label }
        if healthScore >= 75 { return "Excellent" }; if healthScore >= 50 { return "Good" }
        if healthScore >= 25 { return "Fair" }; return "Poor"
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
            name: entry.name, calories: entry.calories, protein: entry.protein,
            carbs: entry.carbs, fat: entry.fat, servingSize: entry.servingSize
        )
        guard let result else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            aiHealthScore = result.healthScore
            aiHealthLabel = result.healthLabel
            aiHealthDescription = result.healthDescription
            entry.fiber = result.fiber; entry.sugar = result.sugar; entry.sodium = result.sodium
            entry.potassium = result.potassium; entry.cholesterol = result.cholesterol
            entry.vitaminA = result.vitaminA; entry.vitaminC = result.vitaminC
            entry.calcium = result.calcium; entry.iron = result.iron
            entry.vitaminD = result.vitaminD ?? 0; entry.magnesium = result.magnesium ?? 0
            entry.zinc = result.zinc ?? 0
            hasChanges = true
        }
    }

    private func formatMicroValue(_ value: Double, unit: String) -> String {
        if value == 0 { return "0\(unit)" }
        if value < 1 { return String(format: "%.1f%@", value, unit) }
        return "\(Int(value))\(unit)"
    }
}
