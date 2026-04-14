import Foundation

@MainActor
class CoachAbsService {
    static let shared = CoachAbsService()

    func sendMessage(messages: [CoachMessage], scanContext: String) async throws -> String {
        let systemPrompt = """
        You are Coach Abs, an expert personal fitness coach specializing in ab development and core training. \
        You are direct, motivating, and knowledgeable. Keep responses concise (2-4 sentences max unless asked for detail). \
        Use the user's scan data to personalize advice. Here is their current data:\n\(scanContext)
        """

        var apiMessages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]

        for msg in messages {
            apiMessages.append(["role": msg.isUser ? "user" : "assistant", "content": msg.text])
        }

        let text = try await OpenAIService.shared.chat(
            model: "gpt-4o",
            messages: apiMessages,
            temperature: 0.7,
            maxTokens: 512
        )

        if text.isEmpty {
            throw CoachError.emptyResponse
        }

        return text
    }
}

nonisolated enum CoachError: Error, Sendable {
    case serverError
    case emptyResponse
}

nonisolated struct CoachMessage: Identifiable, Sendable {
    let id: UUID
    let text: String
    let isUser: Bool
    let date: Date

    init(id: UUID = UUID(), text: String, isUser: Bool, date: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.date = date
    }
}
