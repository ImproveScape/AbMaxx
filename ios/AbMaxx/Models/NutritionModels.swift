import Foundation

nonisolated struct FoodEntry: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: String
    var quantity: Double
    var mealType: MealType
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var potassium: Double
    var cholesterol: Double
    var vitaminA: Double
    var vitaminC: Double
    var calcium: Double
    var iron: Double
    var vitaminD: Double
    var vitaminE: Double
    var vitaminK: Double
    var vitaminB6: Double
    var vitaminB12: Double
    var folate: Double
    var magnesium: Double
    var zinc: Double
    var phosphorus: Double
    var thiamin: Double
    var riboflavin: Double
    var niacin: Double
    var manganese: Double
    var selenium: Double
    var copper: Double

    var imageURL: String?
    var timestamp: Date

    var adjustedCalories: Int { Int(Double(calories) * quantity) }
    var adjustedProtein: Double { protein * quantity }
    var adjustedCarbs: Double { carbs * quantity }
    var adjustedFat: Double { fat * quantity }

    init(
        name: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        servingSize: String = "1 serving",
        quantity: Double = 1.0,
        mealType: MealType,
        fiber: Double = 0, sugar: Double = 0, sodium: Double = 0,
        potassium: Double = 0, cholesterol: Double = 0,
        vitaminA: Double = 0, vitaminC: Double = 0,
        calcium: Double = 0, iron: Double = 0,
        vitaminD: Double = 0, vitaminE: Double = 0, vitaminK: Double = 0,
        vitaminB6: Double = 0, vitaminB12: Double = 0, folate: Double = 0,
        magnesium: Double = 0, zinc: Double = 0, phosphorus: Double = 0,
        thiamin: Double = 0, riboflavin: Double = 0, niacin: Double = 0,
        manganese: Double = 0, selenium: Double = 0, copper: Double = 0,
        imageURL: String? = nil, timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.quantity = quantity
        self.mealType = mealType
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.potassium = potassium
        self.cholesterol = cholesterol
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.calcium = calcium
        self.iron = iron
        self.vitaminD = vitaminD
        self.vitaminE = vitaminE
        self.vitaminK = vitaminK
        self.vitaminB6 = vitaminB6
        self.vitaminB12 = vitaminB12
        self.folate = folate
        self.magnesium = magnesium
        self.zinc = zinc
        self.phosphorus = phosphorus
        self.thiamin = thiamin
        self.riboflavin = riboflavin
        self.niacin = niacin
        self.manganese = manganese
        self.selenium = selenium
        self.copper = copper
        self.imageURL = imageURL
        self.timestamp = timestamp
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        calories = try c.decode(Int.self, forKey: .calories)
        protein = try c.decode(Double.self, forKey: .protein)
        carbs = try c.decode(Double.self, forKey: .carbs)
        fat = try c.decode(Double.self, forKey: .fat)
        servingSize = try c.decodeIfPresent(String.self, forKey: .servingSize) ?? "1 serving"
        quantity = try c.decodeIfPresent(Double.self, forKey: .quantity) ?? 1.0
        mealType = try c.decode(MealType.self, forKey: .mealType)
        fiber = try c.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
        sugar = try c.decodeIfPresent(Double.self, forKey: .sugar) ?? 0
        sodium = try c.decodeIfPresent(Double.self, forKey: .sodium) ?? 0
        potassium = try c.decodeIfPresent(Double.self, forKey: .potassium) ?? 0
        cholesterol = try c.decodeIfPresent(Double.self, forKey: .cholesterol) ?? 0
        vitaminA = try c.decodeIfPresent(Double.self, forKey: .vitaminA) ?? 0
        vitaminC = try c.decodeIfPresent(Double.self, forKey: .vitaminC) ?? 0
        calcium = try c.decodeIfPresent(Double.self, forKey: .calcium) ?? 0
        iron = try c.decodeIfPresent(Double.self, forKey: .iron) ?? 0
        vitaminD = try c.decodeIfPresent(Double.self, forKey: .vitaminD) ?? 0
        vitaminE = try c.decodeIfPresent(Double.self, forKey: .vitaminE) ?? 0
        vitaminK = try c.decodeIfPresent(Double.self, forKey: .vitaminK) ?? 0
        vitaminB6 = try c.decodeIfPresent(Double.self, forKey: .vitaminB6) ?? 0
        vitaminB12 = try c.decodeIfPresent(Double.self, forKey: .vitaminB12) ?? 0
        folate = try c.decodeIfPresent(Double.self, forKey: .folate) ?? 0
        magnesium = try c.decodeIfPresent(Double.self, forKey: .magnesium) ?? 0
        zinc = try c.decodeIfPresent(Double.self, forKey: .zinc) ?? 0
        phosphorus = try c.decodeIfPresent(Double.self, forKey: .phosphorus) ?? 0
        thiamin = try c.decodeIfPresent(Double.self, forKey: .thiamin) ?? 0
        riboflavin = try c.decodeIfPresent(Double.self, forKey: .riboflavin) ?? 0
        niacin = try c.decodeIfPresent(Double.self, forKey: .niacin) ?? 0
        manganese = try c.decodeIfPresent(Double.self, forKey: .manganese) ?? 0
        selenium = try c.decodeIfPresent(Double.self, forKey: .selenium) ?? 0
        copper = try c.decodeIfPresent(Double.self, forKey: .copper) ?? 0
        imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        timestamp = try c.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
    }
}

