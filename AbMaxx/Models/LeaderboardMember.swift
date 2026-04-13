import Foundation

nonisolated struct LeaderboardMember: Identifiable, Sendable {
    let id: String
    let name: String
    let score: Int
    let streakDays: Int
    let initials: String
    let color: String

    static let celebrities: [LeaderboardMember] = [
        LeaderboardMember(id: "1", name: "", score: 96, streakDays: 868, initials: "", color: "blue"),
        LeaderboardMember(id: "2", name: "", score: 94, streakDays: 858, initials: "", color: "green"),
        LeaderboardMember(id: "3", name: "", score: 92, streakDays: 844, initials: "", color: "orange"),
        LeaderboardMember(id: "4", name: "", score: 91, streakDays: 748, initials: "", color: "green"),
        LeaderboardMember(id: "5", name: "", score: 89, streakDays: 747, initials: "", color: "blue"),
        LeaderboardMember(id: "6", name: "", score: 88, streakDays: 746, initials: "", color: "red"),
        LeaderboardMember(id: "7", name: "", score: 87, streakDays: 720, initials: "", color: "purple"),
        LeaderboardMember(id: "8", name: "", score: 85, streakDays: 695, initials: "", color: "orange"),
        LeaderboardMember(id: "9", name: "", score: 84, streakDays: 680, initials: "", color: "green"),
        LeaderboardMember(id: "10", name: "", score: 82, streakDays: 654, initials: "", color: "blue"),
    ]
}
