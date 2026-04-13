import SwiftUI
import UIKit

@Observable
@MainActor
class NutritionViewModel {
    var todayNutrition: NutritionDailyLog = NutritionDailyLog()
    var weeklyHistory: [NutritionDailyLog] = []
    var dailyCalorieGoal: Int = 2500
    var proteinGoal: Double = 180
    var carbsGoal: Double = 300
    var fatGoal: Double = 80
    var waterGoal: Double = 128
    var nutritionGoals: NutritionGoals = NutritionGoals()
    var showingNutritionSettings: Bool = false
    var showingAddFood: Bool = false
    var showingManualEntry: Bool = false
    var selectedMealType: MealType = .breakfast
    var searchText: String = ""
    var manualName: String = ""
    var manualCalories: String = ""
    var manualProtein: String = ""
    var manualCarbs: String = ""
    var manualFat: String = ""
    var selectedDayIndex: Int = 6
    var streakDays: Int = 7
    var selectedDayNutrition: NutritionDailyLog = NutritionDailyLog()
    var isViewingPastDay: Bool = false

    var nutritionService = NutritionService()
    var showingBarcodeScanner: Bool = false
    var scannedBarcode: String = ""
    var aiSearchText: String = ""
    var isAISearching: Bool = false
    var aiSearchResults: [NutritionLookupResult] = []
    var barcodeResult: NutritionLookupResult?
    var aiErrorMessage: String?
    var showingFoodScanner: Bool = false
    var scannedFoodImage: Data?
    var isAnalyzingImage: Bool = false
    var isScanningMealInline: Bool = false
    var scanningMealResults: [NutritionLookupResult] = []
    var scanningMealError: String?
    var lastCapturedImageURL: String?

    var healthKitConnected: Bool = false
    var healthKitConnecting: Bool = false
    var todaySteps: Double = 0
    var todayActiveCalories: Double = 0
    var healthKitError: String?
    var showOpenHealthSettings: Bool = false

