import Foundation

nonisolated struct LeaderboardMember: Identifiable, Sendable {
    let id: String
    let name: String
    let score: Int
    let streakDays: Int
    let initials: String
    let color: String
    var rank: Int = 0

    static let celebrities: [LeaderboardMember] = {
        let names: [(String, String)] = [
            ("Marcus Chen", "MC"), ("Tyler Brooks", "TB"), ("Jordan Rivera", "JR"),
            ("Aiden Walsh", "AW"), ("Kai Nakamura", "KN"), ("Ethan Cole", "EC"),
            ("Liam Foster", "LF"), ("Noah Park", "NP"), ("Dylan Reed", "DR"),
            ("Mason Cruz", "MC"), ("Jake Morales", "JM"), ("Ryan Ortiz", "RO"),
            ("Caleb Kim", "CK"), ("Lucas Grant", "LG"), ("Owen Bailey", "OB"),
            ("Hunter Ross", "HR"), ("Alex Tran", "AT"), ("Bryce Morgan", "BM"),
            ("Colton Hayes", "CH"), ("Derek Pham", "DP"), ("Eli Santos", "ES"),
            ("Finn O'Brien", "FO"), ("Grant Ellis", "GE"), ("Isaiah Dunn", "ID"),
            ("Jace Cooper", "JC"), ("Kevin Reyes", "KR"), ("Leo Vasquez", "LV"),
            ("Miles Turner", "MT"), ("Nate Sullivan", "NS"), ("Oscar Ramirez", "OR"),
            ("Preston Lee", "PL"), ("Quinn Murphy", "QM"), ("Reed Jackson", "RJ"),
            ("Seth Howard", "SH"), ("Trevor Diaz", "TD"), ("Vince Nguyen", "VN"),
            ("Wesley Price", "WP"), ("Xavier Ruiz", "XR"), ("Zane Fisher", "ZF"),
            ("Aaron Mitchell", "AM"), ("Blake Griffin", "BG"), ("Carter Young", "CY"),
            ("Damian Scott", "DS"), ("Evan Torres", "ET"), ("Felix Herrera", "FH"),
            ("Gavin Stewart", "GS"), ("Hugo Flores", "HF"), ("Ivan Lopez", "IL"),
            ("Jason Bell", "JB"), ("Kyle Adams", "KA"), ("Logan White", "LW"),
        ]

        let colors = ["blue", "green", "orange", "red", "purple", "pink", "teal", "indigo"]

        return names.enumerated().map { index, entry in
            let score = max(28, 97 - index - Int.random(in: 0...3))
            let streak = max(1, 900 - (index * 9) - Int.random(in: 0...30))
            let color = colors[index % colors.count]
            return LeaderboardMember(
                id: "fake_\(index + 1)",
                name: entry.0,
                score: score,
                streakDays: streak,
                initials: entry.1,
                color: color,
                rank: index + 1
            )
        }
    }()
}
