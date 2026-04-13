import SwiftUI

struct NutritionView: View {
    @Bindable var vm: AppViewModel
    @State private var viewModel = NutritionViewModel()
    @State private var appeared: Bool = false
    @State private var dataLoaded: Bool = false
    @State private var ringAnimation: Bool = false
    @State private var waterDrop: Int = 0
    @State private var showingAddMenu: Bool = false
    @State private var showingVoiceLog: Bool = false
    @State private var showingFuelCamera: Bool = false
    @State private var fuelCapturedImage: UIImage?
    @State private var showingBarcodeScanner: Bool = false
    @State private var scanPulse: Bool = false
    @State private var showDeficitPicker: Bool = false
    @State private var macroPageIndex: Int = 0
    @State private var cupScales: [Int: CGFloat] = [:]
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    fuelHeader
                    nutritionContent
                }
                .premiumBackground()

                if showingAddMenu {
                    Color(hex: "0D0D0D").opacity(0.85)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                                showingAddMenu = false
                            }
                        }
                        .transition(.opacity)
                }

                if dataLoaded {
                    addMenuOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .navigationDestination(for: UUID.self) { entryId in
                if let entry = viewModel.todayNutrition.entries.first(where: { $0.id == entryId }) {
                    FoodDetailView(viewModel: viewModel, entry: entry)
                }
            }
            .sheet(isPresented: $viewModel.showingAddFood) {
                AddFoodView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showingFuelCamera, onDismiss: {
                guard let img = fuelCapturedImage else { return }
                Task {
                    guard let compressed = img.jpegData(compressionQuality: 0.6) else { return }
                    await viewModel.analyzeFoodImageInline(compressed, mealType: .lunch)
                }
            }) {
                FuelCameraView(capturedImage: $fuelCapturedImage)
            }
            .fullScreenCover(isPresented: $viewModel.showingFoodScanner) {
                FoodScannerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingVoiceLog) {
                VoiceLogView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingNutritionSettings) {
                NutritionSettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showDeficitPicker) {
                CalorieDeficitPickerSheet(vm: vm)
                    .presentationDetents([.height(520), .large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
            .task {
                viewModel.loadData()
                viewModel.onFoodAdded = { totalMeals, foodName in
                    vm.onNutritionFoodAdded(totalMeals, foodName: foodName)
                }
                viewModel.onWaterChanged = { glasses in
                    vm.syncWaterFromNutrition(glasses)
                }
                viewModel.onMacroExceeded = { macroName, overBy in
                    vm.triggerMacroOverToast(macroName: macroName, overByAmount: overBy)
                }
                viewModel.syncFromProfile(vm.profile)
                withAnimation(.spring(response: 0.6)) {
                    appeared = true
                    dataLoaded = true
                }
                withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                    ringAnimation = true
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.onForeground()
                }
            }
            .onChange(of: vm.profile.selectedCalorieDeficit) { _, _ in
                withAnimation(.spring(duration: 0.4)) {
                    viewModel.syncFromProfile(vm.profile)
                }
            }
        }
    }

    private var fuelHeader: some View {
        HStack(alignment: .center) {
            Text("Nutrition")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.white)

            Spacer()

            deficitButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var deficitButton: some View {
        Button {
            showDeficitPicker = true
        } label: {
            let deficit = vm.profile.scanDeficit ?? vm.profile.selectedCalorieDeficit
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("-\(deficit)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("cal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.primaryAccent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(hex: "0A1428"))
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    AppTheme.primaryAccent.opacity(0.25),
                    lineWidth: 1
                )
            )
        }
    }

    private var nutritionContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                if dataLoaded {
                    weeklyCalendarStrip
                    caloriesHeroCard
                    macroTabView
                    macroPageDots
                    todaysMealsSection
                } else {
                    ProgressView()
                        .tint(AppTheme.primaryAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Weekly Calendar Strip

    private var weeklyCalendarStrip: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.weekDays.enumerated()), id: \.offset) { index, day in
                let isSelected = index == viewModel.selectedDayIndex

                Button {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                        viewModel.selectedDayIndex = index
                        viewModel.loadNutritionForDay(at: index)
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(day.shortName.prefix(1).uppercased())
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)

                        Text("\(day.dayNumber)")
                            .font(.system(size: 18, weight: isSelected ? .bold : .semibold, design: .default))
                            .foregroundStyle(isSelected ? .white : AppTheme.primaryText)
                    }
                    .frame(width: 44, height: 70)
                    .background(isSelected ? AppTheme.primaryAccent : Color.white.opacity(0.06), in: .rect(cornerRadius: 14))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    // MARK: - Calories Hero Card

    private var caloriesHeroCard: some View {
        let displayLog = viewModel.nutritionForSelectedDay(at: viewModel.selectedDayIndex)
        let totalCal = displayLog.totalCalories
        let goal = viewModel.dailyCalorieGoal
        let remaining = max(0, goal - totalCal)
        let progress = goal > 0 ? min(Double(totalCal) / Double(goal), 1.0) : 0
        let safeProgress = (progress.isNaN || progress.isInfinite) ? 0 : progress

        return VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedCalories(remaining))
                        .font(.system(size: 52, weight: .heavy))
                        .tracking(-0.03 * 52)
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("Calories remaining")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "8E8E93"))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    Circle()
                        .stroke(Color(hex: "0066FF").opacity(0.10), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: ringAnimation ? safeProgress : 0)
                        .stroke(Color(hex: "0066FF"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color(hex: "0066FF").opacity(0.65), radius: 14, x: 0, y: 0)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: "0066FF"))
                }
                .frame(width: 80, height: 80)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule().fill(Color(hex: "0066FF"))
                        .frame(width: max(2, geo.size.width * (ringAnimation ? safeProgress : 0)))
                        .shadow(color: Color(hex: "0066FF").opacity(0.50), radius: 8, x: 0, y: 0)
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())

            HStack {
                Text("\(totalCal) eaten")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "636366"))
                Spacer()
                Text("\(formattedCalories(goal)) goal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "636366"))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05), in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    // MARK: - Macro TabView (3 Pages)

    private var macroTabView: some View {
        TabView(selection: $macroPageIndex) {
            macrosRingPage.tag(0)
            micronutrientsPage.tag(1)
            waterPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 200)
    }

    private var macroPageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(macroPageIndex == index ? Color(hex: "0066FF") : Color.white.opacity(0.20))
                    .frame(width: macroPageIndex == index ? 8 : 6, height: macroPageIndex == index ? 8 : 6)
                    .shadow(color: macroPageIndex == index ? Color(hex: "0066FF").opacity(0.55) : .clear, radius: 6, x: 0, y: 0)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: macroPageIndex)
    }

    // MARK: - Page 1: Macros Ring Page

    private var macrosRingPage: some View {
        let displayLog = viewModel.nutritionForSelectedDay(at: viewModel.selectedDayIndex)

        return HStack(spacing: 8) {
            macroRingCard(
                name: "PROTEIN",
                current: displayLog.totalProtein,
                goal: viewModel.proteinGoal,
                accentColor: Color(hex: "0066FF"),
                iconName: "figure.strengthtraining.traditional"
            )
            macroRingCard(
                name: "CARBS",
                current: displayLog.totalCarbs,
                goal: viewModel.carbsGoal,
                accentColor: Color(hex: "FF9F0A"),
                iconName: "flame.fill"
            )
            macroRingCard(
                name: "FAT",
                current: displayLog.totalFat,
                goal: viewModel.fatGoal,
                accentColor: Color(hex: "BF5AF2"),
                iconName: "chart.pie.fill"
            )
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }

    private func macroRingCard(name: String, current: Double, goal: Double, accentColor: Color, iconName: String) -> some View {
        let remaining = max(0, goal - current)
        let ratio = goal > 0 ? current / goal : 0
        let safeRatio = (ratio.isNaN || ratio.isInfinite) ? 0 : ratio
        let clampedRatio = min(safeRatio, 1.0)
        let exceeded = safeRatio > 1.0
        let ringColor = exceeded ? Color(hex: "FF453A") : accentColor
        let shadowColor = exceeded ? Color(hex: "FF453A").opacity(0.55) : accentColor.opacity(0.55)

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(remaining))g")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
                Text("\(name.prefix(1))\(name.dropFirst().lowercased()) left")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "8E8E93"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 7)
                Circle()
                    .stroke(ringColor.opacity(0.10), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: ringAnimation ? clampedRatio : 0)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: shadowColor, radius: 10, x: 0, y: 0)
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ringColor)
            }
            .frame(width: 60, height: 60)

            Text(name)
                .font(.system(size: 7, weight: .heavy))
                .foregroundStyle(accentColor)
                .tracking(1.2)
                .padding(.top, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 175)
        .background(Color.white.opacity(0.05), in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    // MARK: - Page 2: Micronutrients

    private var micronutrientsPage: some View {
        let displayLog = viewModel.nutritionForSelectedDay(at: viewModel.selectedDayIndex)

        let micros: [(String, Double, Double, String, Color)] = [
            ("Fiber", displayLog.totalFiber, 28, "g", Color(hex: "32D74B")),
            ("Sodium", displayLog.totalSodium, 2300, "mg", Color(hex: "FF9F0A")),
            ("Sugar", displayLog.totalSugar, 50, "g", Color(hex: "FF453A")),
            ("Iron", displayLog.totalIron, 18, "mg", Color(hex: "FF6B6B")),
            ("Calcium", displayLog.totalCalcium, 1000, "mg", Color(hex: "0066FF")),
            ("Vit D", displayLog.totalVitaminD, 20, "mcg", Color(hex: "FFD60A")),
            ("Vit C", displayLog.totalVitaminC, 90, "mg", Color(hex: "FF9F0A")),
            ("Vit A", displayLog.totalVitaminA, 900, "mcg", Color(hex: "BF5AF2")),
            ("Potassium", displayLog.totalPotassium, 4700, "mg", Color(hex: "32D74B")),
            ("Magnesium", displayLog.totalMagnesium, 420, "mg", Color(hex: "64D2FF")),
            ("Zinc", displayLog.totalZinc, 11, "mg", Color(hex: "AC8E68")),
            ("B12", displayLog.totalVitaminB12, 2.4, "mcg", Color(hex: "FF375F")),
        ]

        return ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)], spacing: 5) {
                ForEach(Array(micros.enumerated()), id: \.offset) { _, micro in
                    microGridCell(name: micro.0, current: micro.1, goal: micro.2, unit: micro.3, accent: micro.4)
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    private func microGridCell(name: String, current: Double, goal: Double, unit: String, accent: Color) -> some View {
        let ratio = goal > 0 ? min(current / goal, 1.0) : 0
        let safeRatio = (ratio.isNaN || ratio.isInfinite) ? 0 : ratio
        let pct = Int(safeRatio * 100)

        return VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("\(pct)%")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule().fill(accent)
                        .frame(width: max(2, geo.size.width * safeRatio))
                        .shadow(color: accent.opacity(0.40), radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: 3)
            .clipShape(Capsule())

            Text(formatMicroAmount(current, unit: unit))
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(Color(hex: "8E8E93"))
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(Color.white.opacity(0.05), in: .rect(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func formatMicroAmount(_ value: Double, unit: String) -> String {
        if value == 0 { return "0\(unit)" }
        if value < 1 { return String(format: "%.1f%@", value, unit) }
        if value < 10 { return String(format: "%.1f%@", value, unit) }
        return "\(Int(value))\(unit)"
    }

    // MARK: - Page 3: Water

    private var waterPage: some View {
        let glasses = Int(viewModel.todayNutrition.waterIntake / 8)
        let blueAccent = Color(hex: "0066FF")
        let waterProgress = min(Double(glasses) / 8.0, 1.0)

        return VStack(spacing: 8) {
            HStack {
                Text("Hydration")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 0) {
                    Text("\(glasses)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(blueAccent)
                    Text("/8")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "636366"))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule().fill(blueAccent)
                        .frame(width: max(2, geo.size.width * waterProgress))
                        .shadow(color: blueAccent.opacity(0.50), radius: 8, x: 0, y: 0)
                }
            }
            .frame(height: 5)
            .clipShape(Capsule())

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(0..<8, id: \.self) { index in
                    let isFilled = index < glasses
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if isFilled {
                                let glassesToRemove = glasses - index
                                for _ in 0..<glassesToRemove {
                                    viewModel.removeWaterGlass()
                                }
                            } else {
                                let glassesToAdd = index - glasses + 1
                                for _ in 0..<glassesToAdd {
                                    viewModel.addWater(8)
                                }
                            }
                            waterDrop += 1
                        }
                        cupScales[index] = 0.85
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            cupScales[index] = 1.0
                        }
                    } label: {
                        ZStack {
                            if isFilled {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(blueAccent.opacity(0.20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(blueAccent.opacity(0.50), lineWidth: 1.5)
                                    )
                                Image(systemName: "mug.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(blueAccent)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                Image(systemName: "mug")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.white.opacity(0.25))
                            }
                        }
                        .frame(width: 42, height: 42)
                        .shadow(color: isFilled ? blueAccent.opacity(0.60) : .clear, radius: 10, x: 0, y: 0)
                        .scaleEffect(cupScales[index] ?? 1.0)
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: waterDrop)
                }
            }

            waterMotivation(glasses: glasses)
                .padding(.top, 2)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    private func waterMotivation(glasses: Int) -> some View {
        Group {
            if glasses == 0 {
                Text("Stay hydrated — it affects your score")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "636366"))
            } else if glasses <= 4 {
                Text("Keep going")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "636366"))
            } else if glasses <= 7 {
                Text("Almost there")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "636366"))
            } else {
                Text("Goal hit")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "32D74B"))
                    .shadow(color: Color(hex: "32D74B").opacity(0.50), radius: 6, x: 0, y: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Today's Meals

    private var todaysMealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meals")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)

            if viewModel.isScanningMealInline {
                scanningMealCard
            }

            if let error = viewModel.scanningMealError {
                scanErrorCard(error)
            }

            if !viewModel.scanningMealResults.isEmpty {
                scanSuccessCard
            }

            let displayLog = viewModel.nutritionForSelectedDay(at: viewModel.selectedDayIndex)
            if displayLog.entries.isEmpty && !viewModel.isScanningMealInline {
                emptyMealsCard
            } else if !displayLog.entries.isEmpty {
                recentlyUploadedList
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.6).delay(0.2), value: appeared)
    }

    private var scanningMealCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(AppTheme.primaryAccent.opacity(0.12)).frame(width: 48, height: 48)
                    Circle().fill(AppTheme.primaryAccent.opacity(0.08)).frame(width: 48, height: 48)
                        .scaleEffect(scanPulse ? 1.6 : 1.0).opacity(scanPulse ? 0 : 0.6)
                    Image(systemName: "viewfinder")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .symbolEffect(.pulse, options: .repeating)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scanning your meal...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Identifying food items")
                        .font(.system(size: 13)).foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                ProgressView().tint(AppTheme.primaryAccent)
            }
            scanWaveform
        }
        .padding(18)
        .cardStyle(highlighted: true)
        .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { scanPulse = true }
        }
        .onDisappear { scanPulse = false }
    }

    private var scanWaveform: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2.5) {
                ForEach(0..<24, id: \.self) { index in
                    let phase = time * 4.0 + Double(index) * 0.3
                    let wave1 = sin(phase) * 0.5 + 0.5
                    let wave2 = sin(phase * 1.7 + 1.3) * 0.3 + 0.3
                    let combined = min(1.0, wave1 + wave2 * 0.5)
                    let barHeight = max(3, combined * 20)
                    Capsule()
                        .fill(LinearGradient(colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.5)], startPoint: .bottom, endPoint: .top))
                        .frame(width: 3.5, height: barHeight)
                        .opacity(0.4 + combined * 0.6)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 22)
        }
    }

    private func scanErrorCard(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 18)).foregroundStyle(AppTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text("Scan Failed").font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
                Text(error).font(.system(size: 12)).foregroundStyle(AppTheme.secondaryText).lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .cardStyle()
        .transition(.opacity)
    }

    private var scanSuccessCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(AppTheme.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.scanningMealResults.count) item\(viewModel.scanningMealResults.count == 1 ? "" : "s") added")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
                let totalCal = viewModel.scanningMealResults.reduce(0) { $0 + $1.calories }
                Text("~\(totalCal) calories total").font(.system(size: 13)).foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
        .padding(14)
        .cardStyle()
        .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
    }

    private var emptyMealsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.muted)
            Text("No meals logged yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
            Text("Tap + to get started")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 160)
    }

    private var recentlyUploadedList: some View {
        let displayLog = viewModel.nutritionForSelectedDay(at: viewModel.selectedDayIndex)
        let isToday = viewModel.selectedDayIndex == 6
        return VStack(spacing: 12) {
            ForEach(displayLog.entries.reversed()) { entry in
                NavigationLink(value: entry.id) {
                    recentlyUploadedCard(entry: entry)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if isToday {
                        Button(role: .destructive) {
                            withAnimation(.spring(duration: 0.3)) {
                                viewModel.removeFoodEntry(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if isToday {
                        Button(role: .destructive) {
                            withAnimation(.spring(duration: 0.3)) {
                                viewModel.removeFoodEntry(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func recentlyUploadedCard(entry: FoodEntry) -> some View {
        HStack(spacing: 10) {
            if let urlString = entry.imageURL, let url = URL(string: urlString) {
                Color(.secondarySystemBackground)
                    .frame(width: 68, height: 68)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                            } else if phase.error != nil {
                                foodPlaceholderIcon(for: entry.name)
                            } else {
                                ProgressView().tint(AppTheme.primaryAccent)
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: 10))
            } else {
                foodPlaceholderIcon(for: entry.name)
                    .frame(width: 68, height: 68)
                    .background(AppTheme.cardSurfaceElevated)
                    .clipShape(.rect(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.name)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                    Spacer()
                    Text(entryTimeString(entry.timestamp))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                    Text("\(entry.adjustedCalories) Calories")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("\(Int(entry.adjustedProtein))g")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.success)
                        Text("\(Int(entry.adjustedCarbs))g")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.warning)
                        Text("\(Int(entry.adjustedFat))g")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
        .padding(8)
        .padding(16)
        .background(AppTheme.cardSolid, in: .rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.cardBorderSolid, lineWidth: 1)
        )
    }

    private func foodPlaceholderIcon(for name: String) -> some View {
        ZStack {
            AppTheme.cardSurfaceElevated
            Image(systemName: "fork.knife")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppTheme.muted)
        }
    }

    private func entryTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: date)
    }

    // MARK: - FAB

    private var addMenuOverlay: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if showingAddMenu {
                addMenuOption(icon: "magnifyingglass", label: "Nutrition Database", delay: 0.08) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) { showingAddMenu = false }
                    viewModel.showingAddFood = true
                }
                addMenuOption(icon: "camera.fill", label: "Scan Your Meal", delay: 0.12) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) { showingAddMenu = false }
                    fuelCapturedImage = nil
                    showingFuelCamera = true
                }
                addMenuOption(icon: "barcode.viewfinder", label: "Scan Barcode", delay: 0.16) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) { showingAddMenu = false }
                    showingBarcodeScanner = true
                }
                addMenuOption(icon: "mic.fill", label: "Voice Log", delay: 0.20) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) { showingAddMenu = false }
                    showingVoiceLog = true
                }
            }

            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) { showingAddMenu.toggle() }
            } label: {
                Image(systemName: showingAddMenu ? "xmark" : "plus")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background {
                        Circle().fill(
                            showingAddMenu
                                ? LinearGradient(colors: [AppTheme.muted, AppTheme.muted.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: showingAddMenu ? .black.opacity(0.2) : AppTheme.primaryAccent.opacity(0.45), radius: 12, y: 4)
                    }
                    .rotationEffect(.degrees(showingAddMenu ? 90 : 0))
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showingAddMenu)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private func addMenuOption(icon: String, label: String, delay: Double, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(AppTheme.primaryAccent)
                    .frame(width: 40, height: 40).background(.white, in: .rect(cornerRadius: 10))
                Text(label).font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(AppTheme.primaryAccent, in: .rect(cornerRadius: 16))
            .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 12, y: 4)
        }
        .frame(width: 240)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8, anchor: .bottomTrailing)),
            removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .bottomTrailing))
        ))
    }

    private func formattedCalories(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
