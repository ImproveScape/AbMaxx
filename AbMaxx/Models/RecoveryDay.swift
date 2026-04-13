import Foundation

nonisolated struct RecoveryDay: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var date: Date = Date()
    var isRestDay: Bool = false
    var sorenessLevel: Int = 0
    var sleepHours: Double = 7.0
    var notes: String = ""

    var sorenessLabel: String {
        switch sorenessLevel {
        case 0: return "None"
        case 1: return "Mild"
        case 2: return "Moderate"
        case 3: return "Sore"
        case 4: return "Very Sore"
        default: return "Unknown"
        }
    }

    var recoveryScore: Int {
        var score = 100
        score -= sorenessLevel * 15
        if sleepHours < 6 { score -= 20 }
        else if sleepHours < 7 { score -= 10 }
        else if sleepHours >= 8 { score += 5 }
        return max(0, min(100, score))
    }
}
