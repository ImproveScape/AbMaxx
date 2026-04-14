import Foundation

nonisolated enum AnthropicError: LocalizedError, Sendable {
    case noAPIKey
    case httpError(status: Int, body: String)
    case invalidResponse
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Anthropic API key not configured"
        case .httpError(let status, let body):
            return "Anthropic API error \(status): \(body)"
        case .invalidResponse:
            return "Invalid response from Anthropic API"
        case .emptyResponse:
            return "Empty response from Anthropic API"
        }
    }
}

class AnthropicService {
    static let shared = AnthropicService()

    private func prefixedModel(_ model: String) -> String {
        if model.contains("/") { return model }
        return "anthropic/\(model)"
    }

    private func extractText(from response: [String: Any]) throws -> String {
        if let choices = response["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let text = message["content"] as? String, !text.isEmpty {
            return text
        }
        throw AnthropicError.invalidResponse
    }

    func chat(
        systemPrompt: String,
        messages: [[String: String]],
        model: String = "claude-sonnet-4-20250514",
        maxTokens: Int = 1024,
        temperature: Double = 0.7
    ) async throws -> String {
        var apiMessages: [[String: Any]] = []

        if !systemPrompt.isEmpty {
            apiMessages.append(["role": "system", "content": systemPrompt])
        }

        for msg in messages {
            apiMessages.append([
                "role": msg["role"] ?? "user",
                "content": msg["content"] ?? ""
            ])
        }

        let response = try await RorkAI.shared.chat(
            model: prefixedModel(model),
            messages: apiMessages,
            options: ["max_tokens": maxTokens, "temperature": temperature],
            timeout: 120
        )

        let text = try extractText(from: response)
        guard !text.isEmpty else { throw AnthropicError.emptyResponse }
        return text
    }

    func chatWithVision(
        systemPrompt: String,
        userText: String,
        imageBase64: String,
        model: String = "claude-sonnet-4-20250514",
        maxTokens: Int = 1024,
        temperature: Double = 0.3
    ) async throws -> String {
        var apiMessages: [[String: Any]] = []

        if !systemPrompt.isEmpty {
            apiMessages.append(["role": "system", "content": systemPrompt])
        }

        apiMessages.append([
            "role": "user",
            "content": [
                [
                    "type": "image_url",
                    "image_url": ["url": "data:image/jpeg;base64,\(imageBase64)"]
                ],
                [
                    "type": "text",
                    "text": userText
                ]
            ]
        ])

        let response = try await RorkAI.shared.chat(
            model: prefixedModel(model),
            messages: apiMessages,
            options: ["max_tokens": maxTokens, "temperature": temperature],
            timeout: 120
        )

        let text = try extractText(from: response)
        guard !text.isEmpty else { throw AnthropicError.emptyResponse }
        return text
    }
}