nonisolated struct NutritionDailyLog: Codable, Sendable {
    var entries: [FoodEntry] = []
    var waterIntake: Double = 0

    var totalCalories: Int { entries.reduce(0) { $0 + $1.adjustedCalories } }
    var totalProtein: Double { entries.reduce(0) { $0 + $1.adjustedProtein } }
    var totalCarbs: Double { entries.reduce(0) { $0 + $1.adjustedCarbs } }
    var totalFat: Double { entries.reduce(0) { $0 + $1.adjustedFat } }

    var totalFiber: Double { entries.reduce(0) { $0 + $1.fiber * $1.quantity } }
    var totalSugar: Double { entries.reduce(0) { $0 + $1.sugar * $1.quantity } }
    var totalSodium: Double { entries.reduce(0) { $0 + $1.sodium * $1.quantity } }
    var totalPotassium: Double { entries.reduce(0) { $0 + $1.potassium * $1.quantity } }
    var totalCholesterol: Double { entries.reduce(0) { $0 + $1.cholesterol * $1.quantity } }
    var totalVitaminA: Double { entries.reduce(0) { $0 + $1.vitaminA * $1.quantity } }
    var totalVitaminC: Double { entries.reduce(0) { $0 + $1.vitaminC * $1.quantity } }
    var totalCalcium: Double { entries.reduce(0) { $0 + $1.calcium * $1.quantity } }
    var totalIron: Double { entries.reduce(0) { $0 + $1.iron * $1.quantity } }
    var totalVitaminD: Double { entries.reduce(0) { $0 + $1.vitaminD * $1.quantity } }
    var totalVitaminE: Double { entries.reduce(0) { $0 + $1.vitaminE * $1.quantity } }
    var totalVitaminK: Double { entries.reduce(0) { $0 + $1.vitaminK * $1.quantity } }
    var totalVitaminB6: Double { entries.reduce(0) { $0 + $1.vitaminB6 * $1.quantity } }
    var totalVitaminB12: Double { entries.reduce(0) { $0 + $1.vitaminB12 * $1.quantity } }
    var totalFolate: Double { entries.reduce(0) { $0 + $1.folate * $1.quantity } }
    var totalMagnesium: Double { entries.reduce(0) { $0 + $1.magnesium * $1.quantity } }
    var totalZinc: Double { entries.reduce(0) { $0 + $1.zinc * $1.quantity } }
    var totalPhosphorus: Double { entries.reduce(0) { $0 + $1.phosphorus * $1.quantity } }
    var totalThiamin: Double { entries.reduce(0) { $0 + $1.thiamin * $1.quantity } }
    var totalRiboflavin: Double { entries.reduce(0) { $0 + $1.riboflavin * $1.quantity } }
    var totalNiacin: Double { entries.reduce(0) { $0 + $1.niacin * $1.quantity } }
    var totalManganese: Double { entries.reduce(0) { $0 + $1.manganese * $1.quantity } }
    var totalSelenium: Double { entries.reduce(0) { $0 + $1.selenium * $1.quantity } }
    var totalCopper: Double { entries.reduce(0) { $0 + $1.copper * $1.quantity } }

    nonisolated init() {}

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entries = try c.decodeIfPresent([FoodEntry].self, forKey: .entries) ?? []
        waterIntake = try c.decodeIfPresent(Double.self, forKey: .waterIntake) ?? 0
    }
}

nonisolated struct NutritionLookupResult: Sendable, Identifiable {
    let id: UUID = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String
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
}

nonisolated struct EnrichedFoodData: Sendable {
    let healthScore: Int
    let healthLabel: String
    let healthDescription: String
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let potassium: Double
    let cholesterol: Double
    let vitaminA: Double
    let vitaminC: Double
    let calcium: Double
    let iron: Double
    let vitaminD: Double?
    let vitaminE: Double?
    let vitaminK: Double?
    let vitaminB6: Double?
    let vitaminB12: Double?
    let folate: Double?
    let magnesium: Double?
    let zinc: Double?
    let phosphorus: Double?
    let thiamin: Double?
    let riboflavin: Double?
    let niacin: Double?
    let manganese: Double?
    let selenium: Double?
    let copper: Double?
}

nonisolated enum BiologicalSex: String, Codable, CaseIterable, Sendable {
    case male = "Male"
    case female = "Female"
}

