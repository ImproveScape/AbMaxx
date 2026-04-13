import Foundation

nonisolated enum NutritionCategory: String, Codable, CaseIterable, Sendable {
    case avoid = "AVOID"
    case positive = "DO"
    case timing = "TIMING"

    var icon: String {
        switch self {
        case .avoid: "xmark.circle.fill"
        case .positive: "checkmark.circle.fill"
        case .timing: "clock.fill"
        }
    }

    var color: String {
        switch self {
        case .avoid: "red"
        case .positive: "green"
        case .timing: "blue"
        }
    }
}

nonisolated struct NutritionTask: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let description: String
    let category: NutritionCategory
    let whyMatters: [String]
    let whatYoullNotice: [String]
    let xp: Int

    static let allTasks: [NutritionTask] = [
        NutritionTask(id: "avoid_sugar", title: "Cut Added Sugar", description: "Avoid sugary drinks and snacks today", category: .avoid, whyMatters: ["Sugar causes bloating", "Spikes insulin, promotes fat storage"], whatYoullNotice: ["Less bloating by evening", "More stable energy"], xp: 15),
        NutritionTask(id: "avoid_alcohol", title: "Skip Alcohol", description: "No alcoholic beverages today", category: .avoid, whyMatters: ["Alcohol slows fat metabolism", "Causes water retention"], whatYoullNotice: ["Better sleep quality", "Less facial puffiness"], xp: 15),
        NutritionTask(id: "avoid_processed", title: "No Processed Food", description: "Eat whole, unprocessed foods only", category: .avoid, whyMatters: ["Processed foods are calorie-dense", "High sodium causes bloating"], whatYoullNotice: ["Feeling lighter", "Better digestion"], xp: 20),
        NutritionTask(id: "avoid_late_eating", title: "No Late Night Eating", description: "Stop eating 3 hours before bed", category: .avoid, whyMatters: ["Late eating disrupts sleep", "Body can't digest properly"], whatYoullNotice: ["Flatter stomach in morning", "Better sleep"], xp: 15),
        NutritionTask(id: "avoid_soda", title: "No Soda or Juice", description: "Drink only water, tea, or black coffee", category: .avoid, whyMatters: ["Liquid calories add up fast", "Fructose promotes belly fat"], whatYoullNotice: ["Reduced cravings", "Better hydration"], xp: 15),
        NutritionTask(id: "do_protein", title: "Hit Protein Goal", description: "Eat 1g protein per pound of bodyweight", category: .positive, whyMatters: ["Protein builds muscle", "Keeps you full longer"], whatYoullNotice: ["Less hunger", "Better recovery"], xp: 20),
        NutritionTask(id: "do_water", title: "Drink 1 Gallon Water", description: "Stay hydrated with at least 1 gallon", category: .positive, whyMatters: ["Water flushes toxins", "Reduces water retention"], whatYoullNotice: ["Clearer skin", "More defined abs"], xp: 15),
        NutritionTask(id: "do_veggies", title: "Eat 5 Servings Veggies", description: "Pack in colorful vegetables today", category: .positive, whyMatters: ["Fiber aids digestion", "Micronutrients support metabolism"], whatYoullNotice: ["Better digestion", "More energy"], xp: 15),
        NutritionTask(id: "do_healthy_fats", title: "Include Healthy Fats", description: "Add avocado, nuts, or olive oil", category: .positive, whyMatters: ["Healthy fats support hormones", "Aid nutrient absorption"], whatYoullNotice: ["Sustained energy", "Better satiety"], xp: 15),
        NutritionTask(id: "do_meal_prep", title: "Prep Tomorrow's Meals", description: "Plan and prepare meals for tomorrow", category: .positive, whyMatters: ["Prevents impulsive eating", "Controls portions"], whatYoullNotice: ["Less stress about food", "Better choices"], xp: 20),
        NutritionTask(id: "timing_breakfast", title: "Protein-Rich Breakfast", description: "Start with 30g+ protein within 1 hour of waking", category: .timing, whyMatters: ["Kickstarts metabolism", "Reduces cravings all day"], whatYoullNotice: ["Steady energy", "Less snacking"], xp: 15),
        NutritionTask(id: "timing_pre_workout", title: "Pre-Workout Fuel", description: "Eat carbs + protein 1-2 hours before training", category: .timing, whyMatters: ["Fuels performance", "Prevents muscle breakdown"], whatYoullNotice: ["Better workout energy", "Stronger lifts"], xp: 15),
        NutritionTask(id: "timing_post_workout", title: "Post-Workout Window", description: "Eat within 45 min after training", category: .timing, whyMatters: ["Maximizes recovery", "Replenishes glycogen"], whatYoullNotice: ["Less soreness", "Faster recovery"], xp: 15),
        NutritionTask(id: "timing_spacing", title: "Space Meals Evenly", description: "Eat every 3-4 hours throughout the day", category: .timing, whyMatters: ["Keeps metabolism active", "Maintains blood sugar"], whatYoullNotice: ["Consistent energy", "Less overeating"], xp: 15),
        NutritionTask(id: "timing_last_meal", title: "Early Last Meal", description: "Finish dinner by 7 PM", category: .timing, whyMatters: ["Allows full digestion", "Supports circadian rhythm"], whatYoullNotice: ["Better sleep", "Leaner morning look"], xp: 15),
    ]

    static func dailyTasks(for dayIndex: Int) -> [NutritionTask] {
        let avoidTasks = allTasks.filter { $0.category == .avoid }
        let doTasks = allTasks.filter { $0.category == .positive }
        let timingTasks = allTasks.filter { $0.category == .timing }

        return [
            avoidTasks[dayIndex % avoidTasks.count],
            doTasks[dayIndex % doTasks.count],
            timingTasks[dayIndex % timingTasks.count]
        ]
    }
}
