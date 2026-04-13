import Foundation

nonisolated struct DailyPhoto: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var date: Date = Date()
    var dayNumber: Int = 0
}
