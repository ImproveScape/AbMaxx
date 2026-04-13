import SwiftUI
import UserNotifications

nonisolated enum FeelCheck: String, CaseIterable, Codable, Sendable {
    case good = "Good"
    case okay = "Okay"
    case dead = "Dead"
}

nonisolated enum DifficultyLevel: String, CaseIterable, Codable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

@Observable
@MainActor
class AppViewModel {
    var profile = UserProfile()
    var scanResults: [ScanResult] = []
    var completedExercises: Set<String> = []
    var completedNutrition: Set<String> = []
    var completedMindset: Set<String> = []
    var showLevelUp: Bool = false
    var showDailyComplete: Bool = false
    var showBadgeUnlock: Bool = false
    var unlockedBadge: RankTier?
    var previousBadge: RankTier?
    var showMilestoneUnlock: Bool = false
    var unlockedMilestone: AppMilestone?
    var showWaterToast: Bool = false
    var waterToastCount: Int = 0
    var showFoodToast: Bool = false
    var foodToastName: String = ""
    var showMacroOverToast: Bool = false
    var macroOverName: String = ""
    var macroOverAmount: Int = 0
    var macroOverMessage: String = ""
    private var previouslyUnlockedMilestoneIds: Set<String> = []
    var totalMealsLoggedFromNutrition: Int = 0
    var shouldNavigateToAnalysis: Bool = false
    var scanJustCompleted: Bool = false
    var previousScanBeforeLatest: ScanResult?
    var dayIndex: Int = 0
    var lastCompletedDate: String = ""
    private var cachedExercises: [Exercise]?
    private var yesterdayExerciseIds: Set<String> = []
    var exerciseRefreshTrigger: Int = 0

    var programDayNumber: Int {
        guard let start = profile.transformationStartDate else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return max(days + 1, 1)
    }

    private func dayInWeek(for dayNumber: Int) -> Int {
        (dayNumber - 1) % 7
    }

    private func weekInCycle(for dayNumber: Int) -> Int {
        ((dayNumber - 1) / 7) % 4
    }

    private enum ScheduleDayType {
        case rest
        case zones(AbRegion, AbRegion)
        case weakFocus
        case fullAbs
        case weakPair
    }

    private func scheduledDay(for dayNumber: Int) -> ScheduleDayType {
        let diw = dayInWeek(for: dayNumber)
        let wic = weekInCycle(for: dayNumber)
        if diw == 2 || diw == 4 || diw == 6 { return .rest }
        switch wic {
        case 0:
            switch diw {
            case 0: return .weakFocus
            case 1: return .zones(.upperAbs, .obliques)
            case 3: return .zones(.lowerAbs, .deepCore)
            case 5: return .weakPair
            default: return .rest
            }
        case 1:
            switch diw {
            case 0: return .weakFocus
            case 1: return .zones(.upperAbs, .deepCore)
            case 3: return .zones(.lowerAbs, .obliques)
            case 5: return .weakPair
            default: return .rest
            }
        case 2:
            switch diw {
            case 0: return .weakFocus
            case 1: return .zones(.lowerAbs, .deepCore)
            case 3: return .zones(.upperAbs, .obliques)
            case 5: return .fullAbs
            default: return .rest
            }
        default:
            switch diw {
            case 0: return .weakFocus
            case 1: return .zones(.upperAbs, .lowerAbs)
            case 3: return .zones(.obliques, .deepCore)
            case 5: return .weakPair
            default: return .rest
            }
        }
    }

    func exerciseCountForDay(_ dayNumber: Int) -> Int {
        let wic = weekInCycle(for: dayNumber)
        switch wic {
        case 0: return 4
        case 1: return 5
        case 2: return 5
        default: return 3
        }
    }

    private func sortedByDifficultyForWeek(_ exercises: [Exercise], dayNumber: Int) -> [Exercise] {
        let wic = weekInCycle(for: dayNumber)
        switch wic {
        case 2:
            return exercises.sorted { diffRank($0.difficulty) > diffRank($1.difficulty) }
        case 3:
            return exercises.sorted { diffRank($0.difficulty) < diffRank($1.difficulty) }
        default:
            return exercises
        }
    }