    var weekDays: [(shortName: String, dayNumber: Int, date: Date)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset -> (String, Int, Date)? in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today) else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let short = formatter.string(from: date)
            let day = calendar.component(.day, from: date)
            return (short, day, date)
        }
    }

    var caloriesLeft: Int {
        max(0, dailyCalorieGoal - todayNutrition.totalCalories)
    }

    var proteinLeft: Double {
        max(0, proteinGoal - todayNutrition.totalProtein)
    }

    var carbsLeft: Double {
        max(0, carbsGoal - todayNutrition.totalCarbs)
    }

    var fatLeft: Double {
        max(0, fatGoal - todayNutrition.totalFat)
    }

    var caloriesRemaining: Int {
        dailyCalorieGoal - todayNutrition.totalCalories
    }

    var calorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        let result = min(Double(todayNutrition.totalCalories) / Double(dailyCalorieGoal), 1.0)
        return result.isNaN || result.isInfinite ? 0 : result
    }

    var proteinProgress: Double {
        guard proteinGoal > 0 else { return 0 }
        let result = min(todayNutrition.totalProtein / proteinGoal, 1.0)
        return result.isNaN || result.isInfinite ? 0 : result
    }

    var carbsProgress: Double {
        guard carbsGoal > 0 else { return 0 }
        let result = min(todayNutrition.totalCarbs / carbsGoal, 1.0)
        return result.isNaN || result.isInfinite ? 0 : result
    }

    var fatProgress: Double {
        guard fatGoal > 0 else { return 0 }
        let result = min(todayNutrition.totalFat / fatGoal, 1.0)
        return result.isNaN || result.isInfinite ? 0 : result
    }

    var totalFiber: Double { todayNutrition.entries.reduce(0) { $0 + $1.fiber * $1.quantity } }
    var totalSugar: Double { todayNutrition.entries.reduce(0) { $0 + $1.sugar * $1.quantity } }
    var totalSodium: Double { todayNutrition.entries.reduce(0) { $0 + $1.sodium * $1.quantity } }
    var totalPotassium: Double { todayNutrition.entries.reduce(0) { $0 + $1.potassium * $1.quantity } }
    var totalCholesterol: Double { todayNutrition.entries.reduce(0) { $0 + $1.cholesterol * $1.quantity } }
    var totalVitaminA: Double { todayNutrition.entries.reduce(0) { $0 + $1.vitaminA * $1.quantity } }
    var totalVitaminC: Double { todayNutrition.entries.reduce(0) { $0 + $1.vitaminC * $1.quantity } }
    var totalCalcium: Double { todayNutrition.entries.reduce(0) { $0 + $1.calcium * $1.quantity } }
    var totalIron: Double { todayNutrition.entries.reduce(0) { $0 + $1.iron * $1.quantity } }
    var totalVitaminD: Double { todayNutrition.entries.reduce(0) { $0 + $1.vitaminD * $1.quantity } }
    var totalMagnesium: Double { todayNutrition.entries.reduce(0) { $0 + $1.magnesium * $1.quantity } }
    var totalZinc: Double { todayNutrition.entries.reduce(0) { $0 + $1.zinc * $1.quantity } }

    var filteredFoods: [FoodTemplate] {
        guard !searchText.isEmpty else { return FoodTemplate.database }
        return FoodTemplate.database.filter { $0.name.localizedStandardContains(searchText) }
    }

    func loadData() {
        migrateDataIfNeeded()
        loadNutritionGoals()
        loadTodayNutrition()
        healthKitConnected = HealthKitService.shared.isConnected
        if healthKitConnected {
            Task {
                await refreshHealthData()
            }
        }
        HealthKitService.shared.onDataUpdate = { [weak self] in
            guard let self else { return }
            self.todaySteps = HealthKitService.shared.todaySteps
            self.todayActiveCalories = HealthKitService.shared.todayActiveCalories
        }
    }

    func onForeground() {
        guard healthKitConnected else { return }
        Task {
            await refreshHealthData()
        }
    }

    func connectAppleHealth() async {
        healthKitConnecting = true
        healthKitError = nil
        showOpenHealthSettings = false
        let result = await HealthKitService.shared.connect()
        switch result {
        case .success:
            healthKitConnected = true
            todaySteps = HealthKitService.shared.todaySteps
            todayActiveCalories = HealthKitService.shared.todayActiveCalories
        case .unavailable:
            healthKitError = "Health data is not available on this device."
        case .entitlementMissing:
            healthKitError = "HealthKit is not configured. Please reinstall the app."
        case .denied:
            healthKitConnected = true
            todaySteps = HealthKitService.shared.todaySteps
            todayActiveCalories = HealthKitService.shared.todayActiveCalories
            if todaySteps == 0 && todayActiveCalories == 0 {
                healthKitError = "Enable access in Settings > Health > Data Access."
                showOpenHealthSettings = true
            }
        case .error(let message):
            healthKitError = message
        }
        healthKitConnecting = false
    }

    func openHealthSettings() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func disconnectAppleHealth() {
        HealthKitService.shared.disconnect()
        healthKitConnected = false
        todaySteps = 0
        todayActiveCalories = 0
    }

    func refreshHealthData() async {
        guard healthKitConnected else { return }
        await HealthKitService.shared.fetchTodayData()
        todaySteps = HealthKitService.shared.todaySteps
        todayActiveCalories = HealthKitService.shared.todayActiveCalories
    }

    private func migrateDataIfNeeded() {
        let currentVersion = 20
        let savedVersion = UserDefaults.standard.integer(forKey: "nutrition_data_version")
        if savedVersion < currentVersion {
            let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
            for key in allKeys where key.hasPrefix("nutrition_") {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.removeObject(forKey: "nutritionGoals")
            UserDefaults.standard.removeObject(forKey: "dailyCalorieGoal")
            UserDefaults.standard.removeObject(forKey: "nutritionGoals_v2")
            UserDefaults.standard.removeObject(forKey: "healthkit_authorized")
            UserDefaults.standard.set(currentVersion, forKey: "nutrition_data_version")
        }
    }

    func applyNutritionGoals() {
        dailyCalorieGoal = nutritionGoals.calculatedCalorieGoal
        proteinGoal = nutritionGoals.calculatedProteinGoal
        carbsGoal = nutritionGoals.calculatedCarbsGoal
        fatGoal = nutritionGoals.calculatedFatGoal
        waterGoal = nutritionGoals.waterGoalOz
        saveNutritionGoals()
        UserDefaults.standard.set(dailyCalorieGoal, forKey: "dailyCalorieGoal")
    }

    private func loadNutritionGoals() {
        guard let data = UserDefaults.standard.data(forKey: "nutritionGoals") else {
            let savedCalorieGoal = UserDefaults.standard.integer(forKey: "dailyCalorieGoal")
            if savedCalorieGoal > 0 {
                dailyCalorieGoal = savedCalorieGoal
            }
            return
        }
        do {
            let saved = try JSONDecoder().decode(NutritionGoals.self, from: data)
            nutritionGoals = saved
            dailyCalorieGoal = max(1200, saved.calculatedCalorieGoal)
            proteinGoal = max(1, saved.calculatedProteinGoal)
            carbsGoal = max(1, saved.calculatedCarbsGoal)
            fatGoal = max(1, saved.calculatedFatGoal)
            waterGoal = max(1, saved.waterGoalOz)
        } catch {
            UserDefaults.standard.removeObject(forKey: "nutritionGoals")
        }
    }

    private func saveNutritionGoals() {
        if let data = try? JSONEncoder().encode(nutritionGoals) {
            UserDefaults.standard.set(data, forKey: "nutritionGoals")
        }
    }

    func addFoodEntry(_ template: FoodTemplate, mealType: MealType) {
        let entry = FoodEntry(
            name: template.name,
            calories: template.calories,
            protein: template.protein,
            carbs: template.carbs,
            fat: template.fat,
            mealType: mealType
        )
        todayNutrition.entries.append(entry)
        saveTodayNutrition()
    }

    func addFoodFromAIResult(_ result: NutritionLookupResult, mealType: MealType, imageURL: String? = nil) {
        let entry = FoodEntry(
            name: result.name,
            calories: result.calories,
            protein: result.protein,
            carbs: result.carbs,
            fat: result.fat,
            servingSize: result.servingSize,
            mealType: mealType,
            imageURL: imageURL
        )
        todayNutrition.entries.append(entry)
        saveTodayNutrition()
    }

    func removeFoodEntry(_ entry: FoodEntry) {
        todayNutrition.entries.removeAll { $0.id == entry.id }
        saveTodayNutrition()
    }

    func updateFoodEntry(_ entry: FoodEntry) {
        if let index = todayNutrition.entries.firstIndex(where: { $0.id == entry.id }) {
            todayNutrition.entries[index] = entry
            saveTodayNutrition()
        }
    }

    func healthScore(for entry: FoodEntry) -> Int {
        var score = 50
        let totalMacroCalories = (entry.protein * 4) + (entry.carbs * 4) + (entry.fat * 9)
        if totalMacroCalories > 0 {
            let proteinRatio = (entry.protein * 4) / totalMacroCalories
            if proteinRatio > 0.25 { score += 15 }
            else if proteinRatio > 0.15 { score += 8 }
            let fatRatio = (entry.fat * 9) / totalMacroCalories
            if fatRatio < 0.35 { score += 10 }
            else if fatRatio > 0.55 { score -= 10 }
        }
        if entry.fiber > 3 { score += 10 }
        if entry.sugar > 20 { score -= 10 }
        else if entry.sugar < 5 { score += 5 }
        if entry.sodium > 600 { score -= 8 }
        if entry.vitaminC > 0 || entry.vitaminA > 0 { score += 5 }
        if entry.calcium > 0 || entry.iron > 0 { score += 5 }
        return max(0, min(100, score))
    }

    func addManualEntry(mealType: MealType) {
        let calories = Int(manualCalories) ?? 0
        let protein = Double(manualProtein) ?? 0
        let carbs = Double(manualCarbs) ?? 0
        let fat = Double(manualFat) ?? 0
        guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else { return }
        let finalCalories = calories > 0 ? calories : Int((protein * 4) + (carbs * 4) + (fat * 9))
        let entry = FoodEntry(
            name: manualName.isEmpty ? "Custom Food" : manualName,
            calories: finalCalories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            mealType: mealType
        )
        todayNutrition.entries.append(entry)
        saveTodayNutrition()
        resetManualEntry()
    }

    func resetManualEntry() {
        manualName = ""
        manualCalories = ""
        manualProtein = ""
        manualCarbs = ""
        manualFat = ""
    }

    func addWater(_ ounces: Double) {
        todayNutrition.waterIntake += ounces
        saveTodayNutrition()
    }

    func searchFoodWithAI() async {
        guard !aiSearchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isAISearching = true
        aiErrorMessage = nil
        await nutritionService.searchFood(aiSearchText)
        aiSearchResults = nutritionService.searchResults
        aiErrorMessage = nutritionService.errorMessage
        isAISearching = false
    }

    func analyzeFoodImage(_ imageData: Data) async {
        isAnalyzingImage = true
        aiErrorMessage = nil
        aiSearchResults = []
        let results = await nutritionService.analyzeFoodImage(imageData)
        aiSearchResults = results
        aiErrorMessage = nutritionService.errorMessage
        isAnalyzingImage = false
    }

    func analyzeFoodImageInline(_ imageData: Data, mealType: MealType) async {
        isScanningMealInline = true
        scanningMealResults = []
        scanningMealError = nil
        let savedURL = saveFoodImage(imageData)
        lastCapturedImageURL = savedURL
        let results = await nutritionService.analyzeFoodImage(imageData)
        if results.isEmpty {
            scanningMealError = nutritionService.errorMessage ?? "Could not identify food items."
        } else {
            for result in results {
                addFoodFromAIResult(result, mealType: mealType, imageURL: savedURL)
            }
            scanningMealResults = results
        }
        isScanningMealInline = false
        Task {
            try? await Task.sleep(for: .seconds(4))
            scanningMealResults = []
            scanningMealError = nil
        }
    }

    private func saveFoodImage(_ data: Data) -> String? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let dir else { return nil }
        let foodImagesDir = dir.appendingPathComponent("FoodImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: foodImagesDir, withIntermediateDirectories: true)
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = foodImagesDir.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileURL.absoluteString
        } catch {
            return nil
        }
    }

    func lookupBarcode(_ barcode: String) async {
        isAISearching = true
        aiErrorMessage = nil
        let result = await nutritionService.lookupBarcode(barcode)
        barcodeResult = result
        if let result {
            aiSearchResults = [result]
        }
        aiErrorMessage = nutritionService.errorMessage
        isAISearching = false
    }

    private func saveTodayNutrition() {
        if let data = try? JSONEncoder().encode(todayNutrition) {
            let key = nutritionKey(for: Date())
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadTodayNutrition() {
        let key = nutritionKey(for: Date())
        guard let data = UserDefaults.standard.data(forKey: key) else {
            todayNutrition = NutritionDailyLog()
            return
        }
        do {
            let decoded = try JSONDecoder().decode(NutritionDailyLog.self, from: data)
            todayNutrition = decoded
        } catch {
            UserDefaults.standard.removeObject(forKey: key)
            todayNutrition = NutritionDailyLog()
        }
    }

    func loadNutritionForDay(at index: Int) {
        guard index < weekDays.count else { return }
        let date = weekDays[index].date
        let calendar = Calendar.current
        isViewingPastDay = !calendar.isDateInToday(date)
        let key = nutritionKey(for: date)
        guard let data = UserDefaults.standard.data(forKey: key) else {
            selectedDayNutrition = NutritionDailyLog()
            return
        }
        do {
            selectedDayNutrition = try JSONDecoder().decode(NutritionDailyLog.self, from: data)
        } catch {
            selectedDayNutrition = NutritionDailyLog()
        }
    }

    func nutritionForSelectedDay(at index: Int) -> NutritionDailyLog {
        let calendar = Calendar.current
        guard index < weekDays.count else { return todayNutrition }
        let date = weekDays[index].date
        if calendar.isDateInToday(date) { return todayNutrition }
        return selectedDayNutrition
    }

    func hasDataForDay(at index: Int) -> Bool {
        guard index < weekDays.count else { return false }
        let date = weekDays[index].date
        let key = nutritionKey(for: date)
        guard let data = UserDefaults.standard.data(forKey: key) else { return false }
        if let log = try? JSONDecoder().decode(NutritionDailyLog.self, from: data) {
            return !log.entries.isEmpty
        }
        return false
    }

    private func nutritionKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "nutrition_\(formatter.string(from: date))"
    }
}

