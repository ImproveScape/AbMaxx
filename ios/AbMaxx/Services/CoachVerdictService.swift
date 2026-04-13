import Foundation

@MainActor
class CoachVerdictService {
    static let shared = CoachVerdictService()

    func sendMessage(messages: [CoachMessage], userContext: String) async throws -> String {
        let systemPrompt = """
        You are Coach Verdict — the user's personal abs and fitness coach inside the AbMaxx app. \
        You know EVERYTHING about their body, their scores, their weak zones, their nutrition, their progress. \
        You speak simple, direct, and motivating. You sound like a smart trainer who actually cares. \
        Keep it real — no fluff, no generic advice. Every answer is personalized to THEIR data. \
        Keep responses 2-4 sentences unless they ask for detail. \
        Use their actual numbers when giving advice. Be confident. Be specific. \
        If they ask about weak zones, reference their actual scores. \
        If they ask about nutrition, use their actual calorie/macro targets. \
        Never say "I don't have access to your data" — you DO have it all below.\n\n\
        --- USER PROFILE & BODY DATA ---\n\(userContext)
        """

        var apiMessages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]

        for msg in messages {
            apiMessages.append(["role": msg.isUser ? "user" : "assistant", "content": msg.text])
        }

        let response = try await RorkAI.shared.chat(
            model: "anthropic/claude-opus-4.5",
            messages: apiMessages,
            options: ["temperature": 0.7, "max_tokens": 512]
        )

        let choices = response["choices"] as? [[String: Any]]
        let text = (choices?.first?["message"] as? [String: Any])?["content"] as? String ?? ""

        if text.isEmpty {
            throw CoachError.emptyResponse
        }

        return text
    }
}
