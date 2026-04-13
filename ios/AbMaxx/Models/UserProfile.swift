import Foundation

nonisolated struct UserProfile: Codable, Sendable {
    var username: String = ""
    var gender: Gender = .male
    var dateOfBirth: Date = Date()
    var activityLevel: ActivityLevel = .sedentary
    var goal: AbsGoal = .visibleAbs
    var heightFeet: Int = 5
    var heightInches: Int = 10
    var weightLbs: Double = 170
    var useMetric: Bool = false
    var absDescription: AbsDescription = .barelyVisible
    var bodyFatCategory: BodyFatCategory = .athletic
    var planSpeed: PlanSpeed = .recommended
    var absTrainingFrequency: AbsTrainingFrequency = .threeToFour
    var commitmentLevel: Int = 3
    var currentXP: Int = 0
    var currentPhase: Int = 0
    var currentLevel: Int = 0
    var totalScansUsed: Int = 0
    var streakDays: Int = 0
    var lastActiveDate: Date?
    var isSubscribed: Bool = false
    var hasCompletedOnboarding: Bool = false
    var transformationStartDate: Date?
    var equipmentSetting: EquipmentSetting = .home
    var hasPersonalCoach: Bool = false
    var trainingSource: String? = nil
    var biggestStruggles: Set<String> = []
    var accomplishGoal: String?

    var displayName: String {
        username.isEmpty ? "AbMaxx User" : username
    }

    var scanBodyFatEstimate: Double?
    var scanAbsStructure: String?
    var scanDailyCalorieTarget: Int?
    var scanProteinG: Int?
    var scanCarbsG: Int?
    var scanFatG: Int?
    var scanDeficit: Int?
    var scanUpperAbsWeeks: Int?
    var scanObliquesWeeks: Int?
    var scanLowerAbsWeeks: Int?
    var scanVtaperWeeks: Int?
    var selectedCalorieDeficit: Int = 400

    var estimatedWeeksToAbs: Int {
        let base: Int
        switch bodyFatCategory {
        case .lean: base = 6
        case .athletic: base = 10
        case .average: base = 16
        case .aboveAverage: base = 24
        }
        let modifier: Double
        switch activityLevel {
        case .veryActive: modifier = 0.7
        case .moderatelyActive: modifier = 0.85
        case .lightlyActive: modifier = 1.0
        case .sedentary: modifier = 1.3
        }
        return max(Int(Double(base) * modifier), 4)
    }

    var daysOnProgram: Int {
        guard let start = transformationStartDate else { return 0 }
        return max(Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0, 0)
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 25
    }

    var heightInCm: Double {
        if useMetric {
            return Double(heightFeet)
        }
        return Double(heightFeet) * 30.48 + Double(heightInches) * 2.54
    }

    var weightInKg: Double {
        if useMetric {
            return weightLbs
        }
        return weightLbs * 0.453592
    }

    var bmr: Double {
        let base = 10.0 * weightInKg + 6.25 * heightInCm - 5.0 * Double(age)
        switch gender {
        case .male: return base + 5
        case .female: return base - 161
        case .other: return base - 78
        }
    }

    var tdee: Double {
        let multiplier: Double
        switch activityLevel {
        case .sedentary: multiplier = 1.2
        case .lightlyActive: multiplier = 1.375
        case .moderatelyActive: multiplier = 1.55
        case .veryActive: multiplier = 1.725
        }
        return bmr * multiplier
    }

    var weightInLbs: Double {
        if useMetric {
            return weightLbs * 2.20462
        }
        return weightLbs
    }

    var calculatedCalorieGoal: Int {
        let deficitPercentage: Double
        if let bodyFatPercent = scanBodyFatEstimate {
            switch bodyFatPercent {
            case ..<12:   deficitPercentage = 0.05
            case 12..<15: deficitPercentage = 0.10
            case 15..<17: deficitPercentage = 0.15
            case 17..<20: deficitPercentage = 0.20
            default:      deficitPercentage = 0.22
            }
        } else {
            switch goal {
            case .loseBellyFat:  deficitPercentage = 0.20
            case .visibleAbs:    deficitPercentage = 0.15
            case .sixPack:       deficitPercentage = 0.12
            case .coreStrength:  deficitPercentage = 0.0
            }
        }
        let deficit = tdee * deficitPercentage
        let finalDeficit = min(deficit, 500)
        let targetCalories = max(tdee - finalDeficit, bmr)
        return Int(round(targetCalories))
    }

    var calculatedProteinGoal: Double {
        return weightInLbs * 1.0
    }

    var calculatedFatGoal: Double {
        return Double(calculatedCalorieGoal) * 0.25 / 9.0
    }

    var calculatedCarbsGoal: Double {
        let proteinCal = calculatedProteinGoal * 4.0
        let fatCal = calculatedFatGoal * 9.0
        let remaining = Double(calculatedCalorieGoal) - proteinCal - fatCal
        return max(remaining / 4.0, 50)
    }

    func toDailyNutrition() -> DailyNutrition {
        var n = DailyNutrition()
        let deficitBasedGoal = selectedCalorieDeficit > 0
            ? max(1200, Int(tdee) - selectedCalorieDeficit)
            : calculatedCalorieGoal
        n.calorieGoal = deficitBasedGoal
        let calGoalDouble = Double(deficitBasedGoal)
        n.proteinGoal = weightInLbs * 1.0
        let proteinCal = n.proteinGoal * 4.0
        let fatCal = calGoalDouble * 0.25
        n.fatGoal = fatCal / 9.0
        n.carbsGoal = max((calGoalDouble - proteinCal - fatCal) / 4.0, 50)
        n.waterGoal = weightInKg > 90 ? 10 : (weightInKg > 70 ? 8 : 7)
        return n
    }
}