nonisolated struct FoodTemplate: Sendable, Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let category: String

    static let database: [FoodTemplate] = [
        FoodTemplate(name: "Grilled Chicken Breast", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: "Protein"),
        FoodTemplate(name: "Brown Rice (1 cup)", calories: 216, protein: 5, carbs: 45, fat: 1.8, category: "Carbs"),
        FoodTemplate(name: "Egg Whites (4)", calories: 68, protein: 14, carbs: 1, fat: 0, category: "Protein"),
        FoodTemplate(name: "Sweet Potato", calories: 103, protein: 2, carbs: 24, fat: 0, category: "Carbs"),
        FoodTemplate(name: "Salmon Fillet", calories: 208, protein: 20, carbs: 0, fat: 13, category: "Protein"),
        FoodTemplate(name: "Greek Yogurt", calories: 100, protein: 17, carbs: 6, fat: 0.7, category: "Protein"),
        FoodTemplate(name: "Banana", calories: 105, protein: 1.3, carbs: 27, fat: 0.4, category: "Fruit"),
        FoodTemplate(name: "Avocado", calories: 240, protein: 3, carbs: 12, fat: 22, category: "Fat"),
        FoodTemplate(name: "Oatmeal (1 cup)", calories: 158, protein: 6, carbs: 27, fat: 3, category: "Carbs"),
        FoodTemplate(name: "Whey Protein Shake", calories: 120, protein: 24, carbs: 3, fat: 1, category: "Protein"),
        FoodTemplate(name: "Broccoli (1 cup)", calories: 55, protein: 3.7, carbs: 11, fat: 0.6, category: "Vegetables"),
        FoodTemplate(name: "Almonds (1 oz)", calories: 164, protein: 6, carbs: 6, fat: 14, category: "Fat"),
        FoodTemplate(name: "Turkey Breast", calories: 135, protein: 30, carbs: 0, fat: 1, category: "Protein"),
        FoodTemplate(name: "Quinoa (1 cup)", calories: 222, protein: 8, carbs: 39, fat: 3.5, category: "Carbs"),
        FoodTemplate(name: "Peanut Butter (2 tbsp)", calories: 188, protein: 8, carbs: 6, fat: 16, category: "Fat"),
        FoodTemplate(name: "Steak (6 oz)", calories: 340, protein: 42, carbs: 0, fat: 18, category: "Protein"),
    ]
}
