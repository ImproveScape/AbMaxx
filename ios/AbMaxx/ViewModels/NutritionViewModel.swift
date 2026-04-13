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
    var totalMealsLogged: Int = 0
    var onFoodAdded: ((Int, String) -> Void)?
    var onWaterChanged: ((Int) -> Void)?
    var onMacroExceeded: ((String, Int) -> Void)?

    var healthKitConnected: Bool = false
    var healthKitConnecting: Bool = false
    var todaySteps: Double = 0
    var todayActiveCalories: Double = 0
    var healthKitError: String?
    var showOpenHealthSettings: Bool = false
    // HealthKit removed — properties kept as stubs for UI compatibility

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

    var totalFiber: Double { todayNutrition.totalFiber }
    var totalSugar: Double { todayNutrition.totalSugar }
    var totalSodium: Double { todayNutrition.totalSodium }
    var totalPotassium: Double { todayNutrition.totalPotassium }
    var totalCholesterol: Double { todayNutrition.totalCholesterol }
    var totalVitaminA: Double { todayNutrition.totalVitaminA }
    var totalVitaminC: Double { todayNutrition.totalVitaminC }
    var totalCalcium: Double { todayNutrition.totalCalcium }
    var totalIron: Double { todayNutrition.totalIron }
    var totalVitaminD: Double { todayNutrition.totalVitaminD }
    var totalMagnesium: Double { todayNutrition.totalMagnesium }
    var totalZinc: Double { todayNutrition.totalZinc }

    var filteredFoods: [FoodTemplate] {
        guard !searchText.isEmpty else { return FoodTemplate.database }
        return FoodTemplate.database.filter { $0.name.localizedStandardContains(searchText) }
    }

    func loadData() {
        migrateDataIfNeeded()
        loadNutritionGoals()
        loadTodayNutrition()
        loadTotalMealsLogged()
        healthKitConnected = false
    }

    func onForeground() {}

    func connectAppleHealth() async {
        healthKitError = "Health integration has been removed."
    }

    func openHealthSettings() {}

    func disconnectAppleHealth() {
        healthKitConnected = false
        todaySteps = 0
        todayActiveCalories = 0
    }

    func refreshHealthData() async {}

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
            UserDefaults.standard.removeObject(forKey: "healthkit_connected")
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

    func syncFromProfile(_ profile: UserProfile) {
        guard profile.selectedCalorieDeficit > 0 else { return }
        let newGoal = max(1200, Int(profile.tdee) - profile.selectedCalorieDeficit)
        guard newGoal != dailyCalorieGoal else { return }
        dailyCalorieGoal = newGoal
        let calDouble = Double(newGoal)
        proteinGoal = profile.weightInLbs * 1.0
        let proteinCal = proteinGoal * 4.0
        let fatCal = calDouble * 0.25
        fatGoal = fatCal / 9.0
        carbsGoal = max((calDouble - proteinCal - fatCal) / 4.0, 50)
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
        let prevCal = todayNutrition.totalCalories
        let prevPro = todayNutrition.totalProtein
        let prevCarbs = todayNutrition.totalCarbs
        let prevFat = todayNutrition.totalFat
        let entry = FoodEntry(
            name: template.name,
            calories: template.calories,
            protein: template.protein,
            carbs: template.carbs,
            fat: template.fat,
            mealType: mealType,
            fiber: template.fiber, sugar: template.sugar, sodium: template.sodium,
            potassium: template.potassium, cholesterol: template.cholesterol,
            vitaminA: template.vitaminA, vitaminC: template.vitaminC,
            calcium: template.calcium, iron: template.iron,
            vitaminD: template.vitaminD, vitaminE: template.vitaminE, vitaminK: template.vitaminK,
            vitaminB6: template.vitaminB6, vitaminB12: template.vitaminB12, folate: template.folate,
            magnesium: template.magnesium, zinc: template.zinc, phosphorus: template.phosphorus,
            thiamin: template.thiamin, riboflavin: template.riboflavin, niacin: template.niacin,
            manganese: template.manganese, selenium: template.selenium, copper: template.copper
        )
        todayNutrition.entries.append(entry)
        saveTodayNutrition()
        lastLoggedFoodName = entry.name
        checkMacroOverflow(prevCal: prevCal, prevPro: prevPro, prevCarbs: prevCarbs, prevFat: prevFat)
        incrementTotalMealsLogged()
    }

    func addFoodFromAIResult(_ result: NutritionLookupResult, mealType: MealType, imageURL: String? = nil) {
        let prevCal = todayNutrition.totalCalories
        let prevPro = todayNutrition.totalProtein
        let prevCarbs = todayNutrition.totalCarbs
        let prevFat = todayNutrition.totalFat
        let entry = FoodEntry(
            name: result.name,
            calories: result.calories,
            protein: result.protein,
            carbs: result.carbs,
            fat: result.fat,
            servingSize: result.servingSize,
            mealType: mealType,
            fiber: result.fiber, sugar: result.sugar, sodium: result.sodium,
            potassium: result.potassium, cholesterol: result.cholesterol,
            vitaminA: result.vitaminA, vitaminC: result.vitaminC,
            calcium: result.calcium, iron: result.iron,
            vitaminD: result.vitaminD, vitaminE: result.vitaminE, vitaminK: result.vitaminK,
            vitaminB6: result.vitaminB6, vitaminB12: result.vitaminB12, folate: result.folate,
            magnesium: result.magnesium, zinc: result.zinc, phosphorus: result.phosphorus,
            thiamin: result.thiamin, riboflavin: result.riboflavin, niacin: result.niacin,
            manganese: result.manganese, selenium: result.selenium, copper: result.copper,
            imageURL: imageURL
        )
        todayNutrition.entries.append(entry)
        saveTodayNutrition()
        lastLoggedFoodName = entry.name
        checkMacroOverflow(prevCal: prevCal, prevPro: prevPro, prevCarbs: prevCarbs, prevFat: prevFat)
        incrementTotalMealsLogged()
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
        let prevCal = todayNutrition.totalCalories
        let prevPro = todayNutrition.totalProtein
        let prevCarbs = todayNutrition.totalCarbs
        let prevFat = todayNutrition.totalFat
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
        lastLoggedFoodName = entry.name
        checkMacroOverflow(prevCal: prevCal, prevPro: prevPro, prevCarbs: prevCarbs, prevFat: prevFat)
        incrementTotalMealsLogged()
        resetManualEntry()
    }

    func resetManualEntry() {
        manualName = ""
        manualCalories = ""
        manualProtein = ""
        manualCarbs = ""
        manualFat = ""
    }

    var waterGlassesCount: Int {
        Int(todayNutrition.waterIntake / 8)
    }

    func addWater(_ ounces: Double) {
        todayNutrition.waterIntake += ounces
        saveTodayNutrition()
        onWaterChanged?(waterGlassesCount)
    }

    func removeWaterGlass() {
        guard todayNutrition.waterIntake >= 8 else { return }
        todayNutrition.waterIntake -= 8
        saveTodayNutrition()
        onWaterChanged?(waterGlassesCount)
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

    private func checkMacroOverflow(prevCal: Int, prevPro: Double, prevCarbs: Double, prevFat: Double) {
        let newCal = todayNutrition.totalCalories
        let newPro = todayNutrition.totalProtein
        let newCarbs = todayNutrition.totalCarbs
        let newFat = todayNutrition.totalFat
        if prevCal <= dailyCalorieGoal && newCal > dailyCalorieGoal {
            onMacroExceeded?("Calories", newCal - dailyCalorieGoal)
        } else if prevPro <= proteinGoal && newPro > proteinGoal {
            onMacroExceeded?("Protein", Int(newPro - proteinGoal))
        } else if prevCarbs <= carbsGoal && newCarbs > carbsGoal {
            onMacroExceeded?("Carbs", Int(newCarbs - carbsGoal))
        } else if prevFat <= fatGoal && newFat > fatGoal {
            onMacroExceeded?("Fat", Int(newFat - fatGoal))
        }
    }

    private var lastLoggedFoodName: String = ""

    private func incrementTotalMealsLogged() {
        totalMealsLogged += 1
        UserDefaults.standard.set(totalMealsLogged, forKey: "totalMealsLoggedAll")
        onFoodAdded?(totalMealsLogged, lastLoggedFoodName)
    }

    func loadTotalMealsLogged() {
        totalMealsLogged = UserDefaults.standard.integer(forKey: "totalMealsLoggedAll")
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
    var fiber: Double = 0
    var sugar: Double = 0
    var sodium: Double = 0
    var potassium: Double = 0
    var cholesterol: Double = 0
    var vitaminA: Double = 0
    var vitaminC: Double = 0
    var calcium: Double = 0
    var iron: Double = 0
    var vitaminD: Double = 0
    var vitaminE: Double = 0
    var vitaminK: Double = 0
    var vitaminB6: Double = 0
    var vitaminB12: Double = 0
    var folate: Double = 0
    var magnesium: Double = 0
    var zinc: Double = 0
    var phosphorus: Double = 0
    var thiamin: Double = 0
    var riboflavin: Double = 0
    var niacin: Double = 0
    var manganese: Double = 0
    var selenium: Double = 0
    var copper: Double = 0

    static let database: [FoodTemplate] = [
        FoodTemplate(name: "Grilled Chicken Breast", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: "Protein", fiber: 0, sugar: 0, sodium: 74, potassium: 256, cholesterol: 85, vitaminA: 6, vitaminC: 0, calcium: 15, iron: 1.0, vitaminD: 0.1, vitaminE: 0.3, vitaminK: 0, vitaminB6: 0.6, vitaminB12: 0.3, folate: 4, magnesium: 29, zinc: 1.0, phosphorus: 228, thiamin: 0.07, riboflavin: 0.11, niacin: 13.7, manganese: 0.02, selenium: 27.6, copper: 0.05),
        FoodTemplate(name: "Brown Rice (1 cup)", calories: 216, protein: 5, carbs: 45, fat: 1.8, category: "Carbs", fiber: 3.5, sugar: 0.7, sodium: 10, potassium: 84, cholesterol: 0, vitaminA: 0, vitaminC: 0, calcium: 20, iron: 0.8, vitaminD: 0, vitaminE: 0.1, vitaminK: 0.6, vitaminB6: 0.3, vitaminB12: 0, folate: 8, magnesium: 84, zinc: 1.2, phosphorus: 162, thiamin: 0.2, riboflavin: 0.02, niacin: 2.6, manganese: 1.8, selenium: 19.1, copper: 0.2),
        FoodTemplate(name: "Egg Whites (4)", calories: 68, protein: 14, carbs: 1, fat: 0, category: "Protein", fiber: 0, sugar: 1, sodium: 220, potassium: 216, cholesterol: 0, vitaminA: 0, vitaminC: 0, calcium: 9, iron: 0.1, vitaminD: 0, vitaminE: 0, vitaminK: 0, vitaminB6: 0.01, vitaminB12: 0.1, folate: 4, magnesium: 15, zinc: 0.1, phosphorus: 15, thiamin: 0.01, riboflavin: 0.44, niacin: 0.1, manganese: 0.01, selenium: 20.0, copper: 0.02),
        FoodTemplate(name: "Sweet Potato", calories: 103, protein: 2, carbs: 24, fat: 0, category: "Carbs", fiber: 3.8, sugar: 7.4, sodium: 41, potassium: 438, cholesterol: 0, vitaminA: 961, vitaminC: 19.6, calcium: 38, iron: 0.7, vitaminD: 0, vitaminE: 0.7, vitaminK: 2.3, vitaminB6: 0.3, vitaminB12: 0, folate: 6, magnesium: 27, zinc: 0.3, phosphorus: 54, thiamin: 0.1, riboflavin: 0.1, niacin: 1.5, manganese: 0.5, selenium: 0.2, copper: 0.16),
        FoodTemplate(name: "Salmon Fillet", calories: 208, protein: 20, carbs: 0, fat: 13, category: "Protein", fiber: 0, sugar: 0, sodium: 59, potassium: 363, cholesterol: 55, vitaminA: 12, vitaminC: 0, calcium: 12, iron: 0.3, vitaminD: 11.1, vitaminE: 3.6, vitaminK: 0.5, vitaminB6: 0.6, vitaminB12: 2.8, folate: 7, magnesium: 27, zinc: 0.4, phosphorus: 252, thiamin: 0.23, riboflavin: 0.11, niacin: 8.6, manganese: 0.02, selenium: 41.4, copper: 0.05),
        FoodTemplate(name: "Greek Yogurt", calories: 100, protein: 17, carbs: 6, fat: 0.7, category: "Protein", fiber: 0, sugar: 6, sodium: 47, potassium: 240, cholesterol: 10, vitaminA: 2, vitaminC: 0, calcium: 187, iron: 0.1, vitaminD: 0, vitaminE: 0, vitaminK: 0, vitaminB6: 0.1, vitaminB12: 1.3, folate: 15, magnesium: 22, zinc: 0.9, phosphorus: 229, thiamin: 0.04, riboflavin: 0.27, niacin: 0.2, manganese: 0.01, selenium: 9.7, copper: 0.03),
        FoodTemplate(name: "Banana", calories: 105, protein: 1.3, carbs: 27, fat: 0.4, category: "Fruit", fiber: 3.1, sugar: 14, sodium: 1, potassium: 422, cholesterol: 0, vitaminA: 3, vitaminC: 10.3, calcium: 6, iron: 0.3, vitaminD: 0, vitaminE: 0.1, vitaminK: 0.5, vitaminB6: 0.4, vitaminB12: 0, folate: 24, magnesium: 32, zinc: 0.2, phosphorus: 26, thiamin: 0.03, riboflavin: 0.07, niacin: 0.8, manganese: 0.3, selenium: 1.2, copper: 0.08),
        FoodTemplate(name: "Avocado", calories: 240, protein: 3, carbs: 12, fat: 22, category: "Fat", fiber: 10, sugar: 1, sodium: 11, potassium: 728, cholesterol: 0, vitaminA: 10, vitaminC: 15, calcium: 18, iron: 0.8, vitaminD: 0, vitaminE: 3.1, vitaminK: 31.5, vitaminB6: 0.4, vitaminB12: 0, folate: 122, magnesium: 44, zinc: 1.0, phosphorus: 78, thiamin: 0.1, riboflavin: 0.2, niacin: 2.6, manganese: 0.2, selenium: 0.6, copper: 0.28),
        FoodTemplate(name: "Oatmeal (1 cup)", calories: 158, protein: 6, carbs: 27, fat: 3, category: "Carbs", fiber: 4, sugar: 1.1, sodium: 9, potassium: 143, cholesterol: 0, vitaminA: 0, vitaminC: 0, calcium: 21, iron: 2.1, vitaminD: 0, vitaminE: 0.2, vitaminK: 0, vitaminB6: 0.05, vitaminB12: 0, folate: 14, magnesium: 56, zinc: 1.5, phosphorus: 180, thiamin: 0.26, riboflavin: 0.05, niacin: 0.6, manganese: 1.7, selenium: 13.0, copper: 0.17),
        FoodTemplate(name: "Whey Protein Shake", calories: 120, protein: 24, carbs: 3, fat: 1, category: "Protein", fiber: 0, sugar: 2, sodium: 130, potassium: 160, cholesterol: 35, vitaminA: 0, vitaminC: 0, calcium: 120, iron: 0.5, vitaminD: 0, vitaminE: 0, vitaminK: 0, vitaminB6: 0, vitaminB12: 0, folate: 0, magnesium: 20, zinc: 1.5, phosphorus: 100, thiamin: 0, riboflavin: 0, niacin: 0, manganese: 0, selenium: 0, copper: 0),
        FoodTemplate(name: "Broccoli (1 cup)", calories: 55, protein: 3.7, carbs: 11, fat: 0.6, category: "Vegetables", fiber: 5.1, sugar: 2.2, sodium: 64, potassium: 457, cholesterol: 0, vitaminA: 60, vitaminC: 135, calcium: 62, iron: 1.0, vitaminD: 0, vitaminE: 1.5, vitaminK: 220, vitaminB6: 0.2, vitaminB12: 0, folate: 108, magnesium: 33, zinc: 0.6, phosphorus: 105, thiamin: 0.1, riboflavin: 0.2, niacin: 1.0, manganese: 0.3, selenium: 2.5, copper: 0.06),
        FoodTemplate(name: "Almonds (1 oz)", calories: 164, protein: 6, carbs: 6, fat: 14, category: "Fat", fiber: 3.5, sugar: 1.2, sodium: 0, potassium: 208, cholesterol: 0, vitaminA: 0, vitaminC: 0, calcium: 76, iron: 1.1, vitaminD: 0, vitaminE: 7.3, vitaminK: 0, vitaminB6: 0.04, vitaminB12: 0, folate: 14, magnesium: 77, zinc: 0.9, phosphorus: 137, thiamin: 0.06, riboflavin: 0.29, niacin: 1.0, manganese: 0.6, selenium: 1.2, copper: 0.29),
        FoodTemplate(name: "Turkey Breast", calories: 135, protein: 30, carbs: 0, fat: 1, category: "Protein", fiber: 0, sugar: 0, sodium: 48, potassium: 249, cholesterol: 71, vitaminA: 0, vitaminC: 0, calcium: 10, iron: 0.7, vitaminD: 0.1, vitaminE: 0.1, vitaminK: 0, vitaminB6: 0.8, vitaminB12: 0.4, folate: 6, magnesium: 27, zinc: 1.3, phosphorus: 210, thiamin: 0.04, riboflavin: 0.12, niacin: 11.8, manganese: 0.02, selenium: 30.7, copper: 0.04),
        FoodTemplate(name: "Quinoa (1 cup)", calories: 222, protein: 8, carbs: 39, fat: 3.5, category: "Carbs", fiber: 5.2, sugar: 1.6, sodium: 13, potassium: 318, cholesterol: 0, vitaminA: 0, vitaminC: 0, calcium: 31, iron: 2.8, vitaminD: 0, vitaminE: 1.2, vitaminK: 0, vitaminB6: 0.2, vitaminB12: 0, folate: 78, magnesium: 118, zinc: 2.0, phosphorus: 281, thiamin: 0.2, riboflavin: 0.2, niacin: 0.8, manganese: 1.2, selenium: 5.2, copper: 0.36),
        FoodTemplate(name: "Peanut Butter (2 tbsp)", calories: 188, protein: 8, carbs: 6, fat: 16, category: "Fat", fiber: 1.9, sugar: 3.4, sodium: 136, potassium: 208, cholesterol: 0, vitaminA: 0, vitaminC: 0, calcium: 17, iron: 0.6, vitaminD: 0, vitaminE: 2.9, vitaminK: 0, vitaminB6: 0.18, vitaminB12: 0, folate: 29, magnesium: 51, zinc: 0.9, phosphorus: 107, thiamin: 0.04, riboflavin: 0.03, niacin: 4.3, manganese: 0.5, selenium: 2.0, copper: 0.14),
        FoodTemplate(name: "Steak (6 oz)", calories: 340, protein: 42, carbs: 0, fat: 18, category: "Protein", fiber: 0, sugar: 0, sodium: 68, potassium: 530, cholesterol: 120, vitaminA: 0, vitaminC: 0, calcium: 18, iron: 3.8, vitaminD: 0.1, vitaminE: 0.4, vitaminK: 1.5, vitaminB6: 0.7, vitaminB12: 5.9, folate: 12, magnesium: 32, zinc: 6.4, phosphorus: 312, thiamin: 0.07, riboflavin: 0.17, niacin: 7.6, manganese: 0.01, selenium: 33.0, copper: 0.08),
    ]
}