nonisolated enum WeightGoalType: String, Codable, CaseIterable, Sendable {
    case cut = "Cut"
    case maintain = "Maintain"
    case bulk = "Bulk"

    var icon: String {
        switch self {
        case .cut: "arrow.down.circle.fill"
        case .maintain: "equal.circle.fill"
        case .bulk: "arrow.up.circle.fill"
        }
    }
}

nonisolated enum WeeklyWeightChange: String, Codable, CaseIterable, Identifiable, Sendable {
    case slow = "0.5 lb/wk"
    case moderate = "1 lb/wk"
    case aggressive = "1.5 lb/wk"
    case extreme = "2 lb/wk"

    var id: String { rawValue }

    var dailyCalorieAdjustment: Int {
        switch self {
        case .slow: 250
        case .moderate: 500
        case .aggressive: 750
        case .extreme: 1000
        }
    }
}

nonisolated struct NutritionGoals: Codable, Sendable {
    var age: Int = 25
    var sex: BiologicalSex = .male
    var weightLbs: Double = 170
    var heightFeet: Int = 5
    var heightInches: Int = 10
    var activityLevel: ActivityLevel = .moderatelyActive
    var weightGoalType: WeightGoalType = .cut
    var targetWeightLbs: Double = 160
    var weeklyChange: WeeklyWeightChange = .moderate
    var waterGoalOz: Double = 128
    var customCalorieGoal: Int?
    var customProteinGoal: Double?
    var customCarbsGoal: Double?
    var customFatGoal: Double?

    var heightCm: Double {
        Double(heightFeet * 12 + heightInches) * 2.54
    }

    var weightKg: Double {
        weightLbs / 2.205
    }

    var bmr: Double {
        switch sex {
        case .male:
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        case .female:
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
    }

    var tdee: Double {
        bmr * activityLevel.multiplier
    }

    var calculatedCalorieGoal: Int {
        if let custom = customCalorieGoal { return custom }
        var base = Int(tdee)
        switch weightGoalType {
        case .cut: base -= weeklyChange.dailyCalorieAdjustment
        case .maintain: break
        case .bulk: base += weeklyChange.dailyCalorieAdjustment
        }
        return max(1200, base)
    }

    var calculatedProteinGoal: Double {
        if let custom = customProteinGoal { return custom }
        return Double(calculatedCalorieGoal) * 0.30 / 4.0
    }

    var calculatedCarbsGoal: Double {
        if let custom = customCarbsGoal { return custom }
        return Double(calculatedCalorieGoal) * 0.40 / 4.0
    }

    var calculatedFatGoal: Double {
        if let custom = customFatGoal { return custom }
        return Double(calculatedCalorieGoal) * 0.30 / 9.0
    }

    var weeksToGoal: Int? {
        guard weightGoalType != .maintain else { return nil }
        let diff = abs(weightLbs - targetWeightLbs)
        guard diff > 0 else { return nil }
        let lbsPerWeek: Double
        switch weeklyChange {
        case .slow: lbsPerWeek = 0.5
        case .moderate: lbsPerWeek = 1.0
        case .aggressive: lbsPerWeek = 1.5
        case .extreme: lbsPerWeek = 2.0
        }
        return Int(ceil(diff / lbsPerWeek))
    }

    nonisolated init() {}

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        age = try c.decodeIfPresent(Int.self, forKey: .age) ?? 25
        sex = try c.decodeIfPresent(BiologicalSex.self, forKey: .sex) ?? .male
        weightLbs = try c.decodeIfPresent(Double.self, forKey: .weightLbs) ?? 170
        heightFeet = try c.decodeIfPresent(Int.self, forKey: .heightFeet) ?? 5
        heightInches = try c.decodeIfPresent(Int.self, forKey: .heightInches) ?? 10
        activityLevel = try c.decodeIfPresent(ActivityLevel.self, forKey: .activityLevel) ?? .moderatelyActive
        weightGoalType = try c.decodeIfPresent(WeightGoalType.self, forKey: .weightGoalType) ?? .cut
        targetWeightLbs = try c.decodeIfPresent(Double.self, forKey: .targetWeightLbs) ?? 160
        weeklyChange = try c.decodeIfPresent(WeeklyWeightChange.self, forKey: .weeklyChange) ?? .moderate
        waterGoalOz = try c.decodeIfPresent(Double.self, forKey: .waterGoalOz) ?? 128
        customCalorieGoal = try c.decodeIfPresent(Int.self, forKey: .customCalorieGoal)
        customProteinGoal = try c.decodeIfPresent(Double.self, forKey: .customProteinGoal)
        customCarbsGoal = try c.decodeIfPresent(Double.self, forKey: .customCarbsGoal)
        customFatGoal = try c.decodeIfPresent(Double.self, forKey: .customFatGoal)
    }
}
