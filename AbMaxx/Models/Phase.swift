import Foundation

nonisolated struct Phase: Identifiable, Sendable {
    let id: Int
    let name: String
    let icon: String
    let xpPerLevel: Int
    let levelsCount: Int = 6

    var totalXPNeeded: Int { xpPerLevel * levelsCount }

    static let allPhases: [Phase] = [
        Phase(id: 0, name: "Rookie", icon: "shield.fill", xpPerLevel: 100),
        Phase(id: 1, name: "Flexer", icon: "bolt.shield.fill", xpPerLevel: 150),
        Phase(id: 2, name: "Alpha", icon: "crown.fill", xpPerLevel: 250),
        Phase(id: 3, name: "Mogger", icon: "star.circle.fill", xpPerLevel: 300),
        Phase(id: 4, name: "God Tier", icon: "sparkle", xpPerLevel: 350),
        Phase(id: 5, name: "Legend", icon: "laurel.leading", xpPerLevel: 400),
    ]

    static func phase(for index: Int) -> Phase {
        guard index >= 0, index < allPhases.count else { return allPhases[0] }
        return allPhases[index]
    }
}

nonisolated struct LevelInfo: Sendable {
    let phase: Phase
    let level: Int
    let xpInLevel: Int
    let xpNeeded: Int
    let isUnlocked: Bool
    let isCurrent: Bool
    let isCompleted: Bool

    var progress: Double {
        guard xpNeeded > 0 else { return 0 }
        return min(Double(xpInLevel) / Double(xpNeeded), 1.0)
    }

    var displayName: String {
        "\(phase.name) \(level + 1)"
    }
}
