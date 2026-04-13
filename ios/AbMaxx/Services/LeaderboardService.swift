import Foundation

nonisolated struct LeaderboardEntry: Codable, Sendable {
    let device_id: String
    let display_name: String
    let score: Int
    let streak_days: Int
    let avatar_color: String
    let updated_at: String?
}

nonisolated struct LeaderboardResponse: Codable, Sendable {
    let device_id: String
    let display_name: String
    let score: Int
    let streak_days: Int
    let avatar_color: String
    let updated_at: String?
    let created_at: String?
}

@MainActor
class LeaderboardService {
    static let shared = LeaderboardService()

    private var supabaseURL: String { Config.EXPO_PUBLIC_MY_SUPABASE_URL }
    private var supabaseKey: String { Config.EXPO_PUBLIC_MY_SUPABASE_ANON_KEY }

    private var isConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseKey.isEmpty
    }

    private let avatarColors = ["blue", "green", "orange", "red", "purple", "pink", "teal", "indigo"]

    func upsertEntry(deviceId: String, displayName: String, score: Int, streakDays: Int) async {
        guard isConfigured else { return }

        let color = avatarColors[abs(deviceId.hashValue) % avatarColors.count]

        let entry = LeaderboardEntry(
            device_id: deviceId,
            display_name: displayName.isEmpty ? "AbMaxx User" : displayName,
            score: max(score, 0),
            streak_days: max(streakDays, 0),
            avatar_color: color,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        guard let url = URL(string: "\(supabaseURL)/rest/v1/leaderboard") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        guard let body = try? JSONEncoder().encode(entry) else { return }
        request.httpBody = body

        _ = try? await URLSession.shared.data(for: request)
    }

    func fetchLeaderboard(limit: Int = 100) async -> [LeaderboardMember] {
        guard isConfigured else { return [] }
        guard let url = URL(string: "\(supabaseURL)/rest/v1/leaderboard?select=*&order=score.desc,streak_days.desc&limit=\(limit)") else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }

        guard let entries = try? JSONDecoder().decode([LeaderboardResponse].self, from: data) else {
            return []
        }

        return entries.enumerated().map { index, entry in
            let initials = Self.makeInitials(from: entry.display_name)
            return LeaderboardMember(
                id: entry.device_id,
                name: entry.display_name,
                score: entry.score,
                streakDays: entry.streak_days,
                initials: initials,
                color: entry.avatar_color,
                rank: index + 1
            )
        }
    }

    func fetchUserRank(deviceId: String) async -> Int? {
        guard isConfigured else { return nil }

        let userScore = await fetchUserScore(deviceId: deviceId)
        guard let score = userScore else { return nil }

        guard let url = URL(string: "\(supabaseURL)/rest/v1/leaderboard?select=device_id&score=gt.\(score)") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("count=exact", forHTTPHeaderField: "Prefer")

        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else {
            return nil
        }

        if let rangeHeader = http.value(forHTTPHeaderField: "Content-Range") {
            let parts = rangeHeader.split(separator: "/")
            if let totalStr = parts.last, let total = Int(totalStr) {
                return total + 1
            }
        }

        return nil
    }

    func fetchUserEntry(deviceId: String) async -> LeaderboardMember? {
        guard isConfigured else { return nil }
        let encodedId = deviceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceId
        guard let url = URL(string: "\(supabaseURL)/rest/v1/leaderboard?select=*&device_id=eq.\(encodedId)&limit=1") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        guard let entries = try? JSONDecoder().decode([LeaderboardResponse].self, from: data),
              let entry = entries.first else {
            return nil
        }

        let initials = Self.makeInitials(from: entry.display_name)
        return LeaderboardMember(
            id: entry.device_id,
            name: entry.display_name,
            score: entry.score,
            streakDays: entry.streak_days,
            initials: initials,
            color: entry.avatar_color,
            rank: 0
        )
    }

    private func fetchUserScore(deviceId: String) async -> Int? {
        guard isConfigured else { return nil }
        let encodedId = deviceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceId
        guard let url = URL(string: "\(supabaseURL)/rest/v1/leaderboard?select=score&device_id=eq.\(encodedId)&limit=1") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        guard let entries = try? JSONDecoder().decode([LeaderboardResponse].self, from: data),
              let first = entries.first else {
            return nil
        }

        return first.score
    }

    func fetchTotalCount() async -> Int {
        guard isConfigured else { return 0 }
        guard let url = URL(string: "\(supabaseURL)/rest/v1/leaderboard?select=device_id") else { return 0 }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("count=exact", forHTTPHeaderField: "Prefer")

        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else {
            return 0
        }

        if let rangeHeader = http.value(forHTTPHeaderField: "Content-Range") {
            let parts = rangeHeader.split(separator: "/")
            if let totalStr = parts.last, let total = Int(totalStr) {
                return total
            }
        }

        return 0
    }

    private static func makeInitials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
