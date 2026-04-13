import SwiftUI

struct NutritionView: View {
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
    @State private var dashboardPage: Int = 0
    @State private var showingDeficitEditor: Bool = false
    @State private var deficitText: String = ""
    @Environment(\.scenePhase) private var scenePhase

    private let brandRed = Color(red: 0.95, green: 0.23, blue: 0.15)
    private let brandOrange = Color(red: 1.0, green: 0.45, blue: 0.18)
    private let pageCount: Int = 3

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    fuelHeader
                    nutritionContent
                }
                .background(Color.black)

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
                BarcodeScannerView(viewModel: viewModel, mealType: .lunch)
            }
            .sheet(isPresented: $showingVoiceLog) {
                VoiceLogView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingNutritionSettings) {
                NutritionSettingsView(viewModel: viewModel)
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
            VStack(alignment: .leading, spacing: 2) {
                Text("Fuel")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                streakBadge

                calorieGoalBadge

                Button {
                    viewModel.showingNutritionSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(white: 0.55))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.08), in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.06), lineWidth: 0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    private var nutritionContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                if dataLoaded {
                    weekDayStrip
                    dashboardCarousel
                    todaysMealsSection
                } else {
                    ProgressView()
                        .tint(brandOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
    }

    private var calorieGoalBadge: some View {
        Button {
            deficitText = "\(viewModel.dailyCalorieGoal)"
            showingDeficitEditor = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "target")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(brandRed)
                Text("\(viewModel.dailyCalorieGoal)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("cal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.06), lineWidth: 0.5))
        }
        .sheet(isPresented: $showingDeficitEditor) {
            calorieGoalEditor
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
    }

    private var calorieGoalEditor: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [brandOrange, brandRed],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("Daily Calorie Goal")
                    .font(.system(size: 18, weight: .bold))
                Text("Set your daily target")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            HStack(spacing: 4) {
                TextField("2000", text: $deficitText)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 160)

                Text("cal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ForEach([1500, 2000, 2500], id: \.self) { preset in
                    Button {
                        deficitText = "\(preset)"
                    } label: {
                        Text("\(preset)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(deficitText == "\(preset)" ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                deficitText == "\(preset)"
                                    ? AnyShapeStyle(LinearGradient(colors: [brandOrange, brandRed], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    : AnyShapeStyle(Color.white.opacity(0.08)),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    deficitText == "\(preset)" ? Color.clear : Color.white.opacity(0.06),
                                    lineWidth: 0.5
                                )
                            )
                    }
                }
            }

            Button {
                if let value = Int(deficitText), value >= 800, value <= 10000 {
                    viewModel.nutritionGoals.customCalorieGoal = value
                    viewModel.applyNutritionGoals()
                }
                showingDeficitEditor = false
            } label: {
                Text("Set Goal")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [brandOrange, brandRed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: .rect(cornerRadius: 14)
                    )
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showingDeficitEditor)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var streakBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13))
                .foregroundStyle(brandOrange)
            Text("\(viewModel.streakDays)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.08), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.06), lineWidth: 0.5))
    }

    private var weekDayStrip: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.weekDays.enumerated()), id: \.offset) { index, day in
                let isSelected = index == viewModel.selectedDayIndex

                Button {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                        viewModel.selectedDayIndex = index
                    }
                } label: {
                    VStack(spacing: 5) {
                        Text(day.shortName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isSelected ? brandRed : .secondary)
                            .textCase(.uppercase)

                        Text("\(day.dayNumber)")
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .frame(width: 30, height: 30)
                            .background {
                                if isSelected {
                                    Circle()
                                        .fill(brandRed)
                                        .shadow(color: brandRed.opacity(0.4), radius: 6, y: 2)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 6)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var dashboardCarousel: some View {
        VStack(spacing: 10) {
            TabView(selection: $dashboardPage) {
                caloriePageContent
                    .tag(0)

                micronutrientPageContent
                    .tag(1)

                waterPageContent
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: dashboardPageHeight)
            .animation(.spring(duration: 0.35), value: dashboardPage)

            pageDots
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.6).delay(0.05), value: appeared)
    }

    private let dashboardPageHeight: CGFloat = 240

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == dashboardPage ? brandOrange : Color.white.opacity(0.18))
                    .frame(width: index == dashboardPage ? 20 : 6, height: 6)
                    .animation(.spring(duration: 0.3, bounce: 0.2), value: dashboardPage)
            }
        }
    }

    private var caloriePageContent: some View {
        VStack(spacing: 8) {
            calorieHeroCard
            macroCardsRow
        }
        .padding(.horizontal, 4)
    }

    private var calorieHeroCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedCalories(viewModel.caloriesLeft))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    Text("Calories left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                calorieRing
            }

            HStack(spacing: 0) {
                VStack(spacing: 1) {
                    Text("\(viewModel.todayNutrition.totalCalories)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(brandOrange)
                    Text("Eaten")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 20)

                VStack(spacing: 1) {
                    Text("\(viewModel.dailyCalorieGoal)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("Goal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 20)

                VStack(spacing: 1) {
                    Text(formattedCalories(viewModel.caloriesLeft))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.caloriesLeft > 0 ? .green : brandRed)
                    Text("Remaining")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 10)
            .padding(.bottom, 2)
        }
        .padding(16)
        .polishedCard(cornerRadius: 18)
    }

    private var calorieRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemFill), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: ringAnimation ? viewModel.calorieProgress : 0)
                .stroke(
                    AngularGradient(
                        colors: [brandOrange, brandRed, brandRed],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            Image(systemName: "flame.fill")
                .font(.system(size: 22))
                .foregroundStyle(
                    LinearGradient(
                        colors: [brandOrange, brandRed],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var macroCardsRow: some View {
        HStack(spacing: 8) {
            macroCard(
                value: Int(viewModel.proteinLeft),
                label: "Protein",
                icon: "fish.fill",
                iconColor: brandRed,
                progress: viewModel.proteinProgress
            )
            macroCard(
                value: Int(viewModel.carbsLeft),
                label: "Carbs",
                icon: "bolt.fill",
                iconColor: brandOrange,
                progress: viewModel.carbsProgress
            )
            macroCard(
                value: Int(viewModel.fatLeft),
                label: "Fat",
                icon: "drop.fill",
                iconColor: Color(red: 0.45, green: 0.52, blue: 0.9),
                progress: viewModel.fatProgress
            )
        }
    }

    private func macroCard(value: Int, label: String, icon: String, iconColor: Color, progress: Double) -> some View {
        let safeProgress = (progress.isNaN || progress.isInfinite) ? 0 : min(1.0, progress)
        return VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(value)g")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(iconColor.opacity(0.12))

                    Capsule()
                        .fill(iconColor)
                        .frame(width: max(4, geo.size.width * (ringAnimation ? safeProgress : 0)))
                }
            }
            .frame(height: 4)
            .clipShape(Capsule())
        }
        .padding(10)
        .polishedCard(cornerRadius: 14)
    }

    private var todaysMealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Meals")
                .font(.system(size: 20, weight: .bold))

            if viewModel.isScanningMealInline {
                scanningMealCard
            }

            if let error = viewModel.scanningMealError {
                scanErrorCard(error)
            }

            if !viewModel.scanningMealResults.isEmpty {
                scanSuccessCard
            }

            if viewModel.todayNutrition.entries.isEmpty && !viewModel.isScanningMealInline {
                emptyMealsCard
            } else if !viewModel.todayNutrition.entries.isEmpty {
                VStack(spacing: 10) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        let entries = viewModel.todayNutrition.entries.filter { $0.mealType == mealType }
                        if !entries.isEmpty {
                            mealGroupCard(mealType: mealType, entries: entries)
                        }
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.6).delay(0.15), value: appeared)
    }

    private var scanningMealCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(brandOrange.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Circle()
                        .fill(brandOrange.opacity(0.08))
                        .frame(width: 48, height: 48)
                        .scaleEffect(scanPulse ? 1.6 : 1.0)
                        .opacity(scanPulse ? 0 : 0.6)

                    Image(systemName: "viewfinder")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(brandOrange)
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scanning your meal...")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Identifying food items")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ProgressView()
                    .tint(brandOrange)
            }

            scanWaveform
        }
        .padding(18)
        .polishedCard(cornerRadius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(brandOrange.opacity(0.3), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        ))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scanPulse = true
            }
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
                        .fill(
                            LinearGradient(
                                colors: [brandOrange, brandRed.opacity(0.7)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 3.5, height: barHeight)
                        .opacity(0.4 + combined * 0.6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 22)
        }
    }

    private func scanErrorCard(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Scan Failed")
                    .font(.system(size: 14, weight: .semibold))
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .polishedCard(cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 0.5)
        )
        .transition(.opacity)
    }

    private var scanSuccessCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.scanningMealResults.count) item\(viewModel.scanningMealResults.count == 1 ? "" : "s") added")
                    .font(.system(size: 15, weight: .semibold))

                let totalCal = viewModel.scanningMealResults.reduce(0) { $0 + $1.calories }
                Text("~\(totalCal) calories total")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .polishedCard(cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.green.opacity(0.3), lineWidth: 0.5)
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        ))
    }

    private var emptyMealsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)

            VStack(spacing: 3) {
                Text("No meals logged yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Tap + or scan food to get started")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
        .polishedCard()
    }

    private func mealGroupCard(mealType: MealType, entries: [FoodEntry]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: mealType.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(mealColor(mealType))
                        .frame(width: 30, height: 30)
                        .background(mealColor(mealType).opacity(0.12))
                        .clipShape(.rect(cornerRadius: 9))

                    Text(mealType.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                }

                Spacer()

                Text("\(entries.reduce(0) { $0 + $1.adjustedCalories }) cal")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(mealColor(mealType))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(mealColor(mealType).opacity(0.1), in: Capsule())
            }
            .padding(.bottom, 12)

            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                if index > 0 {
                    Divider()
                        .overlay(Color.white.opacity(0.04))
                        .padding(.leading, 15)
                }
                NavigationLink(value: entry.id) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(mealColor(mealType))
                            .frame(width: 3.5, height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            HStack(spacing: 8) {
                                Text("P \(Int(entry.adjustedProtein))g")
                                    .foregroundStyle(.blue)
                                Text("C \(Int(entry.adjustedCarbs))g")
                                    .foregroundStyle(.orange)
                                Text("F \(Int(entry.adjustedFat))g")
                                    .foregroundStyle(.purple)
                            }
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Text("\(entry.adjustedCalories)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            + Text(" cal")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(mealColor(mealType).opacity(0.04))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .polishedCard(cornerRadius: 18)
    }

    private var micronutrientPageContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 24, height: 24)
                    .background(.green.opacity(0.12), in: .rect(cornerRadius: 7))
                Text("Micronutrients")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            let leftColumn: [(String, String, Double, Double, Color)] = [
                ("Fiber", "leaf.circle.fill", viewModel.totalFiber, 28, .green),
                ("Sugar", "cube.fill", viewModel.totalSugar, 50, .pink),
                ("Vit C", "sun.max.fill", viewModel.totalVitaminC, 90, .yellow),
                ("Iron", "bolt.circle.fill", viewModel.totalIron, 18, brandRed),
                ("Calcium", "shield.fill", viewModel.totalCalcium, 1000, .cyan),
                ("Vit A", "eye.fill", viewModel.totalVitaminA, 900, .orange),
            ]

            let rightColumn: [(String, String, Double, Double, Color)] = [
                ("Sodium", "exclamationmark.triangle.fill", viewModel.totalSodium, 2300, .orange),
                ("Potassium", "bolt.heart.fill", viewModel.totalPotassium, 4700, .purple),
                ("Magnesium", "sparkles", viewModel.totalMagnesium, 400, .teal),
                ("Vit D", "sun.min.fill", viewModel.totalVitaminD, 20, .yellow),
                ("Zinc", "atom", viewModel.totalZinc, 11, .mint),
                ("Cholest.", "heart.circle.fill", viewModel.totalCholesterol, 300, .red),
            ]

            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 4) {
                    ForEach(Array(leftColumn.enumerated()), id: \.offset) { _, micro in
                        compactMicroRow(name: micro.0, icon: micro.1, value: micro.2, rda: micro.3, color: micro.4)
                    }
                }
                VStack(spacing: 4) {
                    ForEach(Array(rightColumn.enumerated()), id: \.offset) { _, micro in
                        compactMicroRow(name: micro.0, icon: micro.1, value: micro.2, rda: micro.3, color: micro.4)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .polishedCard(cornerRadius: 18)
        .padding(.horizontal, 4)
    }

    private func compactMicroRow(name: String, icon: String, value: Double, rda: Double, color: Color) -> some View {
        let progress = rda > 0 ? min(value / rda, 1.0) : 0
        let safeProgress = (progress.isNaN || progress.isInfinite) ? 0 : progress
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(color)
                Text(name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatMicroValue(value, rda: rda))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(safeProgress >= 1.0 ? color : .primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.1))
                    Capsule()
                        .fill(color)
                        .frame(width: max(3, geo.size.width * (ringAnimation ? safeProgress : 0)))
                }
            }
            .frame(height: 3)
            .clipShape(Capsule())
        }
        .frame(height: 24)
    }

    private func formatMicroValue(_ value: Double, rda: Double) -> String {
        if rda >= 100 {
            return "\(Int(value))/\(Int(rda))"
        } else {
            return String(format: "%.1f/%.0f", value, rda)
        }
    }

    private var waterPageContent: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                appleHealthConnectCard
                caloriesStepsCard
            }
            .frame(height: 160)
            waterTrackerRow
        }
        .padding(.horizontal, 4)
    }

    private var appleHealthConnectCard: some View {
        Group {
            if viewModel.healthKitConnected {
                appleHealthConnectedCard
            } else {
                appleHealthDisconnectedCard
            }
        }
    }

    private var appleHealthDisconnectedCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(
                    LinearGradient(
                        colors: [.pink, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: .rect(cornerRadius: 13)
                )

            VStack(spacing: 3) {
                Text("Connect Apple Health")
                    .font(.system(size: 13, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("Track your steps")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await viewModel.connectAppleHealth()
                }
            } label: {
                if viewModel.healthKitConnecting {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 18)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 5)
                } else {
                    Text("Connect")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 8)
                }
            }
            .background(
                LinearGradient(
                    colors: [.pink, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .disabled(viewModel.healthKitConnecting)

            if let error = viewModel.healthKitError {
                Text(error)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if viewModel.showOpenHealthSettings {
                Button {
                    viewModel.openHealthSettings()
                } label: {
                    Text("Open Settings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.pink)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .polishedCard(cornerRadius: 18)
    }

    private var appleHealthConnectedCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.pink)
                Text("Apple Health")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Connected")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.green)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(brandOrange)
                Text("\(Int(viewModel.todaySteps))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("steps")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(brandRed)
                Text("\(Int(viewModel.todayActiveCalories))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("cal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.disconnectAppleHealth()
            } label: {
                Text("Disconnect")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .polishedCard(cornerRadius: 18)
    }

    private var caloriesStepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Calories burned")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(viewModel.todayActiveCalories))")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("cal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(brandOrange)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Steps")
                        .font(.system(size: 13, weight: .semibold))
                    Text("\(Int(viewModel.todaySteps))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .polishedCard(cornerRadius: 18)
    }

    private var waterTrackerRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.cyan)
                .frame(width: 40, height: 40)
                .background(.cyan.opacity(0.1), in: .rect(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 2) {
                Text("Water")
                    .font(.system(size: 14, weight: .bold))
                let glasses = Int(viewModel.todayNutrition.waterIntake / 8)
                Text("\(Int(viewModel.todayNutrition.waterIntake)) fl oz (\(glasses) cups)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                ForEach([4, 8, 12, 16], id: \.self) { oz in
                    Button {
                        withAnimation(.spring(duration: 0.4, bounce: 0.35)) {
                            viewModel.addWater(Double(oz))
                            waterDrop += 1
                        }
                    } label: {
                        Label("+\(oz) oz", systemImage: "drop.fill")
                    }
                }
            } label: {
                Text("Log Water")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color(.systemGray5), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
            }
            .sensoryFeedback(.impact(weight: .light), trigger: waterDrop)
        }
        .padding(14)
        .polishedCard(cornerRadius: 18)
    }


    private var addMenuOverlay: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if showingAddMenu {
                addMenuOption(
                    icon: "magnifyingglass",
                    label: "Nutrition Database",
                    delay: 0.08
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) { showingAddMenu = false }
                    viewModel.showingAddFood = true
                }

                addMenuOption(
                    icon: "camera.fill",
                    label: "Scan Your Meal",
                    delay: 0.12
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) { showingAddMenu = false }
                    fuelCapturedImage = nil
                    showingFuelCamera = true
                }

                addMenuOption(
                    icon: "barcode.viewfinder",
                    label: "Scan Barcode",
                    delay: 0.16
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) { showingAddMenu = false }
                    showingBarcodeScanner = true
                }

                addMenuOption(
                    icon: "mic.fill",
                    label: "Voice Log",
                    delay: 0.20
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) { showingAddMenu = false }
                    showingVoiceLog = true
                }
            }

            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                    showingAddMenu.toggle()
                }
            } label: {
                Image(systemName: showingAddMenu ? "xmark" : "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background {
                        Circle()
                            .fill(
                                showingAddMenu
                                    ? LinearGradient(colors: [Color(.systemGray2), Color(.systemGray3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [brandOrange, brandRed], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: showingAddMenu ? .black.opacity(0.2) : brandRed.opacity(0.45), radius: 12, y: 4)
                    }
                    .rotationEffect(.degrees(showingAddMenu ? 90 : 0))
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showingAddMenu)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 90)
    }

    private func addMenuOption(icon: String, label: String, delay: Double, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(brandOrange)
                    .frame(width: 40, height: 40)
                    .background(.white, in: .rect(cornerRadius: 10))

                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [brandOrange, brandOrange.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: .rect(cornerRadius: 16)
            )
            .shadow(color: brandOrange.opacity(0.35), radius: 12, y: 4)
        }
        .frame(width: 240)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8, anchor: .bottomTrailing)),
            removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .bottomTrailing))
        ))
    }

    private func mealColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast: brandOrange
        case .lunch: .green
        case .dinner: .blue
        case .snack: .purple
        case .preworkout: brandRed
        case .postworkout: .teal
        }
    }

    private func formattedCalories(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