    private func diffRank(_ d: ExerciseDifficulty) -> Int {
        switch d {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }

    private var weakPairRegions: (AbRegion, AbRegion) {
        let regions = weakestRegions
        return (regions[0], regions.count > 1 ? regions[1] : regions[0])
    }

    var isTodayRestDay: Bool {
        if case .rest = scheduledDay(for: programDayNumber) { return true }
        return false
    }

    var todayTargetRegions: (AbRegion, AbRegion) {
        regionsForDay(programDayNumber)
    }

    private func regionsForDay(_ dayNumber: Int) -> (AbRegion, AbRegion) {
        switch scheduledDay(for: dayNumber) {
        case .zones(let a, let b): return (a, b)
        case .weakFocus: return (weakestZoneFromScan, weakestZoneFromScan)
        case .weakPair: return weakPairRegions
        case .fullAbs: return (.upperAbs, .lowerAbs)
        case .rest: return (.upperAbs, .deepCore)
        }
    }

    var todayTargetLabel: String {
        labelForDay(programDayNumber)
    }

    private func labelForDay(_ dayNumber: Int) -> String {
        switch scheduledDay(for: dayNumber) {
        case .rest: return "Rest & Recovery"
        case .weakFocus: return "Weak Zone Focus"
        case .fullAbs: return "Full Abs Day"
        case .weakPair:
            let (r1, r2) = weakPairRegions
            return r1 == r2 ? "\(r1.rawValue) Blitz" : "\(r1.rawValue) & \(r2.rawValue)"
        case .zones(let a, let b): return "\(a.rawValue) & \(b.rawValue)"
        }
    }

    var currentWeekTheme: String {
        Self.weekTheme(for: weekInCycle(for: programDayNumber))
    }

    static func weekTheme(for wic: Int) -> String {
        switch wic % 4 {
        case 0: return "Foundation"
        case 1: return "Volume"
        case 2: return "Intensity"
        default: return "Deload"
        }
    }

    static func weekThemeIcon(for wic: Int) -> String {
        switch wic % 4 {
        case 0: return "square.stack.3d.up"
        case 1: return "arrow.up.right"
        case 2: return "flame.fill"
        default: return "leaf.fill"
        }
    }

    func dayTypeLabel(for dayNumber: Int) -> String {
        switch scheduledDay(for: dayNumber) {
        case .rest: return "REST"
        case .weakFocus: return "WEAK ZONE"
        case .fullAbs: return "FULL ABS"
        case .weakPair: return "WEAK ZONES"
        case .zones: return "TRAINING"
        }
    }

    var weakestZoneFromScan: AbRegion {
        guard let scan = latestScan else { return .lowerAbs }
        let zones: [(AbRegion, Int)] = [
            (.upperAbs, scan.upperAbsScore),
            (.lowerAbs, scan.lowerAbsScore),
            (.obliques, scan.obliquesScore),
            (.deepCore, scan.deepCoreScore)
        ]
        return zones.min(by: { $0.1 < $1.1 })?.0 ?? .lowerAbs
    }

    var weakestZoneScore: Int {
        guard let scan = latestScan else { return 0 }
        let zones = [scan.upperAbsScore, scan.lowerAbsScore, scan.obliquesScore, scan.deepCoreScore]
        return zones.min() ?? 0
    }

    var tomorrowTargetLabel: String {
        targetLabel(for: programDayNumber + 1)
    }

    var isTomorrowRestDay: Bool {
        isRestDay(for: programDayNumber + 1)
    }

    var tomorrowExercisesPreview: [Exercise] {
        exercisesPreview(for: programDayNumber + 1)
    }

    func targetLabel(for dayNumber: Int) -> String {
        labelForDay(dayNumber)
    }

    func isRestDay(for dayNumber: Int) -> Bool {
        if case .rest = scheduledDay(for: dayNumber) { return true }
        return false
    }

    func exercisesPreview(for dayNumber: Int) -> [Exercise] {
        let targetCount = exerciseCountForDay(dayNumber)
        switch scheduledDay(for: dayNumber) {
        case .rest:
            return []
        case .weakFocus:
            let region = weakestZoneFromScan
            let pool = sortedByDifficultyForWeek(Exercise.exercises(for: region), dayNumber: dayNumber)
            let seed = dayNumber
            var exercises: [Exercise] = []
            for i in 0..<min(targetCount + 2, pool.count) {
                let idx = (seed + i) % pool.count
                if !exercises.contains(where: { $0.id == pool[idx].id }) {
                    exercises.append(pool[idx])
                }
            }
            return Array(exercises.prefix(targetCount))
        case .fullAbs:
            return fullAbsDayExercises(for: dayNumber)
        case .weakPair:
            let (r1, r2) = weakPairRegions
            return previewExercisesForRegions(primary: r1, secondary: r2, dayNumber: dayNumber, targetCount: targetCount)
        case .zones(let a, let b):
            return previewExercisesForRegions(primary: a, secondary: b, dayNumber: dayNumber, targetCount: targetCount)
        }
    }

    private func previewExercisesForRegions(primary: AbRegion, secondary: AbRegion, dayNumber: Int, targetCount: Int) -> [Exercise] {
        var exercises: [Exercise] = []
        var usedIds: Set<String> = []
        let seed = dayNumber
        let pTarget = primary == secondary ? targetCount : (targetCount + 1) / 2
        let primaryPool = Exercise.exercises(for: primary)
        for i in 0..<primaryPool.count {
            guard exercises.count < pTarget else { break }
            let idx = (seed + i) % primaryPool.count
            let ex = primaryPool[idx]
            if !usedIds.contains(ex.id) {
                exercises.append(ex)
                usedIds.insert(ex.id)
            }
        }
        if primary != secondary {
            let secondaryPool = Exercise.exercises(for: secondary)
            for i in 0..<secondaryPool.count {
                guard exercises.count < targetCount else { break }
                let idx = (seed + i) % secondaryPool.count
                let ex = secondaryPool[idx]
                if !usedIds.contains(ex.id) {
                    exercises.append(ex)
                    usedIds.insert(ex.id)
                }
            }
        }
        return Array(exercises.prefix(targetCount))
    }

    var foodLog: [FoodItem] = []
    var dailyNutrition = DailyNutrition()
    var waterGlasses: Int = 0
    var dailyPhotos: [DailyPhoto] = []
    var whyReasons: [String] = []

    var recoveryDays: [RecoveryDay] = []
    var totalExercisesCompleted: Int = 0
    var waterGoalDaysHit: Int = 0
    var notificationsEnabled: Bool = false
    var aiCounterEnabled: Bool = true

    var trainingPlan: TrainingPlanData = TrainingPlanData()
    var selectedDayId: String?
    var currentFeelCheck: FeelCheck? = nil
    var currentDifficulty: DifficultyLevel? = nil
    var difficultyLockedForToday: Bool = false
    var workoutHistory: [CompletedWorkout] = []
    var profileImage: UIImage? = nil
    var absProjection: AbsProjection = AbsProjection()

    func recalculateNutrition() {
        dailyNutrition = profile.toDailyNutrition()
        saveDailyNutrition()
    }

    func refreshExercisesForEquipment() {
        cachedExercises = nil
        exerciseRefreshTrigger += 1
    }

    // MARK: - Abs Projection

    var absGoalLevel: AbsGoalLevel {
        guard let scan = latestScan else {
            switch profile.absDescription {
            case .barelyVisible, .slightOutline: return .visibleAbs
            case .topTwoVisible: return .fourPack
            case .fourPackVisible: return .sixPack
            case .almostThere: return .shreddedSixPack
            }
        }
        let score = scan.overallScore
        if score < 45 { return .visibleAbs }
        if score < 60 { return .fourPack }
        if score < 75 { return .sixPack }
        return .shreddedSixPack
    }

    var absProjectionProgress: Double {
        guard let scan = latestScan else { return 0 }
        let target = absGoalLevel.targetOverallScore
        let current = scan.overallScore
        guard target > 0 else { return 0 }
        return min(max(Double(current) / Double(target), 0), 0.99)
    }

    func recalculateAbsProjection() {
        let currentBF = latestScan?.estimatedBodyFat ?? estimatedBodyFatFromProfile
        let goalLevel = absGoalLevel
        let targetBF = goalLevel.targetBodyFat
        let score = latestScan?.overallScore ?? 0
        let targetScoreVal = goalLevel.targetOverallScore

        absProjection.currentBodyFat = currentBF
        absProjection.targetBodyFat = targetBF
        absProjection.currentScore = score
        absProjection.targetScore = targetScoreVal
        absProjection.bodyWeightKg = profile.weightInKg
        absProjection.streakDays = profile.streakDays

        let plannedDeficit = Double(profile.selectedCalorieDeficit > 0 ? profile.selectedCalorieDeficit : 400)
        absProjection.plannedDailyDeficit = plannedDeficit

        let nutritionStats = nutritionAdherenceLast30
        absProjection.trackedDaysLast30 = nutritionStats.trackedDays
        absProjection.daysOverLast30 = nutritionStats.daysOver
        absProjection.totalSurplusCaloriesLast30 = nutritionStats.totalSurplus

        let avgDailySurplus: Double
        if nutritionStats.trackedDays > 0 {
            avgDailySurplus = nutritionStats.totalSurplus / Double(nutritionStats.trackedDays)
        } else {
            avgDailySurplus = 0
        }
        let effectiveDeficit = max(plannedDeficit - avgDailySurplus, 0)
        absProjection.effectiveDailyDeficit = effectiveDeficit

        if nutritionStats.trackedDays > 0 {
            let onTrackDays = nutritionStats.trackedDays - nutritionStats.daysOver
            absProjection.nutritionAdherenceRate = Double(onTrackDays) / Double(nutritionStats.trackedDays)
        } else {
            absProjection.nutritionAdherenceRate = 1.0
        }

        let workoutStats = workoutAdherenceLast30
        absProjection.scheduledWorkoutsLast30 = workoutStats.scheduled
        absProjection.completedWorkoutsLast30 = workoutStats.completed
        if workoutStats.scheduled > 0 {
            absProjection.workoutAdherenceRate = min(Double(workoutStats.completed) / Double(workoutStats.scheduled), 1.0)
        } else {
            absProjection.workoutAdherenceRate = 1.0
        }

        absProjection.lastCalculatedDate = Date()
        saveAbsProjection()
    }

    private var estimatedBodyFatFromProfile: Double {
        switch profile.bodyFatCategory {
        case .lean: return 10.0
        case .athletic: return 15.0
        case .average: return 22.0
        case .aboveAverage: return 28.0
        }
    }

    private var nutritionAdherenceLast30: (trackedDays: Int, daysOver: Int, totalSurplus: Double) {
        let calendar = Calendar.current
        let now = Date()
        let goal = dailyNutrition.calorieGoal
        guard goal > 0 else { return (0, 0, 0) }
        var tracked = 0
        var over = 0
        var surplus: Double = 0
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for offset in 1...30 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let cals = nutritionCalories(for: day, formatter: formatter)
            guard cals > 0 else { continue }
            tracked += 1
            if cals > goal {
                over += 1
                surplus += Double(cals - goal)
            }
        }
        return (tracked, over, surplus)
    }

    private func nutritionCalories(for date: Date, formatter: DateFormatter) -> Int {
        let key = "nutrition_\(formatter.string(from: date))"
        guard let data = UserDefaults.standard.data(forKey: key),
              let log = try? JSONDecoder().decode(NutritionDailyLog.self, from: data) else {
            return totalCalories(for: date)
        }
        return log.totalCalories
    }

