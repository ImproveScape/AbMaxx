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
    @State private var tabPage: Int = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    fuelHeader
                    nutritionContent
                }
                .background {
                    ZStack {
                        AppTheme.background.ignoresSafeArea()
                        StandardBackgroundOrbs()
                    }
                }

                if showingAddMenu {
                    Color.black.opacity(0.4)
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
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .task {
                viewModel.loadData()
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
        }
    }

    private var fuelHeader: some View {
        HStack(alignment: .center) {
            Text("Nutrition")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            Spacer()

            deficitButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    private var deficitButton: some View {
        Button {
            showDeficitPicker = true
        } label: {
            HStack(spacing: 4) {
                Text("-\(vm.profile.selectedCalorieDeficit)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppTheme.cardSurface, in: .rect(cornerRadius: 10))
        }
    }

    private var nutritionContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if dataLoaded {
                    weeklyCalendarStrip
                    caloriesHeroCard
                    tabViewSection
                    pageDots
                    todaysMealsSection
                } else {
                    ProgressView()
                        .tint(AppTheme.primaryAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                }
            }
            .padding(.horizontal, 16)
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
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)

                        Text("\(day.dayNumber)")
                            .font(.system(size: 16, weight: isSelected ? .bold : .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? .white : AppTheme.primaryText)
                    }
                    .frame(width: 44, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? AppTheme.primaryAccent : AppTheme.cardSurface)
                            .shadow(color: isSelected ? AppTheme.primaryAccent.opacity(0.3) : Color.black.opacity(0.1), radius: isSelected ? 8 : 4, y: 2)
                    )
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

        return VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedCalories(remaining))
                        .font(.system(size: 52, weight: .heavy))
                        .foregroundStyle(.white)
                        .tracking(-0.03 * 52)
                        .contentTransition(.numericText())

                    Text("Calories remaining")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "8E8E93"))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .stroke(Color(hex: "0066FF").opacity(0.10), lineWidth: 14)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: ringAnimation ? safeProgress : 0)
                        .stroke(Color(hex: "0066FF"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color(hex: "0066FF").opacity(0.65), radius: 14, x: 0, y: 0)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: "0066FF"))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .clipShape(.rect(cornerRadius: 3))

                    Rectangle()
                        .fill(Color(hex: "0066FF"))
                        .frame(width: max(2, geo.size.width * (ringAnimation ? safeProgress : 0)))
                        .clipShape(.rect(cornerRadius: 3))
                        .shadow(color: Color(hex: "0066FF").opacity(0.50), radius: 8, x: 0, y: 0)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(totalCal) eaten")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "636366"))
                Spacer()
                Text("\(formattedCalories(goal)) goal")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "636366"))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.6).delay(0.05), value: appeared)
    }

    // MARK: - TabView Section

    private var tabViewSection: some View {
        TabView(selection: $tabPage) {
            macroRingsPage.tag(0)
            micronutrientsPage.tag(1)
            waterPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 300)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.6).delay(0.1), value: appeared)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == tabPage ? Color(hex: "0066FF") : Color.white.opacity(0.20))
                    .frame(width: index == tabPage ? 8 : 6, height: index == tabPage ? 8 : 6)
                    .shadow(color: index == tabPage ? Color(hex: "0066FF").opacity(0.55) : .clear, radius: 6, x: 0, y: 0)
                    .animation(.spring(response: 0.3), value: tabPage)
            }
        }
    }

    // MARK: - Page 1: Macro Rings

    private var macroRingsPage: some View {
        let displayLog = viewModel.nutritionForSelectedDay(at: viewModel.selectedDayIndex)

        return HStack(spacing: 8) {
            macroRingCard(
                consumed: displayLog.totalProtein,
                goal: viewModel.proteinGoal,
                accent: Color(hex: "0066FF"),
                icon: "figure.strengthtraining.traditional",
                fallbackIcon: "dumbbell.fill",
                label: "PROTEIN",
                unit: "g"
            )
            macroRingCard(
                consumed: displayLog.totalCarbs,
                goal: viewModel.carbsGoal,
                accent: Color(hex: "FF9F0A"),
                icon: "flame.fill",
                fallbackIcon: "flame.fill",
                label: "CARBS",
                unit: "g"
            )
            macroRingCard(
                consumed: displayLog.totalFat,
                goal: viewModel.fatGoal,
                accent: Color(hex: "BF5AF2"),
                icon: "chart.pie.fill",
                fallbackIcon: "circle.lefthalf.filled",
                label: "FAT",
                unit: "g"
            )
        }
        .padding(.top, 4)
    }

    private func macroRingCard(consumed: Double, goal: Double, accent: Color, icon: String, fallbackIcon: String, label: String, unit: String) -> some View {
        let progress = goal > 0 ? min(consumed / goal, 1.0) : 0
        let safeProgress = (progress.isNaN || progress.isInfinite) ? 0 : progress
        let exceeded = consumed > goal && goal > 0
        let arcColor = exceeded ? Color(hex: "FF453A") : accent
        let glowColor = exceeded ? Color(hex: "FF453A").opacity(0.55) : accent.opacity(0.55)

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 6)
                    .frame(width: 56, height: 56)

                Circle()
                    .stroke(accent.opacity(0.10), lineWidth: 10)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: ringAnimation ? safeProgress : 0)
                    .stroke(arcColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: glowColor, radius: 10, x: 0, y: 0)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(accent)
            }

            HStack(spacing: 4) {
                Text("\(Int(consumed))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("/")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "636366"))
                Text("\(Int(goal))\(unit)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "636366"))
            }

            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(accent)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Page 2: Micronutrients

    private var micronutrientsPage: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Micronutrients")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("Today")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "636366"))
            }
            .padding(.bottom, 8)

            VStack(spacing: 8) {
                micronutrientRow(name: "Fiber", current: viewModel.totalFiber, goal: 25, unit: "g", accent: Color(hex: "32D74B"))
                micronutrientRow(name: "Sodium", current: viewModel.totalSodium, goal: 2300, unit: "mg", accent: Color(hex: "FF9F0A"))
                micronutrientRow(name: "Sugar", current: viewModel.totalSugar, goal: 50, unit: "g", accent: Color(hex: "FF453A"))
                micronutrientRow(name: "Cholesterol", current: viewModel.totalCholesterol, goal: 300, unit: "mg", accent: Color(hex: "BF5AF2"))
                micronutrientRow(name: "Calcium", current: viewModel.totalCalcium, goal: 1000, unit: "mg", accent: Color(hex: "0066FF"))
                micronutrientRow(name: "Potassium", current: viewModel.totalPotassium, goal: 3500, unit: "mg", accent: Color(hex: "32D74B"))
            }

            Text("Based on today's logged meals")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "48484A"))
                .padding(.top, 8)
        }
        .padding(.top, 4)
    }

    private func micronutrientRow(name: String, current: Double, goal: Double, unit: String, accent: Color) -> some View {
        let progress = goal > 0 ? min(current / goal, 1.0) : 0
        let safeProgress = (progress.isNaN || progress.isInfinite) ? 0 : progress

        return HStack {
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 85, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .clipShape(.rect(cornerRadius: 3))

                    Rectangle()
                        .fill(accent)
                        .frame(width: max(2, geo.size.width * safeProgress))
                        .clipShape(.rect(cornerRadius: 3))
                        .shadow(color: accent.opacity(0.40), radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: 6)

            Text("\(Int(current)) / \(Int(goal))\(unit)")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "8E8E93"))
                .frame(width: 80, alignment: .trailing)
        }
        .frame(height: 44)
        .padding(.horizontal, 12)
        .padding(.vertical, 0)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Page 3: Water

    private var waterPage: some View {
        let glasses = Int(viewModel.todayNutrition.waterIntake / 8)
        let clampedGlasses = min(glasses, 8)
        let waterProgress = min(Double(clampedGlasses) / 8.0, 1.0)

        return VStack(spacing: 0) {
            HStack {
                Text("Hydration")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 0) {
                    Text("\(clampedGlasses)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "0066FF"))
                    Text("/8")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "636366"))
                }
            }
            .padding(.bottom, 10)

            VStack(spacing: 2) {
                Text("\(clampedGlasses)")
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.15), radius: 10, x: 0, y: 0)

                Text("glasses today")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "636366"))
            }
            .padding(.bottom, 10)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .clipShape(.rect(cornerRadius: 4))

                    Rectangle()
                        .fill(Color(hex: "0066FF"))
                        .frame(width: max(2, geo.size.width * waterProgress))
                        .clipShape(.rect(cornerRadius: 4))
                        .shadow(color: Color(hex: "0066FF").opacity(0.50), radius: 8, x: 0, y: 0)
                }
            }
            .frame(height: 8)
            .padding(.bottom, 14)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(0..<8, id: \.self) { index in
                    let isFilled = index < clampedGlasses
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if isFilled {
                                let currentGlasses = Int(viewModel.todayNutrition.waterIntake / 8)
                                let glassesToRemove = currentGlasses - index
                                if glassesToRemove > 0 {
                                    viewModel.todayNutrition.waterIntake -= Double(glassesToRemove * 8)
                                    if viewModel.todayNutrition.waterIntake < 0 {
                                        viewModel.todayNutrition.waterIntake = 0
                                    }
                                }
                            } else {
                                let currentGlasses = Int(viewModel.todayNutrition.waterIntake / 8)
                                let glassesToAdd = (index + 1) - currentGlasses
                                if glassesToAdd > 0 {
                                    for _ in 0..<glassesToAdd {
                                        viewModel.addWater(8)
                                    }
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            if isFilled {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: "0066FF").opacity(0.18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "0066FF").opacity(0.45), lineWidth: 1)
                                    )
                                    .shadow(color: Color(hex: "0066FF").opacity(0.65), radius: 12, x: 0, y: 0)

                                Image(systemName: "drop.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(hex: "0066FF"))
                            } else {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )

                                Image(systemName: "drop")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.white.opacity(0.20))
                            }
                        }
                        .frame(width: 54, height: 54)
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: clampedGlasses)
                }
            }

            waterMotivationalText(glasses: clampedGlasses)
                .padding(.top, 8)
        }
        .padding(.top, 4)
    }

    private func waterMotivationalText(glasses: Int) -> some View {
        Group {
            if glasses == 0 {
                Text("Stay hydrated — it affects your score")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "636366"))
            } else if glasses <= 4 {
                Text("Keep going — halfway there")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "636366"))
            } else if glasses <= 7 {
                Text("Almost there — finish strong")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "636366"))
            } else {
                Text("Goal hit")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "32D74B"))
                    .shadow(color: Color(hex: "32D74B").opacity(0.50), radius: 6, x: 0, y: 0)
            }
        }
    }

    // MARK: - Today's Meals / Recently Uploaded

    private var todaysMealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.selectedDayIndex == 6 ? "Recently uploaded" : "Meals")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

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
                    Circle().fill(AppTheme.primaryAccent.opacity(0.15)).frame(width: 48, height: 48)
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
            Image(systemName: "fork.knife").font(.system(size: 28)).foregroundStyle(AppTheme.muted)
            VStack(spacing: 3) {
                Text("No meals logged yet").font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.secondaryText)
                Text("Tap + or scan food to get started").font(.system(size: 12)).foregroundStyle(AppTheme.muted)
            }
        }
        .frame(maxWidth: .infinity).frame(minHeight: 220)
        .cardStyle()
    }

    private var recentlyUploadedList: some View {
        let displayLog = viewModel.nutritionForSelectedDay(at: viewModel.selectedDayIndex)
        return VStack(spacing: 12) {
            ForEach(displayLog.entries.reversed()) { entry in
                NavigationLink(value: entry.id) {
                    recentlyUploadedCard(entry: entry)
                }
                .buttonStyle(.plain)
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
                        .font(.system(size: 16, weight: .semibold))
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
                        .font(.system(size: 15, weight: .bold))
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
        .cardStyle()
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
                    viewModel.aiSearchResults = []
                    viewModel.aiErrorMessage = nil
                    viewModel.showingFoodScanner = true
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
