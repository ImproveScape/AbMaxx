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

        var apiMessages: [[String: String]] = []
        for msg in messages {
            apiMessages.append(["role": msg.isUser ? "user" : "assistant", "content": msg.text])
        }

        let text = try await AnthropicService.shared.chat(
            systemPrompt: systemPrompt,
            messages: apiMessages,
            model: "claude-sonnet-4-20250514",
            maxTokens: 512,
            temperature: 0.7
        )

        if text.isEmpty {
            throw CoachError.emptyResponse
        }

        return text
    }
}