nonisolated enum Gender: String, Codable, CaseIterable, Sendable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

nonisolated enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case moderatelyActive = "Moderately Active"
    case veryActive = "Very Active"

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "Moderate": self = .moderatelyActive
        case "Extra Active": self = .veryActive
        default:
            guard let val = ActivityLevel(rawValue: raw) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown ActivityLevel: \(raw)")
            }
            self = val
        }
    }

    var description: String {
        switch self {
        case .sedentary: "Little to no exercise"
        case .lightlyActive: "Light exercise 1-3 days/week"
        case .moderatelyActive: "Moderate exercise 3-5 days/week"
        case .veryActive: "Hard exercise 6-7 days/week"
        }
    }

    var detail: String { description }

    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .lightlyActive: 1.375
        case .moderatelyActive: 1.55
        case .veryActive: 1.725
        }
    }
}

nonisolated enum AbsGoal: String, Codable, CaseIterable, Sendable {
    case visibleAbs = "Get Visible Abs"
    case sixPack = "Get a Six-Pack"
    case loseBellyFat = "Lose Belly Fat"
    case coreStrength = "Build Core Strength"

    var icon: String {
        switch self {
        case .visibleAbs: "eye.fill"
        case .sixPack: "trophy.fill"
        case .loseBellyFat: "flame.fill"
        case .coreStrength: "bolt.fill"
        }
    }

    var calorieHint: String {
        switch self {
        case .visibleAbs: "Moderate calorie deficit"
        case .sixPack: "Lean cut with high protein"
        case .loseBellyFat: "Aggressive calorie deficit"
        case .coreStrength: "Maintenance calories"
        }
    }
}

nonisolated enum AbsDescription: String, Codable, CaseIterable, Sendable {
    case barelyVisible = "Barely Visible"
    case slightOutline = "Slight Outline"
    case topTwoVisible = "Top Two Visible"
    case fourPackVisible = "Four Pack Visible"
    case almostThere = "Almost a Six-Pack"

    var detail: String {
        switch self {
        case .barelyVisible: "Can't see any definition"
        case .slightOutline: "Can see faint lines in good lighting"
        case .topTwoVisible: "Upper abs are starting to show"
        case .fourPackVisible: "Top four abs visible"
        case .almostThere: "Close to full six-pack definition"
        }
    }
}

nonisolated enum BodyFatCategory: String, Codable, CaseIterable, Sendable {
    case lean = "Lean"
    case athletic = "Athletic"
    case average = "Average"
    case aboveAverage = "Above Average"

    var rangeText: String {
        switch self {
        case .lean: "8-12%"
        case .athletic: "12-18%"
        case .average: "18-25%"
        case .aboveAverage: "25%+"
        }
    }

    var icon: String {
        switch self {
        case .lean: "figure.run"
        case .athletic: "figure.strengthtraining.traditional"
        case .average: "figure.walk"
        case .aboveAverage: "figure.stand"
        }
    }
}

nonisolated enum AbsTrainingFrequency: String, Codable, CaseIterable, Sendable {
    case zeroToTwo = "0-2 times"
    case threeToFour = "3-4 times"
    case fiveOrMore = "5+ times"

    var icon: String {
        switch self {
        case .zeroToTwo: "figure.cooldown"
        case .threeToFour: "figure.core.training"
        case .fiveOrMore: "flame.fill"
        }
    }

    var detail: String {
        switch self {
        case .zeroToTwo: "Just getting started"
        case .threeToFour: "Solid consistency"
        case .fiveOrMore: "Beast mode"
        }
    }
}

nonisolated enum EquipmentSetting: String, Codable, CaseIterable, Sendable {
    case home = "Home"
    case gym = "Gym"
    case both = "Both"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .gym: return "dumbbell.fill"
        case .both: return "figure.strengthtraining.traditional"
        }
    }

    var detail: String {
        switch self {
        case .home: return "Bodyweight exercises only — no equipment needed"
        case .gym: return "Full gym access with cables, benches & weights"
        case .both: return "Mix of home & gym exercises for maximum variety"
        }
    }
}

nonisolated enum PlanSpeed: String, Codable, CaseIterable, Sendable {
    case slow = "Slow & Steady"
    case recommended = "Recommended"
    case fast = "Fast & Intense"

    var icon: String {
        switch self {
        case .slow: "bicycle"
        case .recommended: "car.fill"
        case .fast: "airplane"
        }
    }

    var description: String {
        switch self {
        case .slow: "Take your time with gradual progress. Best for beginners."
        case .recommended: "Balanced approach. Consistent progress without burnout."
        case .fast: "Maximum intensity. For those ready to push their limits."
        }
    }
}
