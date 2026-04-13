import Foundation

nonisolated struct TrainingStage: Identifiable, Codable, Sendable {
    let id: Int
    let name: String
    let subtitle: String
    var days: [TrainingDay]

    var totalWorkoutDays: Int { days.filter { !$0.isRestDay }.count }
    var completedWorkoutDays: Int { days.filter { $0.isCompleted && !$0.isRestDay }.count }
}

nonisolated struct TrainingDay: Identifiable, Codable, Sendable {
    let id: String
    let dayNumber: Int
    let isRestDay: Bool
    var isCompleted: Bool = false
    var isUnlocked: Bool = false
    var exerciseIds: [String] = []

    var estimatedCalories: Int {
        if isRestDay { return 0 }
        return exerciseIds.count * 25 + Int.random(in: 0...15)
    }

    var estimatedMinutes: Int {
        if isRestDay { return 0 }
        return exerciseIds.count * 4 + 3
    }
}

nonisolated struct TrainingPlanData: Codable, Sendable {
    var currentStageIndex: Int = 0
    var currentDayIndex: Int = 0
    var stages: [TrainingStage] = []
    var isGenerated: Bool = false
}

enum TrainingPlanGenerator {
    static let stageTemplates: [(name: String, subtitle: String)] = [
        ("Stage 1", "Activate Deep Core"),
        ("Stage 2", "Build Definition"),
        ("Stage 3", "Sculpt & Strengthen"),
        ("Stage 4", "Peak Performance")
    ]

    static func stageInfo(for weakRegions: [AbRegion], stageIndex: Int) -> (name: String, subtitle: String) {
        let subtitles: [[AbRegion]: [String]] = [
            [.deepCore, .upperAbs]: ["Activate Deep Core", "Carve Upper Blocks", "Forge Core Power", "Shredded Finish"],
            [.deepCore, .lowerAbs]: ["Activate Deep Core", "Lower Ab Attack", "Total Core Build", "Peak Shred"],
            [.deepCore, .obliques]: ["Activate Deep Core", "Oblique Definition", "360° Core Sculpt", "Final Form"],
            [.upperAbs, .lowerAbs]: ["Upper Ab Ignition", "Lower Ab Lockdown", "Full Six-Pack Build", "Diamond Cut"],
            [.upperAbs, .obliques]: ["Upper Ab Ignition", "Oblique Chisel", "V-Taper Sculpt", "Razor Definition"],
            [.lowerAbs, .obliques]: ["Lower Ab Activation", "Oblique Forge", "Core Integration", "Elite Finish"],
        ]

        let key = weakRegions.sorted { $0.rawValue < $1.rawValue }
        let idx = min(stageIndex, 3)

        for (k, v) in subtitles {
            let sortedK = k.sorted { $0.rawValue < $1.rawValue }
            if sortedK == key {
                return ("Stage \(stageIndex + 1)", v[idx])
            }
        }

        return stageTemplates[idx]
    }

    static func generatePlan(weakRegions: [AbRegion]) -> TrainingPlanData {
        var plan = TrainingPlanData()
        var allUsedIds: Set<String> = []

        for stageIdx in 0..<4 {
            let info = stageInfo(for: weakRegions, stageIndex: stageIdx)
            var days: [TrainingDay] = []

            for dayNum in 1...7 {
                let isRest = dayNum == 3 || dayNum == 7
                let dayId = "s\(stageIdx)d\(dayNum)"

                if isRest {
                    var day = TrainingDay(id: dayId, dayNumber: dayNum, isRestDay: true)
                    day.isUnlocked = (stageIdx == 0 && dayNum == 1)
                    days.append(day)
                } else {
                    let exercises = pickExercises(
                        weakRegions: weakRegions,
                        stageIndex: stageIdx,
                        dayInStage: dayNum,
                        usedIds: &allUsedIds
                    )
                    var day = TrainingDay(
                        id: dayId,
                        dayNumber: dayNum,
                        isRestDay: false,
                        exerciseIds: exercises
                    )
                    day.isUnlocked = (stageIdx == 0 && dayNum == 1)
                    days.append(day)
                }
            }

            let stage = TrainingStage(
                id: stageIdx,
                name: info.name,
                subtitle: info.subtitle,
                days: days
            )
            plan.stages.append(stage)
        }

        plan.isGenerated = true
        return plan
    }

    private static func pickExercises(
        weakRegions: [AbRegion],
        stageIndex: Int,
        dayInStage: Int,
        usedIds: inout Set<String>
    ) -> [String] {
        var picked: [String] = []
        var localUsed: Set<String> = []
        let difficultyForStage: [ExerciseDifficulty] = {
            switch stageIndex {
            case 0: return [.beginner, .beginner, .intermediate]
            case 1: return [.beginner, .intermediate, .intermediate]
            case 2: return [.intermediate, .intermediate, .advanced]
            default: return [.intermediate, .advanced, .advanced]
            }
        }()

        for region in weakRegions {
            let pool = Exercise.exercises(for: region)
                .filter { !localUsed.contains($0.id) }
                .sorted { ex1, ex2 in
                    let d1 = difficultyForStage.contains(ex1.difficulty) ? 0 : 1
                    let d2 = difficultyForStage.contains(ex2.difficulty) ? 0 : 1
                    return d1 < d2
                }
            let offset = (stageIndex * 7 + dayInStage) % max(pool.count, 1)
            if !pool.isEmpty {
                let ex = pool[offset % pool.count]
                picked.append(ex.id)
                localUsed.insert(ex.id)
            }
        }

        let otherRegions = AbRegion.allCases.filter { !weakRegions.contains($0) }
        let otherPool = otherRegions.flatMap { Exercise.exercises(for: $0) }
            .filter { !localUsed.contains($0.id) }
        let seed = stageIndex * 10 + dayInStage
        if !otherPool.isEmpty {
            let ex = otherPool[seed % otherPool.count]
            picked.append(ex.id)
            localUsed.insert(ex.id)
        }

        while picked.count < 4 {
            let fallback = Exercise.allExercises.filter { !localUsed.contains($0.id) }
            guard !fallback.isEmpty else { break }
            let ex = fallback[(seed + picked.count) % fallback.count]
            picked.append(ex.id)
            localUsed.insert(ex.id)
        }

        usedIds.formUnion(localUsed)
        return Array(picked.prefix(4))
    }
}
