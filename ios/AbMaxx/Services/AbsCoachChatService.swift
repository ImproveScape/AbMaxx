import Foundation

@MainActor
class AbsCoachChatService {
    static let shared = AbsCoachChatService()

    func sendMessage(messages: [CoachMessage], userContext: String) async throws -> String {
        let systemPrompt = """
        You are Coach Maxx — the user's personal abs coach inside the AbMaxx app. You talk like a real personal trainer, not a robot. Friendly, motivating, and straight to the point. \
        Use proper punctuation — capitalize the first letter of every sentence, use periods and commas normally. Write like a real person texting their client, not like a chatbot. \
        Keep it simple and easy to understand. Short sentences. No jargon. No bullet points or numbered lists. \
        You know EVERYTHING about them: stats, scan scores, workout history, nutrition, streaks, goals, progress. \
        Use their name sometimes but don't overdo it. Be direct, supportive, and real. If they're slacking, give them tough love. If they're doing great, hype them up genuinely. \
        Keep responses concise (2-4 sentences) unless they ask for detail. \
        Reference their actual numbers when relevant — don't be vague when you have data. \
        Never make up data you don't have. Never use emojis excessively — one max if it fits naturally. \
        Never introduce yourself or say "I'm Coach Maxx" mid-conversation — they already know who you are.\n\n\
        USER DATA:\n\(userContext)
        """

        var apiMessages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]

        for msg in messages {
            apiMessages.append(["role": msg.isUser ? "user" : "assistant", "content": msg.text])
        }

        let response = try await RorkAI.shared.chat(
            model: "anthropic/claude-sonnet-4.6",
            messages: apiMessages,
            options: ["temperature": 0.75, "max_tokens": 400],
            timeout: 90
        )

        let choices = response["choices"] as? [[String: Any]]
        let text = (choices?.first?["message"] as? [String: Any])?["content"] as? String ?? ""

        if text.isEmpty {
            throw CoachError.emptyResponse
        }

        return text
    }
}
