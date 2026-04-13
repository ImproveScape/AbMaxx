import Foundation

nonisolated struct CompletedWorkout: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let exercises: [CompletedExerciseEntry]
    let targetLabel: String
    let difficultyLevel: String
    let durationMinutes: Int
    let totalXP: Int

    init(date: Date = Date(), exercises: [CompletedExerciseEntry], targetLabel: String, difficultyLevel: String, durationMinutes: Int, totalXP: Int) {
        self.id = UUID()
        self.date = date
        self.exercises = exercises
        self.targetLabel = targetLabel
        self.difficultyLevel = difficultyLevel
        self.durationMinutes = durationMinutes
        self.totalXP = totalXP
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        exercises = try container.decode([CompletedExerciseEntry].self, forKey: .exercises)
        targetLabel = try container.decode(String.self, forKey: .targetLabel)
        difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel) ?? "Medium"
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes) ?? 0
        totalXP = try container.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
    }
}

nonisolated struct CompletedExerciseEntry: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let region: String
    let reps: String
    let xp: Int
}
