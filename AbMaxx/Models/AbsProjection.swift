import Foundation

nonisolated struct AbsProjection: Codable, Sendable {
    var currentBodyFat: Double = 20.0
    var targetBodyFat: Double = 12.0
    var plannedDailyDeficit: Double = 400.0
    var effectiveDailyDeficit: Double = 400.0
    var totalSurplusCaloriesLast30: Double = 0
    var trackedDaysLast30: Int = 0
    var daysOverLast30: Int = 0
    var scheduledWorkoutsLast30: Int = 0
    var completedWorkoutsLast30: Int = 0
    var workoutAdherenceRate: Double = 1.0
    var nutritionAdherenceRate: Double = 1.0
    var currentScore: Int = 0
    var targetScore: Int = 75
    var streakDays: Int = 0
    var bodyWeightKg: Double = 77.0
    var lastCalculatedDate: Date = Date()

    var weeklyFatLossLbs: Double {
        let effectiveWeeklyDeficit = effectiveDailyDeficit * 7.0
        return max(effectiveWeeklyDeficit / 3500.0, 0)
    }

    var weeklyBFChangePercent: Double {
        guard bodyWeightKg > 0 else { return 0.15 }
        let kgPerWeek = weeklyFatLossLbs * 0.453592
        return max((kgPerWeek / bodyWeightKg) * 100.0, 0.05)
    }

    var bfToLose: Double {
        max(currentBodyFat - targetBodyFat, 0)
    }

    var weeksFromBodyFat: Double {
        guard weeklyBFChangePercent > 0 else { return 52 }
        return min(bfToLose / weeklyBFChangePercent, 104)
    }

    var baseScoreGainPerWeek: Double { 2.5 }

    var effectiveScoreGainPerWeek: Double {
        baseScoreGainPerWeek * workoutAdherenceRate * max(nutritionAdherenceRate, 0.4)
    }

    var scoreGap: Int {
        max(targetScore - currentScore, 0)
    }

    var weeksFromScore: Double {
        guard effectiveScoreGainPerWeek > 0 else { return 52 }
        return min(Double(scoreGap) / effectiveScoreGainPerWeek, 104)
    }

    var totalProjectedWeeks: Double {
        let limiting = max(weeksFromBodyFat, weeksFromScore)
        return max(limiting, 1)
    }

    var totalProjectedDays: Double {
        totalProjectedWeeks * 7.0
    }

    var projectedDate: Date {
        Calendar.current.date(byAdding: .day, value: Int(ceil(totalProjectedDays)), to: Date()) ?? Date()
    }

    var projectedWeeks: Int {
        max(Int(ceil(totalProjectedWeeks)), 1)
    }

    var daysAddedByNutrition: Double {
        guard plannedDailyDeficit > 0 else { return 0 }
        let idealWeeks = bfToLose / max((plannedDailyDeficit * 7.0 / 3500.0 * 0.453592 / max(bodyWeightKg, 60)) * 100.0, 0.05)
        let actualWeeks = weeksFromBodyFat
        return max((actualWeeks - idealWeeks) * 7.0, 0)
    }

    var daysAddedByMissedWorkouts: Double {
        guard workoutAdherenceRate < 1.0 else { return 0 }
        let idealWeeks = Double(scoreGap) / max(baseScoreGainPerWeek, 0.1)
        let actualWeeks = weeksFromScore
        return max((actualWeeks - idealWeeks) * 7.0, 0)
    }

    var limitingFactor: LimitingFactor {
        if weeksFromBodyFat >= weeksFromScore {
            return .bodyFat
        }
        return .muscleScore
    }

    nonisolated init() {}

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentBodyFat = try container.decodeIfPresent(Double.self, forKey: .currentBodyFat) ?? 20.0
        targetBodyFat = try container.decodeIfPresent(Double.self, forKey: .targetBodyFat) ?? 12.0
        plannedDailyDeficit = try container.decodeIfPresent(Double.self, forKey: .plannedDailyDeficit) ?? 400.0
        effectiveDailyDeficit = try container.decodeIfPresent(Double.self, forKey: .effectiveDailyDeficit) ?? 400.0
        totalSurplusCaloriesLast30 = try container.decodeIfPresent(Double.self, forKey: .totalSurplusCaloriesLast30) ?? 0
        trackedDaysLast30 = try container.decodeIfPresent(Int.self, forKey: .trackedDaysLast30) ?? 0
        daysOverLast30 = try container.decodeIfPresent(Int.self, forKey: .daysOverLast30) ?? 0
        scheduledWorkoutsLast30 = try container.decodeIfPresent(Int.self, forKey: .scheduledWorkoutsLast30) ?? 0
        completedWorkoutsLast30 = try container.decodeIfPresent(Int.self, forKey: .completedWorkoutsLast30) ?? 0
        workoutAdherenceRate = try container.decodeIfPresent(Double.self, forKey: .workoutAdherenceRate) ?? 1.0
        nutritionAdherenceRate = try container.decodeIfPresent(Double.self, forKey: .nutritionAdherenceRate) ?? 1.0
        currentScore = try container.decodeIfPresent(Int.self, forKey: .currentScore) ?? 0
        targetScore = try container.decodeIfPresent(Int.self, forKey: .targetScore) ?? 75
        streakDays = try container.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        bodyWeightKg = try container.decodeIfPresent(Double.self, forKey: .bodyWeightKg) ?? 77.0
        lastCalculatedDate = try container.decodeIfPresent(Date.self, forKey: .lastCalculatedDate) ?? Date()
    }
}

nonisolated enum LimitingFactor: String, Codable, Sendable {
    case bodyFat
    case muscleScore
}

nonisolated enum AbsGoalLevel: String, Codable, Sendable {
    case visibleAbs = "Visible Abs"
    case fourPack = "4-Pack"
    case sixPack = "6-Pack"
    case shreddedSixPack = "Shredded 6-Pack"

    var targetBodyFat: Double {
        switch self {
        case .visibleAbs: return 15.0
        case .fourPack: return 13.0
        case .sixPack: return 11.0
        case .shreddedSixPack: return 8.0
        }
    }

    var targetOverallScore: Int {
        switch self {
        case .visibleAbs: return 45
        case .fourPack: return 60
        case .sixPack: return 75
        case .shreddedSixPack: return 88
        }
    }

    var icon: String {
        switch self {
        case .visibleAbs: return "eye.fill"
        case .fourPack: return "square.grid.2x2.fill"
        case .sixPack: return "trophy.fill"
        case .shreddedSixPack: return "bolt.shield.fill"
        }
    }
}
