import Foundation

nonisolated enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case preworkout = "Pre-Workout"
    case postworkout = "Post-Workout"

    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "leaf.fill"
        case .preworkout: "bolt.fill"
        case .postworkout: "figure.cooldown"
        }
    }

    var defaultTime: String {
        switch self {
        case .breakfast: "8:00 AM"
        case .lunch: "12:30 PM"
        case .dinner: "7:00 PM"
        case .snack: "3:00 PM"
        case .preworkout: "5:00 PM"
        case .postworkout: "6:30 PM"
        }
    }
}

nonisolated struct FoodItem: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    let mealType: MealType
    var date: Date = Date()
    var imageURL: String?

    init(name: String, calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double = 0, sugar: Double = 0, sodium: Double = 0, mealType: MealType, date: Date = Date(), imageURL: String? = nil) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.mealType = mealType
        self.date = date
        self.imageURL = imageURL
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Double.self, forKey: .protein)
        carbs = try container.decode(Double.self, forKey: .carbs)
        fat = try container.decode(Double.self, forKey: .fat)
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
        sugar = try container.decodeIfPresent(Double.self, forKey: .sugar) ?? 0
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium) ?? 0
        mealType = try container.decode(MealType.self, forKey: .mealType)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
    }
}

nonisolated struct DailyNutrition: Codable, Sendable {
    var calorieGoal: Int = 2200
    var proteinGoal: Double = 180
    var carbsGoal: Double = 220
    var fatGoal: Double = 70
    var fiberGoal: Double = 30
    var sugarGoal: Double = 50
    var sodiumGoal: Double = 2300
    var waterGoal: Int = 8

    nonisolated init() {}

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calorieGoal = try container.decodeIfPresent(Int.self, forKey: .calorieGoal) ?? 2200
        proteinGoal = try container.decodeIfPresent(Double.self, forKey: .proteinGoal) ?? 180
        carbsGoal = try container.decodeIfPresent(Double.self, forKey: .carbsGoal) ?? 220
        fatGoal = try container.decodeIfPresent(Double.self, forKey: .fatGoal) ?? 70
        fiberGoal = try container.decodeIfPresent(Double.self, forKey: .fiberGoal) ?? 30
        sugarGoal = try container.decodeIfPresent(Double.self, forKey: .sugarGoal) ?? 50
        sodiumGoal = try container.decodeIfPresent(Double.self, forKey: .sodiumGoal) ?? 2300
        waterGoal = try container.decodeIfPresent(Int.self, forKey: .waterGoal) ?? 8
    }
}

nonisolated struct QuickAddPreset: Identifiable, Sendable {
    let id: String
    let name: String
    let emoji: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double

    init(id: String, name: String, emoji: String, calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double = 0, sugar: Double = 0, sodium: Double = 0) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
    }

    static let presets: [QuickAddPreset] = [
        QuickAddPreset(id: "chicken_breast", name: "Chicken Breast", emoji: "🍗", calories: 284, protein: 53, carbs: 0, fat: 6, fiber: 0, sugar: 0, sodium: 82),
        QuickAddPreset(id: "rice_cup", name: "Rice (1 cup)", emoji: "🍚", calories: 206, protein: 4, carbs: 45, fat: 0.4, fiber: 0.6, sugar: 0, sodium: 1),
        QuickAddPreset(id: "eggs_2", name: "2 Eggs", emoji: "🥚", calories: 156, protein: 12, carbs: 1, fat: 11, fiber: 0, sugar: 1, sodium: 142),
        QuickAddPreset(id: "protein_shake", name: "Protein Shake", emoji: "🥤", calories: 160, protein: 30, carbs: 5, fat: 2, fiber: 1, sugar: 2, sodium: 150),
        QuickAddPreset(id: "banana", name: "Banana", emoji: "🍌", calories: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3.1, sugar: 14, sodium: 1),
        QuickAddPreset(id: "oatmeal", name: "Oatmeal", emoji: "🥣", calories: 154, protein: 5, carbs: 27, fat: 3, fiber: 4, sugar: 1, sodium: 2),
        QuickAddPreset(id: "salad", name: "Salad Bowl", emoji: "🥗", calories: 180, protein: 8, carbs: 15, fat: 10, fiber: 4, sugar: 5, sodium: 300),
        QuickAddPreset(id: "steak", name: "Steak (6oz)", emoji: "🥩", calories: 340, protein: 42, carbs: 0, fat: 18, fiber: 0, sugar: 0, sodium: 65),
        QuickAddPreset(id: "greek_yogurt", name: "Greek Yogurt", emoji: "🍦", calories: 130, protein: 17, carbs: 6, fat: 4, fiber: 0, sugar: 5, sodium: 50),
        QuickAddPreset(id: "avocado", name: "Avocado", emoji: "🥑", calories: 234, protein: 3, carbs: 12, fat: 21, fiber: 10, sugar: 1, sodium: 10),
        QuickAddPreset(id: "almonds", name: "Almonds (1oz)", emoji: "🥜", calories: 164, protein: 6, carbs: 6, fat: 14, fiber: 3.5, sugar: 1, sodium: 0),
        QuickAddPreset(id: "sweet_potato", name: "Sweet Potato", emoji: "🍠", calories: 112, protein: 2, carbs: 26, fat: 0.1, fiber: 3.8, sugar: 5, sodium: 36),
        QuickAddPreset(id: "salmon", name: "Salmon (4oz)", emoji: "🐟", calories: 233, protein: 25, carbs: 0, fat: 14, fiber: 0, sugar: 0, sodium: 59),
        QuickAddPreset(id: "broccoli", name: "Broccoli (1 cup)", emoji: "🥦", calories: 55, protein: 4, carbs: 11, fat: 0.6, fiber: 5.1, sugar: 2, sodium: 33),
        QuickAddPreset(id: "pasta", name: "Pasta (1 cup)", emoji: "🍝", calories: 220, protein: 8, carbs: 43, fat: 1.3, fiber: 2.5, sugar: 1, sodium: 1),
        QuickAddPreset(id: "apple", name: "Apple", emoji: "🍎", calories: 95, protein: 0.5, carbs: 25, fat: 0.3, fiber: 4.4, sugar: 19, sodium: 2),
    ]
}