    func nutritionLog(for date: Date) -> NutritionDailyLog? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = "nutrition_\(formatter.string(from: date))"
        guard let data = UserDefaults.standard.data(forKey: key),
              let log = try? JSONDecoder().decode(NutritionDailyLog.self, from: data) else {
            return nil
        }
        return log
    }

    var todayNutritionLog: NutritionDailyLog? {
        nutritionLog(for: Date())
    }

    private var workoutAdherenceLast30: (scheduled: Int, completed: Int) {
        guard let start = profile.transformationStartDate else { return (0, 0) }
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let rangeStart = max(start, thirtyDaysAgo)
        let totalDays = max(calendar.dateComponents([.day], from: calendar.startOfDay(for: rangeStart), to: calendar.startOfDay(for: now)).day ?? 0, 0)

        let workoutDates = Set(workoutHistory.map { calendar.startOfDay(for: $0.date) })
        var scheduled = 0
        var completed = 0
        for offset in 0..<totalDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: rangeStart)) else { continue }
            let dayNum = max(calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: day).day ?? 0, 0) + 1
            let diw = (dayNum - 1) % 7
            if diw == 2 || diw == 4 || diw == 6 { continue }
            scheduled += 1
            if workoutDates.contains(calendar.startOfDay(for: day)) {
                completed += 1
            }
        }
        return (scheduled, completed)
    }

    var missedWorkoutDaysLast30: Int {
        let stats = workoutAdherenceLast30
        return max(stats.scheduled - stats.completed, 0)
    }

    var calorieOverageDaysLast30: Int {
        nutritionAdherenceLast30.daysOver
    }

    func onWorkoutCompleted() {
        recalculateAbsProjection()
    }

    func onFoodLogged() {
        recalculateAbsProjection()
    }

    private func saveAbsProjection() {
        if let data = try? JSONEncoder().encode(absProjection) {
            UserDefaults.standard.set(data, forKey: "absProjection")
        }
    }

    private func loadAbsProjection() {
        if let data = UserDefaults.standard.data(forKey: "absProjection"),
           let decoded = try? JSONDecoder().decode(AbsProjection.self, from: data) {
            absProjection = decoded
        }
        recalculateAbsProjection()
    }

    var latestScan: ScanResult? { scanResults.last }

    var todaysScan: ScanResult? {
        let calendar = Calendar.current
        return scanResults.last(where: { calendar.isDateInToday($0.date) })
    }

    var hasScannedToday: Bool { todaysScan != nil }

    var todaysFoodLog: [FoodItem] {
        let calendar = Calendar.current
        return foodLog.filter { calendar.isDateInToday($0.date) }
    }

    var totalCaloriesToday: Int {
        if let log = todayNutritionLog, !log.entries.isEmpty { return log.totalCalories }
        return todaysFoodLog.reduce(0) { $0 + $1.calories }
    }
    var totalProteinToday: Double {
        if let log = todayNutritionLog, !log.entries.isEmpty { return log.totalProtein }
        return todaysFoodLog.reduce(0) { $0 + $1.protein }
    }
    var totalCarbsToday: Double {
        if let log = todayNutritionLog, !log.entries.isEmpty { return log.totalCarbs }
        return todaysFoodLog.reduce(0) { $0 + $1.carbs }
    }
    var totalFatToday: Double {
        if let log = todayNutritionLog, !log.entries.isEmpty { return log.totalFat }
        return todaysFoodLog.reduce(0) { $0 + $1.fat }
    }
    var totalFiberToday: Double {
        if let log = todayNutritionLog, !log.entries.isEmpty { return log.totalFiber }
        return todaysFoodLog.reduce(0) { $0 + $1.fiber }
    }
    var totalSugarToday: Double {
        if let log = todayNutritionLog, !log.entries.isEmpty { return log.totalSugar }
        return todaysFoodLog.reduce(0) { $0 + $1.sugar }
    }
    var totalSodiumToday: Double {
        if let log = todayNutritionLog, !log.entries.isEmpty { return log.totalSodium }
        return todaysFoodLog.reduce(0) { $0 + $1.sodium }
    }

    var caloriesRemaining: Int { max(dailyNutrition.calorieGoal - totalCaloriesToday, 0) }

    var calorieProgress: Double {
        guard dailyNutrition.calorieGoal > 0 else { return 0 }
        return min(Double(totalCaloriesToday) / Double(dailyNutrition.calorieGoal), 1.0)
    }

    var proteinProgress: Double {
        guard dailyNutrition.proteinGoal > 0 else { return 0 }
        return min(totalProteinToday / dailyNutrition.proteinGoal, 1.0)
    }

    var carbsProgress: Double {
        guard dailyNutrition.carbsGoal > 0 else { return 0 }
        return min(totalCarbsToday / dailyNutrition.carbsGoal, 1.0)
    }

    var fatProgress: Double {
        guard dailyNutrition.fatGoal > 0 else { return 0 }
        return min(totalFatToday / dailyNutrition.fatGoal, 1.0)
    }

    var waterProgress: Double {
        guard dailyNutrition.waterGoal > 0 else { return 0 }
        return min(Double(waterGlasses) / Double(dailyNutrition.waterGoal), 1.0)
    }

    var canScan: Bool {
        guard let mostRecent = scanResults.map({ $0.date }).max() else { return true }
        let elapsed = Date().timeIntervalSince(mostRecent)
        return elapsed >= 7 * 24 * 60 * 60
    }

    var nextScanDate: Date? {
        guard let mostRecent = scanResults.map({ $0.date }).max() else { return nil }
        return mostRecent.addingTimeInterval(7 * 24 * 60 * 60)
    }

    var timeUntilNextScan: (days: Int, hours: Int, minutes: Int) {
        guard let next = nextScanDate else { return (0, 0, 0) }
        let remaining = max(next.timeIntervalSince(Date()), 0)
        let totalMinutes = Int(remaining) / 60
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60
        return (days, hours, minutes)
    }

    var canTakePhotoToday: Bool {
        let calendar = Calendar.current
        guard let mostRecent = dailyPhotos.map({ $0.date }).max() else { return true }
        let daysSince = calendar.dateComponents([.day], from: mostRecent, to: Date()).day ?? 0
        return daysSince >= 7
    }

    var daysUntilNextScan: Int {
        guard let next = nextScanDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: next).day ?? 0
        return max(days, 0)
    }

    var photoDaysThisMonth: Set<Int> {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        var days: Set<Int> = []
        for photo in dailyPhotos {
            if calendar.component(.month, from: photo.date) == month &&
               calendar.component(.year, from: photo.date) == year {
                days.insert(calendar.component(.day, from: photo.date))
            }
        }
        return days
    }

    func addDailyPhoto() {
        guard canTakePhotoToday else { return }
        let photo = DailyPhoto(date: Date(), dayNumber: profile.daysOnProgram)
        dailyPhotos.append(photo)
        saveDailyPhotos()
    }

    func addFood(_ item: FoodItem) {
        foodLog.append(item)
        saveFoodLog()
        onFoodLogged()
        foodToastName = item.name
        showFoodToast = true
        checkMilestoneUnlocks()
    }

    func removeFood(_ item: FoodItem) {
        foodLog.removeAll { $0.id == item.id }
        saveFoodLog()
    }

    func addWater() {
        let wasGoalHit = waterGlasses >= dailyNutrition.waterGoal && dailyNutrition.waterGoal > 0
        waterGlasses += 1
        saveWater()
        waterToastCount = waterGlasses
        showWaterToast = true
        if !wasGoalHit && waterGlasses >= dailyNutrition.waterGoal && dailyNutrition.waterGoal > 0 {
            let key = "waterGoalHitToday_\(dateKey)"
            if !UserDefaults.standard.bool(forKey: key) {
                UserDefaults.standard.set(true, forKey: key)
                waterGoalDaysHit += 1
                UserDefaults.standard.set(waterGoalDaysHit, forKey: "waterGoalDaysHit")
            }
        }
        checkMilestoneUnlocks()
    }

    func removeWater() {
        guard waterGlasses > 0 else { return }
        waterGlasses -= 1
        saveWater()
    }

    func foodLog(for date: Date) -> [FoodItem] {
        let calendar = Calendar.current
        return foodLog.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func totalCalories(for date: Date) -> Int { foodLog(for: date).reduce(0) { $0 + $1.calories } }
    func totalProtein(for date: Date) -> Double { foodLog(for: date).reduce(0) { $0 + $1.protein } }
    func totalCarbs(for date: Date) -> Double { foodLog(for: date).reduce(0) { $0 + $1.carbs } }
    func totalFat(for date: Date) -> Double { foodLog(for: date).reduce(0) { $0 + $1.fat } }

    func mealsForType(_ type: MealType) -> [FoodItem] {
        todaysFoodLog.filter { $0.mealType == type }
    }

    func mealsForType(_ type: MealType, on date: Date) -> [FoodItem] {
        foodLog(for: date).filter { $0.mealType == type }
    }

    func caloriesForMeal(_ type: MealType) -> Int {
        mealsForType(type).reduce(0) { $0 + $1.calories }
    }

    func caloriesForMeal(_ type: MealType, on date: Date) -> Int {
        mealsForType(type, on: date).reduce(0) { $0 + $1.calories }
    }

    func waterGlasses(for date: Date) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        return UserDefaults.standard.integer(forKey: "waterGlasses_\(key)")
    }

    private static var foodLogFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("foodLog.json")
    }

    private func saveFoodLog() {
        if let data = try? JSONEncoder().encode(foodLog) {
            try? data.write(to: Self.foodLogFileURL)
        }
        if let data = try? JSONEncoder().encode(dailyNutrition) {
            UserDefaults.standard.set(data, forKey: "dailyNutrition")
        }
    }

    private func pruneFoodLog() {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        let before = foodLog.count
        foodLog.removeAll { $0.date < cutoff }
        if foodLog.count != before {
            saveFoodLog()
        }
    }

    private func saveWater() {
        UserDefaults.standard.set(waterGlasses, forKey: "waterGlasses_\(dateKey)")
    }

    private func saveDailyPhotos() {
        if let data = try? JSONEncoder().encode(dailyPhotos) {
            UserDefaults.standard.set(data, forKey: "dailyPhotos")
        }
    }

    private var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var currentPhase: Phase {
        Phase.phase(for: profile.currentPhase)
    }



    var scanAvailable: Bool { canScan }

    struct ZoneWeekInfo {
        let zone: AbRegion
        let dayNumbers: [Int]
        let dayLabels: [String]
        let sessionsPerWeek: Int
        let isWeak: Bool
        let statusMessage: String
    }

    func zoneWeekInfo(for zone: AbRegion) -> ZoneWeekInfo {
        let weekStart = ((programDayNumber - 1) / 7) * 7 + 1
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var hitDays: [Int] = []
        var hitLabels: [String] = []

        for offset in 0..<7 {
            let dayNum = weekStart + offset
            let schedule = scheduledDay(for: dayNum)
            let hitsZone: Bool
            switch schedule {
            case .rest:
                hitsZone = false
            case .zones(let a, let b):
                hitsZone = a == zone || b == zone
            case .weakFocus:
                hitsZone = weakestZoneFromScan == zone
            case .fullAbs:
                hitsZone = true
            case .weakPair:
                let (r1, r2) = weakPairRegions
                hitsZone = r1 == zone || r2 == zone
            }
            if hitsZone {
                hitDays.append(dayNum)
                hitLabels.append(dayNames[offset])
            }
        }

        let isWeak = weakestRegions.contains(zone)
        let sessions = hitDays.count
        let status: String
        if isWeak {
            status = "Your plan hits this \(sessions)x this week because it scored low — extra volume to close the gap"
        } else if sessions >= 3 {
            status = "Strong zone getting \(sessions) sessions to maintain your lead"
        } else {
            status = "\(sessions)x this week — maintenance volume keeps this zone sharp"
        }

        return ZoneWeekInfo(
            zone: zone,
            dayNumbers: hitDays,
            dayLabels: hitLabels,
            sessionsPerWeek: sessions,
            isWeak: isWeak,
            statusMessage: status
        )
    }

    func dayLabelForNumber(_ dayNumber: Int) -> String {
        labelForDay(dayNumber)
    }

    func dayTypeLabelShort(for dayNumber: Int) -> String {
        dayTypeLabel(for: dayNumber)
    }

    var weakestRegions: [AbRegion] {
        guard let scan = latestScan else { return [.deepCore, .upperAbs] }
        let regions: [(AbRegion, Int)] = [
            (.upperAbs, scan.upperAbsScore),
            (.lowerAbs, scan.lowerAbsScore),
            (.obliques, scan.obliquesScore),
            (.deepCore, scan.deepCoreScore)
        ]
        let sorted = regions.sorted { $0.1 < $1.1 }
        return Array(sorted.prefix(2).map(\.0))
    }

    // MARK: - Progressive Overload

    var currentWeekNumber: Int {
        (programDayNumber - 1) / 7
    }

    func zoneScoreForRegion(_ region: AbRegion) -> Int {
        guard let scan = latestScan else { return 0 }
        switch region {
        case .upperAbs: return scan.upperAbsScore
        case .lowerAbs: return scan.lowerAbsScore
        case .obliques: return scan.obliquesScore
        case .deepCore: return scan.deepCoreScore
        }
    }

    private func scoreMultiplier(for score: Int) -> Double {
        if score >= 76 { return 1.30 }
        if score >= 61 { return 1.20 }
        if score >= 41 { return 1.10 }
        return 1.0
    }

    private func parseBaseReps(_ reps: String) -> (value: Int, sets: Int, isTime: Bool, isEachSide: Bool) {
        let lower = reps.lowercased()
        let isTime = lower.contains("sec")
        let isEachSide = lower.contains("each side")

        var value = 15
        var sets = 3

        let parts = lower.components(separatedBy: "×").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.isEmpty {
            let altParts = lower.components(separatedBy: "x").map { $0.trimmingCharacters(in: .whitespaces) }
            if let first = altParts.first, let num = Int(first.filter(\.isNumber)), num > 0 { value = num }
            if altParts.count > 1, let num = Int(altParts[1].filter(\.isNumber)), num > 0 { sets = num }
        } else {
            if let first = parts.first, let num = Int(first.filter(\.isNumber)), num > 0 { value = num }
            if parts.count > 1, let num = Int(parts[1].filter(\.isNumber)), num > 0 { sets = num }
        }

        return (value, sets, isTime, isEachSide)
    }

    func progressiveRepsString(for exercise: Exercise, dayNumber: Int? = nil) -> String {
        let effectiveWeek = dayNumber.map { ($0 - 1) / 7 } ?? currentWeekNumber
        return buildProgressiveReps(for: exercise, weekNumber: effectiveWeek)
    }

    private func buildProgressiveReps(for exercise: Exercise, weekNumber: Int) -> String {
        let parsed = parseBaseReps(exercise.reps)
        let weekPhase = weekNumber % 4
        let zoneScore = zoneScoreForRegion(exercise.region)
        let multiplier = scoreMultiplier(for: zoneScore)

        var adjustedValue = Int(round(Double(parsed.value) * multiplier))
        var adjustedSets = parsed.sets

        switch weekPhase {
        case 0:
            break
        case 1:
            adjustedSets += 1
        case 2:
            adjustedValue = parsed.isTime
                ? adjustedValue + 10
                : adjustedValue + max(Int(round(Double(adjustedValue) * 0.25)), 2)
        default:
            adjustedValue = parsed.isTime
                ? max(adjustedValue - 10, 15)
                : max(Int(round(Double(adjustedValue) * 0.8)), 6)
            adjustedSets = max(adjustedSets - 1, 2)
        }

        if let difficulty = currentDifficulty {
            switch difficulty {
            case .easy:
                adjustedSets = max(adjustedSets - 1, 2)
                adjustedValue = parsed.isTime ? max(adjustedValue - 10, 15) : max(adjustedValue - 3, 6)
            case .medium:
                break
            case .hard:
                adjustedSets += 1
                adjustedValue = parsed.isTime ? adjustedValue + 10 : adjustedValue + 3
            }
        }

        if parsed.isTime {
            if parsed.isEachSide {
                return "\(adjustedValue) sec each side × \(adjustedSets) sets"
            }
            return "\(adjustedValue) sec × \(adjustedSets) sets"
        }
        if parsed.isEachSide {
            return "\(adjustedValue) each side × \(adjustedSets) sets"
        }
        return "\(adjustedValue) reps × \(adjustedSets) sets"
    }

    // MARK: - Feel Check

    var todayFeelCheck: FeelCheck? {
        currentFeelCheck
    }

    func saveFeelCheck(_ feel: FeelCheck) {
        currentFeelCheck = feel
        UserDefaults.standard.set(feel.rawValue, forKey: "feelCheck_\(dateKey)")
    }

    private func loadFeelCheck() {
        if let raw = UserDefaults.standard.string(forKey: "feelCheck_\(dateKey)") {
            currentFeelCheck = FeelCheck(rawValue: raw)
        }
    }

    func saveDifficulty(_ level: DifficultyLevel) {
        currentDifficulty = level
        UserDefaults.standard.set(level.rawValue, forKey: "difficulty_\(dateKey)")
        cachedExercises = nil
    }

    private func loadDifficulty() {
        if let raw = UserDefaults.standard.string(forKey: "difficulty_\(dateKey)") {
            currentDifficulty = DifficultyLevel(rawValue: raw)
        }
        difficultyLockedForToday = !completedExercises.isEmpty && currentDifficulty != nil
    }

    var bonusExerciseForHard: Exercise? {
        guard currentDifficulty == .hard else { return nil }
        let currentIds = Set(todaysExercises.map(\.id))
        let (r1, _) = todayTargetRegions
        let pool = filteredExercises(for: r1).filter { !currentIds.contains($0.id) }
        guard !pool.isEmpty else { return nil }
        return pool[programDayNumber % pool.count]
    }

    var displayExercisesWithDifficulty: [Exercise] {
        var exercises = todaysExercises
        if let bonus = bonusExerciseForHard {
            exercises.append(bonus)
        }
        return exercises
    }

    var consecutiveGoodDays: Int {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var count = 0
        for offset in 1...7 {
            guard let pastDate = calendar.date(byAdding: .day, value: -offset, to: Date()) else { break }
            let key = "feelCheck_\(formatter.string(from: pastDate))"
            guard let raw = UserDefaults.standard.string(forKey: key),
                  let feel = FeelCheck(rawValue: raw),
                  feel == .good else { break }
            count += 1
        }
        return count
    }

    // MARK: - Rest Day Checkboxes

    func restDayCheckboxes() -> [Bool] {
        let key = "restDayChecks_\(dateKey)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Bool].self, from: data) else {
            return [false, false, false, false]
        }
        return decoded
    }

    func saveRestDayCheckboxes(_ checks: [Bool]) {
        if let data = try? JSONEncoder().encode(checks) {
            UserDefaults.standard.set(data, forKey: "restDayChecks_\(dateKey)")
        }
    }

    var restDayRecoveryPercent: Double {
        let checks = restDayCheckboxes()
        let ticked = checks.filter { $0 }.count
        return 60.0 + Double(ticked) * 10.0
    }

    // MARK: - Full Abs Day

    private func fullAbsDayExercises(for dayNumber: Int) -> [Exercise] {
        let targetCount = exerciseCountForDay(dayNumber)
        let allRegions: [AbRegion] = [.upperAbs, .lowerAbs, .obliques, .deepCore]
        let weekStart = ((dayNumber - 1) / 7) * 7 + 1
        var usedOnEarlierDays: Set<String> = Set<String>()

        for d in weekStart..<dayNumber {
            let schedule = scheduledDay(for: d)
            let dayCount = exerciseCountForDay(d)
            switch schedule {
            case .zones(let r1, let r2):
                let half = (dayCount + 1) / 2
                for pool in [Exercise.exercises(for: r1), Exercise.exercises(for: r2)] {
                    for i in 0..<min(half, pool.count) {
                        let idx = (d + i) % pool.count
                        usedOnEarlierDays.insert(pool[idx].id)
                    }
                }
            case .weakFocus:
                let pool = Exercise.exercises(for: weakestZoneFromScan)
                for i in 0..<min(dayCount, pool.count) {
                    usedOnEarlierDays.insert(pool[(d + i) % pool.count].id)
                }
            case .weakPair:
                let (wr1, wr2) = weakPairRegions
                let half = (dayCount + 1) / 2
                let p1 = Exercise.exercises(for: wr1)
                for i in 0..<min(half, p1.count) {
                    usedOnEarlierDays.insert(p1[(d + i) % p1.count].id)
                }
                if wr1 != wr2 {
                    let p2 = Exercise.exercises(for: wr2)
                    for i in 0..<min(dayCount - half, p2.count) {
                        usedOnEarlierDays.insert(p2[(d + i) % p2.count].id)
                    }
                }
            default:
                break
            }
        }

        let sortedRegions: [AbRegion]
        if targetCount < 4 {
            let ranked = allRegions.sorted { zoneScoreForRegion($0) < zoneScoreForRegion($1) }
            sortedRegions = Array(ranked.prefix(targetCount))
        } else {
            sortedRegions = allRegions
        }

        var exercises: [Exercise] = []
        for region in sortedRegions {
            let pool = sortedByDifficultyForWeek(
                filteredExercises(for: region).filter { !usedOnEarlierDays.contains($0.id) },
                dayNumber: dayNumber
            )
            if pool.isEmpty {
                let fallback = filteredExercises(for: region)
                if !fallback.isEmpty {
                    exercises.append(fallback[dayNumber % fallback.count])
                }
            } else {
                let idx = dayNumber % pool.count
                exercises.append(pool[idx])
            }
        }

        if exercises.count < targetCount {
            let weakest = weakestZoneFromScan
            let extraPool = filteredExercises(for: weakest).filter { ex in
                !exercises.contains(where: { $0.id == ex.id })
            }
            if !extraPool.isEmpty {
                exercises.append(extraPool[dayNumber % extraPool.count])
            }
        }

        return Array(exercises.prefix(targetCount))
    }

    // MARK: - Coach Note

    var coachNote: String {
        let schedule = scheduledDay(for: programDayNumber)
        if isTodayRestDay {
            if let scan = latestScan {
                let bf = String(format: "%.1f", scan.estimatedBodyFat)
                return "Your muscles rebuild during rest. At \(bf)% body fat, recovery is where the next layer of definition comes through. Hydrate and sleep deep."
            }
            return "Your muscles rebuild during rest. Hydrate, stretch, and let the work you've done this week compound."
        }

        guard let scan = latestScan else {
            return "Complete your first scan to unlock personalized coaching based on your actual ab development."
        }

        let zones: [(String, Int)] = [
            ("Upper Abs", scan.upperAbsScore),
            ("Lower Abs", scan.lowerAbsScore),
            ("Obliques", scan.obliquesScore),
            ("Deep Core", scan.deepCoreScore)
        ]
        let weakest = zones.min(by: { $0.1 < $1.1 })!
        let strongest = zones.max(by: { $0.1 < $1.1 })!
        let exerciseCount = displayExercisesWithDifficulty.count
        let gap = strongest.1 - weakest.1
        let scanWeek = max(scanResults.count, 1)
        let projectedGain = gap > 15 ? "+5" : (gap > 8 ? "+4" : "+3")

        switch schedule {
        case .weakFocus:
            return "Your \(weakest.0) scored \(weakest.1) last scan — that's \(gap) points behind your \(strongest.0). Today's \(exerciseCount) exercises target that gap directly. Hit all \(exerciseCount) and you're on track for \(projectedGain) next scan."
        case .fullAbs:
            return "Full Abs Day. Your \(weakest.0) at \(weakest.1) is the bottleneck holding your overall score at \(scan.overallScore). Every rep on that zone today moves the needle. \(exerciseCount) exercises, zero skipped."
        case .weakPair:
            let (wr1, wr2) = weakPairRegions
            let s1 = zones.first(where: { $0.0 == wr1.rawValue })?.1 ?? 0
            let s2 = zones.first(where: { $0.0 == wr2.rawValue })?.1 ?? 0
            return "Double weak zone session. \(wr1.rawValue) (\(s1)) and \(wr2.rawValue) (\(s2)) are your biggest gaps. \(exerciseCount) targeted exercises to close the deficit."
        default:
            let (r1, r2) = todayTargetRegions
            let r1Score = zones.first(where: { $0.0 == r1.rawValue })?.1 ?? 0
            let r2Score = zones.first(where: { $0.0 == r2.rawValue })?.1 ?? 0
            let targetZone = r1Score < r2Score ? r1 : r2
            let targetScore = min(r1Score, r2Score)
            let isTargetWeak = targetZone.rawValue == weakest.0

            if isTargetWeak {
                return "Your \(targetZone.rawValue) scored \(targetScore) last scan — today's session targets that zone. Hit all \(exerciseCount) exercises and you're on track for \(projectedGain) next scan."
            } else {
                return "Today hits \(r1.rawValue) (\(r1Score)) and \(r2.rawValue) (\(r2Score)). Your overall is \(scan.overallScore) after Week \(scanWeek). \(exerciseCount) exercises — don't leave reps on the table."
            }
        }
    }

    var coachTip: String {
        let name = profile.displayName
        if isTodayRestDay {
            return "\(name), your muscles grow during rest — today's recovery is just as important as any workout."
        }
        let (r1, r2) = todayTargetRegions
        guard let scan = latestScan else {
            return "\(name), today's \(totalCount) exercises are hand-picked to build your \(r1.rawValue.lowercased()) foundation. Complete your first scan to unlock a fully personalized program."
        }
        let zoneScores: [AbRegion: Int] = [
            .upperAbs: scan.upperAbsScore,
            .lowerAbs: scan.lowerAbsScore,
            .obliques: scan.obliquesScore,
            .deepCore: scan.deepCoreScore
        ]
        let r1Score = zoneScores[r1] ?? 0
        let r2Score = zoneScores[r2] ?? 0
        let overall = scan.overallScore
        let day = programDayNumber
        let seed = day % 4
        if r1 == r2 {
            let tips = [
                "\(name), your scan flagged \(r1.rawValue.lowercased()) at \(r1Score) — it's the #1 thing holding your \(overall) overall score back. These \(totalCount) exercises were chosen specifically to attack that.",
                "\(name), your \(r1.rawValue.lowercased()) scored \(r1Score) last scan. We built today's entire session around that zone — every single rep here directly moves your score.",
                "\(name), at \(r1Score) your \(r1.rawValue.lowercased()) is your biggest opportunity right now. These \(totalCount) exercises isolate exactly what your scan showed you need most.",
                "\(name), your scan data pointed straight at \(r1.rawValue.lowercased()) at \(r1Score). Today's session is programmed to close that gap and push your overall past \(overall)."
            ]
            return tips[seed]
        }
        let weaker = r1Score <= r2Score ? r1 : r2
        let weakerScore = min(r1Score, r2Score)
        let stronger = r1Score > r2Score ? r1 : r2
        let strongerScore = max(r1Score, r2Score)
        let tips = [
            "\(name), your scan shows \(weaker.rawValue.lowercased()) at \(weakerScore) vs \(stronger.rawValue.lowercased()) at \(strongerScore) — that imbalance is what we're fixing today. These \(totalCount) exercises were built around your data.",
            "\(name), we chose these \(totalCount) exercises because your \(weaker.rawValue.lowercased()) is lagging at \(weakerScore). Every rep today is precision-targeted to pull your \(overall) score higher.",
            "\(name), your scan flagged \(weaker.rawValue.lowercased()) (\(weakerScore)) as the weak link holding you back. This session pairs it with \(stronger.rawValue.lowercased()) (\(strongerScore)) — nothing left behind.",
            "\(name), at \(overall) overall, your \(weaker.rawValue.lowercased()) at \(weakerScore) is your fastest path to a higher score. That's exactly why we built today's session around it."
        ]
        return tips[seed]
    }

    private var totalCount: Int {
        displayExercisesWithDifficulty.count
    }

    // MARK: - Exercises

    var todaysExercises: [Exercise] {
        if isTodayRestDay { return [] }
        if let cached = cachedExercises { return cached }

        let schedule = scheduledDay(for: programDayNumber)
        let seed = programDayNumber
        let targetCount = exerciseCountForDay(programDayNumber)

        switch schedule {
        case .weakFocus:
            let region = weakestZoneFromScan
            let pool = sortedByDifficultyForWeek(filteredExercises(for: region), dayNumber: programDayNumber)
            var exercises: [Exercise] = []
            var usedIds: Set<String> = Set<String>()
            for i in 0..<min(targetCount + 2, pool.count) {
                let idx = (seed + i) % pool.count
                let ex = pool[idx]
                if !usedIds.contains(ex.id) {
                    exercises.append(ex)
                    usedIds.insert(ex.id)
                }
            }
            let result = Array(exercises.prefix(targetCount))
            saveYesterdayExercises(result)
            return result

        case .fullAbs:
            let result = fullAbsDayExercises(for: programDayNumber)
            saveYesterdayExercises(result)
            return result

        case .weakPair:
            let (r1, r2) = weakPairRegions
            let primaryCount = (targetCount + 1) / 2
            var exercises: [Exercise] = []
            var usedIds: Set<String> = Set(yesterdayExerciseIds)
            let primaryPool = sortedByDifficultyForWeek(
                filteredExercises(for: r1).filter { !usedIds.contains($0.id) },
                dayNumber: programDayNumber
            )
            for i in 0..<primaryPool.count {
                guard exercises.count < primaryCount else { break }
                let idx = (seed + i) % primaryPool.count
                let ex = primaryPool[idx]
                if !usedIds.contains(ex.id) {
                    exercises.append(ex)
                    usedIds.insert(ex.id)
                }
            }
            if r1 != r2 {
                let secondaryPool = sortedByDifficultyForWeek(
                    filteredExercises(for: r2).filter { !usedIds.contains($0.id) },
                    dayNumber: programDayNumber
                )
                for i in 0..<secondaryPool.count {
                    guard exercises.count < targetCount else { break }
                    let idx = (seed + i) % secondaryPool.count
                    let ex = secondaryPool[idx]
                    if !usedIds.contains(ex.id) {
                        exercises.append(ex)
                        usedIds.insert(ex.id)
                    }
                }
            }
            let result = Array(exercises.prefix(targetCount))
            saveYesterdayExercises(result)
            return result

        case .zones(_, _):
            let (primary, secondary) = todayTargetRegions
            let primaryCount = (targetCount + 1) / 2
            var exercises: [Exercise] = []
            var usedIds: Set<String> = Set(yesterdayExerciseIds)
            let primaryPool = sortedByDifficultyForWeek(
                filteredExercises(for: primary).filter { !usedIds.contains($0.id) },
                dayNumber: programDayNumber
            )
            for i in 0..<min(primaryCount, primaryPool.count) {
                let idx = (seed + i) % primaryPool.count
                let ex = primaryPool[idx]
                if !usedIds.contains(ex.id) {
                    exercises.append(ex)
                    usedIds.insert(ex.id)
                }
            }
            let secondaryPool = sortedByDifficultyForWeek(
                filteredExercises(for: secondary).filter { !usedIds.contains($0.id) },
                dayNumber: programDayNumber
            )
            for i in 0..<min(targetCount - primaryCount, secondaryPool.count) {
                guard exercises.count < targetCount else { break }
                let idx = (seed + i) % secondaryPool.count
                let ex = secondaryPool[idx]
                if !usedIds.contains(ex.id) {
                    exercises.append(ex)
                    usedIds.insert(ex.id)
                }
            }
            if exercises.count < targetCount {
                let fallback = filteredAllExercises.filter { !usedIds.contains($0.id) }
                for offset in 0..<fallback.count {
                    guard exercises.count < targetCount else { break }
                    let ex = fallback[(seed + offset) % fallback.count]
                    exercises.append(ex)
                    usedIds.insert(ex.id)
                }
            }
            let result = Array(exercises.prefix(targetCount))
            saveYesterdayExercises(result)
            return result

        case .rest:
            return []
        }
    }

    private func filteredExercises(for region: AbRegion) -> [Exercise] {
        let available = Exercise.exercises(for: region, equipment: profile.equipmentSetting)
        if available.isEmpty {
            return Exercise.exercises(for: region)
        }
        switch profile.equipmentSetting {
        case .gym:
            let gym = available.filter { $0.equipment == .gym }
            let rest = available.filter { $0.equipment != .gym }
            return gym + rest
        case .both:
            let gym = available.filter { $0.equipment == .gym }
            let minimal = available.filter { $0.equipment == .minimal }
            let bodyweight = available.filter { $0.equipment == .none }
            return gym + minimal + bodyweight
        case .home:
            return available
        }
    }

    private var filteredAllExercises: [Exercise] {
        let available = Exercise.allExercises.filter { $0.isAvailable(for: profile.equipmentSetting) }
        if available.isEmpty { return Exercise.allExercises }
        switch profile.equipmentSetting {
        case .gym:
            let gym = available.filter { $0.equipment == .gym }
            let rest = available.filter { $0.equipment != .gym }
            return gym + rest
        case .both:
            let gym = available.filter { $0.equipment == .gym }
            let minimal = available.filter { $0.equipment == .minimal }
            let bodyweight = available.filter { $0.equipment == .none }
            return gym + minimal + bodyweight
        case .home:
            return available
        }
    }

    private func saveYesterdayExercises(_ exercises: [Exercise]) {
        let ids = exercises.map(\.id)
        UserDefaults.standard.set(ids, forKey: "lastDayExercises_\(dateKey)")
    }

    private func loadYesterdayExercises() {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterdayKey = formatter.string(from: yesterday)
        if let ids = UserDefaults.standard.array(forKey: "lastDayExercises_\(yesterdayKey)") as? [String] {
            yesterdayExerciseIds = Set(ids)
        }
    }

    func addExerciseToToday(_ exercise: Exercise) {
        let currentIds = Set(todaysExercises.map(\.id))
        guard !currentIds.contains(exercise.id) else { return }
        var updated = todaysExercises
        updated.append(exercise)
        cachedExercises = updated
        save()
    }

    func swapExercise(at index: Int) {
        guard index < todaysExercises.count else { return }
        let current = todaysExercises[index]
        let sameRegion = filteredExercises(for: current.region)
        let currentIds = Set(todaysExercises.map(\.id))
        let alternatives = sameRegion.filter { !currentIds.contains($0.id) }

        guard let replacement = alternatives.randomElement() else { return }

        var updated = todaysExercises
        if completedExercises.contains(current.id) {
            completedExercises.remove(current.id)
        }
        updated[index] = replacement
        cachedExercises = updated
        save()
    }

    var todaysNutrition: [NutritionTask] { NutritionTask.dailyTasks(for: dayIndex) }

    var todaysMindset: [MindsetTask] {
        let pair = MindsetTask.dailyPair(for: dayIndex)
        return [pair.0, pair.1]
    }

    var allTasksCompleted: Bool {
        todaysExercises.allSatisfy { completedExercises.contains($0.id) }
    }

    func completeExercise(_ id: String) {
        guard !completedExercises.contains(id) else { return }
        completedExercises.insert(id)
        if currentDifficulty != nil {
            difficultyLockedForToday = true
        }
        incrementTotalExercises()
        checkCompletion()
    }

    func completeNutrition(_ id: String) {
        guard !completedNutrition.contains(id) else { return }
        completedNutrition.insert(id)
        checkCompletion()
    }

    func completeMindset(_ id: String) {
        guard !completedMindset.contains(id) else { return }
        completedMindset.insert(id)
        checkCompletion()
    }

    private func checkCompletion() {
        if allTasksCompleted {
            showDailyComplete = true
            updateStreak()
            saveWorkoutToHistory()
            onWorkoutCompleted()
            syncLeaderboard()
            SmartNotificationService.shared.schedulePostWorkoutCelebration(
                name: profile.username.isEmpty ? "Champ" : profile.username,
                streakDays: profile.streakDays,
                exercisesCompleted: displayExercisesWithDifficulty.count,
                todayTargetLabel: todayTargetLabel
            )
            refreshSmartNotifications()
        }
        checkMilestoneUnlocks()
        save()
    }

    var missedYesterday: Bool {
        guard let lastDate = profile.lastActiveDate else { return false }
        let calendar = Calendar.current
        if calendar.isDate(lastDate, inSameDayAs: Date()) { return false }
        guard let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: Date())).day else { return false }
        return daysBetween >= 2 && profile.streakDays > 1
    }

    var previousStreakDays: Int {
        guard missedYesterday else { return profile.streakDays }
        return profile.streakDays
    }

    var streakRecoveredToday: Bool {
        UserDefaults.standard.bool(forKey: "streakRecovered_\(dateKey)")
    }

    func recoverStreak() {
        UserDefaults.standard.set(true, forKey: "streakRecovered_\(dateKey)")
        profile.lastActiveDate = Date()
        save()
    }

    func toggleAICounter() {
        aiCounterEnabled.toggle()
        UserDefaults.standard.set(aiCounterEnabled, forKey: "aiCounterEnabled")
    }

    private func updateStreak() {
        let calendar = Calendar.current
        if let lastDate = profile.lastActiveDate, calendar.isDate(lastDate, inSameDayAs: Date()) { return }
        if let lastDate = profile.lastActiveDate,
           let daysBetween = calendar.dateComponents([.day], from: lastDate, to: Date()).day,
           daysBetween == 1 {
            profile.streakDays += 1
        } else if profile.lastActiveDate == nil {
            profile.streakDays = 1
        } else if streakRecoveredToday {
            profile.streakDays += 1
        } else {
            profile.streakDays = 1
        }
        profile.lastActiveDate = Date()
    }

    var effectiveTotalMealsLogged: Int {
        max(foodLog.count, totalMealsLoggedFromNutrition, UserDefaults.standard.integer(forKey: "totalMealsLoggedAll"))
    }

    func syncWaterFromNutrition(_ glasses: Int) {
        guard glasses != waterGlasses else { return }
        waterGlasses = glasses
        saveWater()
        waterToastCount = waterGlasses
        showWaterToast = true
        let waterGoal = dailyNutrition.waterGoal
        if waterGlasses >= waterGoal && waterGoal > 0 {
            let key = "waterGoalHitToday_\(dateKey)"
            if !UserDefaults.standard.bool(forKey: key) {
                UserDefaults.standard.set(true, forKey: key)
                waterGoalDaysHit += 1
                UserDefaults.standard.set(waterGoalDaysHit, forKey: "waterGoalDaysHit")
            }
        }
        checkMilestoneUnlocks()
    }

    func onNutritionFoodAdded(_ totalMeals: Int, foodName: String = "") {
        totalMealsLoggedFromNutrition = totalMeals
        foodToastName = foodName.isEmpty ? "Food" : foodName
        showFoodToast = true
        checkMilestoneUnlocks()
    }

    func triggerMacroOverToast(macroName: String, overByAmount: Int) {
        let messages: [String: [String]] = [
            "Calories": ["Tomorrow's a fresh start — reset and lock in.", "One day won't derail you. Back on track tomorrow.", "It happens. Tomorrow you crush it."],
            "Protein": ["Extra protein never hurts the grind — you're still winning.", "More fuel for those abs. Adjust tomorrow.", "High protein day. Not the worst problem to have."],
            "Carbs": ["Carbs = energy. Channel it into tomorrow's workout.", "Balance it out tomorrow. You've got this.", "Extra carbs means extra fuel. Use it wisely."],
            "Fat": ["Tomorrow's a clean slate. Keep going.", "One day won't stop your progress — stay consistent.", "Adjust tomorrow and keep building."]
        ]
        let pool = messages[macroName] ?? ["Tomorrow's a fresh start. Keep going."]
        macroOverMessage = pool[Int.random(in: 0..<pool.count)]
        macroOverName = macroName
        macroOverAmount = overByAmount
        showMacroOverToast = true
    }

    func snapshotCurrentMilestones() {
        totalMealsLoggedFromNutrition = UserDefaults.standard.integer(forKey: "totalMealsLoggedAll")
        let saved = loadPersistedMilestoneIds()
        let milestones = AppMilestone.allShuffled(
            streakDays: profile.streakDays,
            totalExercises: totalExercisesCompleted,
            totalScans: scanResults.count,
            totalMealsLogged: effectiveTotalMealsLogged,
            totalWorkoutSessions: workoutHistory.count,
            waterGoalDaysHit: waterGoalDaysHit,
            daysOnProgram: profile.daysOnProgram
        )
        let currentUnlocked = Set(milestones.filter(\.isUnlocked).map(\.id))
        previouslyUnlockedMilestoneIds = saved.isEmpty ? currentUnlocked : saved
        persistMilestoneIds(currentUnlocked)
    }

    private func loadPersistedMilestoneIds() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: "unlockedMilestoneIds"),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return []
        }
        return ids
    }

    private func persistMilestoneIds(_ ids: Set<String>) {
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: "unlockedMilestoneIds")
        }
    }

    func checkMilestoneUnlocks() {
        let milestones = AppMilestone.allShuffled(
            streakDays: profile.streakDays,
            totalExercises: totalExercisesCompleted,
            totalScans: scanResults.count,
            totalMealsLogged: effectiveTotalMealsLogged,
            totalWorkoutSessions: workoutHistory.count,
            waterGoalDaysHit: waterGoalDaysHit,
            daysOnProgram: profile.daysOnProgram
        )
        let currentUnlocked = Set(milestones.filter(\.isUnlocked).map(\.id))
        let newlyUnlocked = currentUnlocked.subtracting(previouslyUnlockedMilestoneIds)
        let suppressedMilestoneIds: Set<String> = ["scan_1"]
        let displayable = newlyUnlocked.subtracting(suppressedMilestoneIds)
        if let firstNew = displayable.first,
           let milestone = milestones.first(where: { $0.id == firstNew }) {
            Task {
                try? await Task.sleep(for: .seconds(2))
                unlockedMilestone = milestone
                showMilestoneUnlock = true
            }
        }
        previouslyUnlockedMilestoneIds = currentUnlocked
        persistMilestoneIds(currentUnlocked)
    }

    func addScanResult(_ result: ScanResult) {
        var scan = result
        scan.phase = profile.currentPhase
        scan.level = profile.currentLevel
        scan.enforceMinimums()

        previousScanBeforeLatest = latestScan

        if !scan.wasAIAnalyzed {
            scan.overallScore = ScanResult.calculateOverall(
                definition: scan.definition, thickness: scan.thickness,
                symmetry: scan.symmetry, obliques: scan.obliques,
                frame: scan.frame, aesthetic: scan.aesthetic
            )
        }

        if let photoData = scan.photoData, scan.photoFileName == nil {
            let fileName = PhotoStorageService.generateFileName()
            PhotoStorageService.savePhoto(photoData, fileName: fileName)
            scan.photoFileName = fileName
            scan.photoData = nil
        }

        scan.enforceMinimums()

        let previousTier: RankTier? = scanResults.last.map { RankTier.tier(for: $0.overallScore) }
        scanResults.append(scan)
        let newTier = RankTier.tier(for: scan.overallScore)
        if let prev = previousTier, prev.name != newTier.name {
            previousBadge = prev
            unlockedBadge = newTier
            showBadgeUnlock = true
        } else if previousTier == nil {
            previousBadge = nil
            unlockedBadge = newTier
            showBadgeUnlock = true
        }
        profile.totalScansUsed += 1
        cachedExercises = nil
        recalculateScanBasedNutrition(from: scan)
        save()
        recalculateAbsProjection()
        syncLeaderboard()
        checkMilestoneUnlocks()

        let weekNum = scanResults.count
        Task {
            let texts = await BreakdownCoachService.shared.generateBreakdownTexts(scan: scan, weekNumber: weekNum, profile: self.profile)
            if let idx = scanResults.firstIndex(where: { $0.id == scan.id }) {
                scanResults[idx].breakdownCoachText = texts.coachText
                scanResults[idx].breakdownWeeklyAction = texts.weeklyAction
                scanResults[idx].breakdownStructureNote = texts.structureNote
                save()
            }
        }
    }

    func analyzeAbPhoto(_ image: UIImage?) async -> ScanResult? {
        if let image = image {
            if let aiResult = await AbScanService.shared.analyzePhoto(image, profile: profile) {
                if aiResult.poorPhoto {
                    return nil
                }
                var scan = ScanResult.fromAnalysis(aiResult)
                scan.phase = profile.currentPhase
                scan.level = profile.currentLevel
                return scan
            }

            if let scanError = AbScanService.shared.lastScanError, scanError.isBadPhoto {
                return nil
            }

            print("[AppVM] API failed, falling back to profile-based scoring")
            let fallback = AbScanService.shared.profileBasedScoring(
                profile: profile,
                previousScan: latestScan,
                daysOnProgram: profile.daysOnProgram,
                exercisesCompleted: totalExercisesCompleted
            )
            var scan = ScanResult.fromAnalysis(fallback)
            scan.wasAIAnalyzed = false
            scan.phase = profile.currentPhase
            scan.level = profile.currentLevel
            return scan
        }

        let fallback = AbScanService.shared.profileBasedScoring(
            profile: profile,
            previousScan: latestScan,
            daysOnProgram: profile.daysOnProgram,
            exercisesCompleted: totalExercisesCompleted
        )
        var scan = ScanResult.fromAnalysis(fallback)
        scan.wasAIAnalyzed = false
        scan.phase = profile.currentPhase
        scan.level = profile.currentLevel
        return scan
    }

    func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
        if let data = try? JSONEncoder().encode(scanResults) {
            UserDefaults.standard.set(data, forKey: "scanResults")
        }
        saveCompletedTasks()
    }

    private func saveCompletedTasks() {
        UserDefaults.standard.set(dateKey, forKey: "lastCompletedDate")
        if let data = try? JSONEncoder().encode(completedExercises) {
            UserDefaults.standard.set(data, forKey: "completedExercises_\(dateKey)")
        }
        if let data = try? JSONEncoder().encode(completedNutrition) {
            UserDefaults.standard.set(data, forKey: "completedNutrition_\(dateKey)")
        }
        if let data = try? JSONEncoder().encode(completedMindset) {
            UserDefaults.standard.set(data, forKey: "completedMindset_\(dateKey)")
        }
    }

    var currentStage: TrainingStage? {
        guard trainingPlan.currentStageIndex < trainingPlan.stages.count else { return nil }
        return trainingPlan.stages[trainingPlan.currentStageIndex]
    }

    var currentDay: TrainingDay? {
        guard let stage = currentStage,
              trainingPlan.currentDayIndex < stage.days.count else { return nil }
        return stage.days[trainingPlan.currentDayIndex]
    }

    func exercisesForDay(_ day: TrainingDay) -> [Exercise] {
        day.exerciseIds.compactMap { id in
            Exercise.allExercises.first { $0.id == id }
        }
    }

    func ensureTrainingPlan() {
        guard !trainingPlan.isGenerated else { return }
        trainingPlan = TrainingPlanGenerator.generatePlan(weakRegions: weakestRegions)
        saveTrainingPlan()
    }

    func completeCurrentDay() {
        guard trainingPlan.isGenerated else { return }
        let si = trainingPlan.currentStageIndex
        let di = trainingPlan.currentDayIndex
        guard si < trainingPlan.stages.count,
              di < trainingPlan.stages[si].days.count else { return }

        trainingPlan.stages[si].days[di].isCompleted = true

        let nextDi = di + 1
        if nextDi < trainingPlan.stages[si].days.count {
            trainingPlan.currentDayIndex = nextDi
            trainingPlan.stages[si].days[nextDi].isUnlocked = true
        } else {
            let nextSi = si + 1
            if nextSi < trainingPlan.stages.count {
                trainingPlan.currentStageIndex = nextSi
                trainingPlan.currentDayIndex = 0
                trainingPlan.stages[nextSi].days[0].isUnlocked = true
            }
        }
        saveTrainingPlan()
    }

    func skipRestDay() {
        guard let day = currentDay, day.isRestDay else { return }
        completeCurrentDay()
    }

    private func saveTrainingPlan() {
        if let data = try? JSONEncoder().encode(trainingPlan) {
            UserDefaults.standard.set(data, forKey: "trainingPlan")
        }
    }

    func regenerateTrainingPlan() {
        trainingPlan = TrainingPlanGenerator.generatePlan(weakRegions: weakestRegions)
        saveTrainingPlan()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "scanResults"),
           let decoded = try? JSONDecoder().decode([ScanResult].self, from: data) {
            scanResults = decoded
            migratePhotoDataToFiles()
        }
        if let data = try? Data(contentsOf: Self.foodLogFileURL),
           let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) {
            foodLog = decoded
        } else if let data = UserDefaults.standard.data(forKey: "foodLog"),
                  let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) {
            foodLog = decoded
            saveFoodLog()
            UserDefaults.standard.removeObject(forKey: "foodLog")
        }
        pruneFoodLog()
        if let data = UserDefaults.standard.data(forKey: "dailyNutrition"),
           let decoded = try? JSONDecoder().decode(DailyNutrition.self, from: data) {
            dailyNutrition = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "dailyPhotos"),
           let decoded = try? JSONDecoder().decode([DailyPhoto].self, from: data) {
            dailyPhotos = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "whyReasons"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            whyReasons = decoded
        }
        waterGlasses = UserDefaults.standard.integer(forKey: "waterGlasses_\(dateKey)")
        let calendar = Calendar.current
        dayIndex = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0

        let savedDate = UserDefaults.standard.string(forKey: "lastCompletedDate") ?? ""
        if savedDate == dateKey {
            if let exData = UserDefaults.standard.data(forKey: "completedExercises_\(dateKey)"),
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: exData) {
                completedExercises = decoded
            }
            if let ntData = UserDefaults.standard.data(forKey: "completedNutrition_\(dateKey)"),
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: ntData) {
                completedNutrition = decoded
            }
            if let mtData = UserDefaults.standard.data(forKey: "completedMindset_\(dateKey)"),
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: mtData) {
                completedMindset = decoded
            }
        } else {
            completedExercises = []
            completedNutrition = []
            completedMindset = []
        }
        lastCompletedDate = dateKey
        cachedExercises = nil
        loadYesterdayExercises()
        loadFeelCheck()
        loadDifficulty()

        if profile.hasCompletedOnboarding {
            dailyNutrition = profile.toDailyNutrition()
        }
        loadExtendedData()
        loadTrainingPlan()
        loadWorkoutHistory()
        loadProfileImage()
        loadAbsProjection()
        syncLeaderboard()
        snapshotCurrentMilestones()
    }

    private func loadTrainingPlan() {
        if let data = UserDefaults.standard.data(forKey: "trainingPlan"),
           let decoded = try? JSONDecoder().decode(TrainingPlanData.self, from: data) {
            trainingPlan = decoded
        }
        ensureTrainingPlan()
    }

    func saveReasons() {
        if let data = try? JSONEncoder().encode(whyReasons) {
            UserDefaults.standard.set(data, forKey: "whyReasons")
        }
    }

    private func saveDailyNutrition() {
        if let data = try? JSONEncoder().encode(dailyNutrition) {
            UserDefaults.standard.set(data, forKey: "dailyNutrition")
        }
    }

    private func migratePhotoDataToFiles() {
        var needsSave = false
        for i in scanResults.indices {
            if let photoData = scanResults[i].photoData, scanResults[i].photoFileName == nil {
                let fileName = PhotoStorageService.generateFileName()
                PhotoStorageService.savePhoto(photoData, fileName: fileName)
                scanResults[i].photoFileName = fileName
                scanResults[i].photoData = nil
                needsSave = true
            }
        }
        if needsSave {
            save()
        }
    }

    // MARK: - Scan-Based Nutrition Calculation

    func recalculateScanBasedNutrition(from scan: ScanResult) {
        let bodyFat = scan.estimatedBodyFat
        let absStructure = scan.absStructure.rawValue

        let bmrVal: Double
        switch profile.gender {
        case .male:
            bmrVal = (10.0 * profile.weightInKg) + (6.25 * profile.heightInCm) - (5.0 * Double(profile.age)) + 5.0
        case .female:
            bmrVal = (10.0 * profile.weightInKg) + (6.25 * profile.heightInCm) - (5.0 * Double(profile.age)) - 161.0
        case .other:
            bmrVal = (10.0 * profile.weightInKg) + (6.25 * profile.heightInCm) - (5.0 * Double(profile.age)) - 78.0
        }

        let tdeeMultiplier: Double
        switch profile.activityLevel {
        case .sedentary:
            tdeeMultiplier = 1.2
        case .lightlyActive:
            tdeeMultiplier = 1.375
        case .moderatelyActive:
            tdeeMultiplier = 1.55
        case .veryActive:
            tdeeMultiplier = 1.725
        }
        let tdeeVal = bmrVal * tdeeMultiplier

        let deficitPercentage: Double
        switch bodyFat {
        case ..<12:   deficitPercentage = 0.05
        case 12..<15: deficitPercentage = 0.10
        case 15..<17: deficitPercentage = 0.15
        case 17..<20: deficitPercentage = 0.20
        default:      deficitPercentage = 0.22
        }
        let deficit = tdeeVal * deficitPercentage
        let finalDeficit = min(deficit, 500)
        let dailyCalorieTarget = Int(round(max(tdeeVal - finalDeficit, bmrVal)))

        let proteinG = Int(round(profile.weightInLbs * 1.0))
        let fatG = Int(round(Double(dailyCalorieTarget) * 0.25 / 9.0))
        let proteinCal = Double(proteinG) * 4.0
        let fatCal = Double(fatG) * 9.0
        let carbsG = Int(round(max((Double(dailyCalorieTarget) - proteinCal - fatCal) / 4.0, 50)))

        let upperAbsWeeks = min(max(0, Int(round(((bodyFat - 16.0) / 0.5) * 4.0))), 52)
        let obliquesWeeks = min(max(0, Int(round(((bodyFat - 14.0) / 0.5) * 4.0))), 52)
        let lowerAbsWeeks = min(max(0, Int(round(((bodyFat - 12.0) / 0.5) * 4.0))), 52)
        let vtaperWeeks = min(max(0, Int(round(((bodyFat - 10.0) / 0.5) * 4.0))), 52)

        profile.scanBodyFatEstimate = bodyFat
        profile.scanAbsStructure = absStructure
        profile.scanDailyCalorieTarget = dailyCalorieTarget
        profile.scanProteinG = proteinG
        profile.scanCarbsG = carbsG
        profile.scanFatG = fatG
        profile.scanDeficit = Int(round(finalDeficit))
        profile.scanUpperAbsWeeks = upperAbsWeeks
        profile.scanObliquesWeeks = obliquesWeeks
        profile.scanLowerAbsWeeks = lowerAbsWeeks
        profile.scanVtaperWeeks = vtaperWeeks

        recalculateNutrition()
    }

    // MARK: - Recovery

    var isRestDay: Bool {
        isTodayRestDay
    }

    func logRecovery(sorenessLevel: Int, sleepHours: Double) {
        let calendar = Calendar.current
        if let index = recoveryDays.firstIndex(where: { calendar.isDateInToday($0.date) }) {
            recoveryDays[index].sorenessLevel = sorenessLevel
            recoveryDays[index].sleepHours = sleepHours
            recoveryDays[index].isRestDay = isRestDay
        } else {
            let entry = RecoveryDay(date: Date(), isRestDay: isRestDay, sorenessLevel: sorenessLevel, sleepHours: sleepHours)
            recoveryDays.append(entry)
        }
        saveRecoveryDays()
    }

    private func saveRecoveryDays() {
        if let data = try? JSONEncoder().encode(recoveryDays) {
            UserDefaults.standard.set(data, forKey: "recoveryDays")
        }
    }


    // MARK: - Notifications

    func requestNotificationPermission() {
        Task {
            let granted = await SmartNotificationService.shared.requestPermission()
            notificationsEnabled = granted
            UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
            if granted {
                refreshSmartNotifications()
            }
        }
    }

    func refreshSmartNotifications() {
        guard notificationsEnabled else { return }
        SmartNotificationService.shared.cancelReEngagementNotifications()
        SmartNotificationService.shared.scheduleAllNotifications(
            streakDays: profile.streakDays,
            hasCompletedTodayWorkout: allTasksCompleted,
            isTodayRestDay: isTodayRestDay,
            todayTargetLabel: todayTargetLabel,
            exerciseCount: displayExercisesWithDifficulty.count,
            scanAvailable: canScan,
            bodyFatPercent: latestScan?.estimatedBodyFat,
            overallScore: latestScan?.overallScore,
            weakestZone: weakestZoneFromScan.rawValue,
            caloriesRemaining: caloriesRemaining,
            proteinProgress: proteinProgress,
            waterGlasses: waterGlasses,
            waterGoal: dailyNutrition.waterGoal,
            programDayNumber: programDayNumber,
            username: profile.username
        )
    }

    // MARK: - Extended Load/Save

    func loadExtendedData() {
        if let data = UserDefaults.standard.data(forKey: "recoveryDays"),
           let decoded = try? JSONDecoder().decode([RecoveryDay].self, from: data) {
            recoveryDays = decoded
        }
        totalExercisesCompleted = UserDefaults.standard.integer(forKey: "totalExercisesCompleted")
        waterGoalDaysHit = UserDefaults.standard.integer(forKey: "waterGoalDaysHit")
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if UserDefaults.standard.object(forKey: "aiCounterEnabled") != nil {
            aiCounterEnabled = UserDefaults.standard.bool(forKey: "aiCounterEnabled")
        }
    }

    func incrementTotalExercises() {
        totalExercisesCompleted += 1
        UserDefaults.standard.set(totalExercisesCompleted, forKey: "totalExercisesCompleted")
    }

    // MARK: - Workout History

    func saveWorkoutToHistory() {
        let completedIds = completedExercises
        let exercises = displayExercisesWithDifficulty.filter { completedIds.contains($0.id) }
        guard !exercises.isEmpty else { return }

        let entries = exercises.map { ex in
            CompletedExerciseEntry(
                id: ex.id,
                name: ex.name,
                region: ex.region.rawValue,
                reps: progressiveRepsString(for: ex),
            )
        }

        let workout = CompletedWorkout(
            exercises: entries,
            targetLabel: todayTargetLabel,
            difficultyLevel: (currentDifficulty ?? .medium).rawValue,
            durationMinutes: exercises.count * 4 + 3
        )

        let alreadyLogged = workoutHistory.contains { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
        if !alreadyLogged {
            workoutHistory.append(workout)
            saveWorkoutHistory()
        }
    }

    private func saveWorkoutHistory() {
        if let data = try? JSONEncoder().encode(workoutHistory) {
            UserDefaults.standard.set(data, forKey: "workoutHistory")
        }
    }

    private func loadWorkoutHistory() {
        if let data = UserDefaults.standard.data(forKey: "workoutHistory"),
           let decoded = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            workoutHistory = decoded
        }
    }

    // MARK: - Profile Picture

    func saveProfileImage(_ image: UIImage) {
        profileImage = image
        if let data = image.jpegData(compressionQuality: 0.85) {
            let url = Self.profilePictureURL
            try? data.write(to: url)
        }
    }

    func loadProfileImage() {
        let url = Self.profilePictureURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return }
        profileImage = image
    }

    private static var profilePictureURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_picture.jpg")
    }

    // MARK: - Leaderboard Sync

    func syncLeaderboard() {
        let deviceId = DeviceIdentityService.shared.deviceId
        let score = latestScan?.overallScore ?? 0
        let streak = profile.streakDays
        let name = profile.displayName
        Task {
            await LeaderboardService.shared.upsertEntry(
                deviceId: deviceId,
                displayName: name,
                score: score,
                streakDays: streak
            )
        }
    }

    func resetAllData() {
        profile = UserProfile()
        scanResults = []
        completedExercises = []
        completedNutrition = []
        completedMindset = []
        foodLog = []
        dailyNutrition = DailyNutrition()
        waterGlasses = 0
        dailyPhotos = []
        whyReasons = []
        recoveryDays = []
        totalExercisesCompleted = 0
        waterGoalDaysHit = 0
        notificationsEnabled = false
        trainingPlan = TrainingPlanData()
        workoutHistory = []
        profileImage = nil
        cachedExercises = nil
        currentFeelCheck = nil
        currentDifficulty = nil

        let domain = Bundle.main.bundleIdentifier ?? ""
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()

        try? FileManager.default.removeItem(at: Self.profilePictureURL)
        try? FileManager.default.removeItem(at: Self.foodLogFileURL)

        PhotoStorageService.deleteAllPhotos()
    }
}
