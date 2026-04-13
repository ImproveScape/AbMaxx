import Foundation

nonisolated struct Phase: Identifiable, Sendable {
    let id: Int
    let name: String
    let icon: String

    static let allPhases: [Phase] = [
        Phase(id: 0, name: "Rookie", icon: "shield.fill"),
        Phase(id: 1, name: "Flexer", icon: "bolt.shield.fill"),
        Phase(id: 2, name: "Alpha", icon: "crown.fill"),
        Phase(id: 3, name: "Mogger", icon: "star.circle.fill"),
        Phase(id: 4, name: "God Tier", icon: "sparkle"),
        Phase(id: 5, name: "Legend", icon: "laurel.leading"),
    ]

    static func phase(for index: Int) -> Phase {
        guard index >= 0, index < allPhases.count else { return allPhases[0] }
        return allPhases[index]
    }
}
