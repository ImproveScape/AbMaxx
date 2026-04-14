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

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let anthropicVersion = "2023-06-01"

    private var apiKey: String { Config.EXPO_PUBLIC_ANTHROPIC_API_KEY }

    func chat(
        systemPrompt: String,
        messages: [[String: String]],
        model: String = "claude-sonnet-4-20250514",
        maxTokens: Int = 1024,
        temperature: Double = 0.7
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw AnthropicError.noAPIKey }

        let anthropicMessages = messages.map { msg -> [String: Any] in
            return [
                "role": msg["role"] ?? "user",
                "content": msg["content"] ?? ""
            ]
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "system": systemPrompt,
            "messages": anthropicMessages
        ]

        let data = try await sendRequest(body: body)
        return try extractText(from: data)
    }

    func chatWithVision(
        systemPrompt: String,
        userText: String,
        imageBase64: String,
        model: String = "claude-sonnet-4-20250514",
        maxTokens: Int = 1024,
        temperature: Double = 0.3
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw AnthropicError.noAPIKey }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": imageBase64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": userText
                        ]
                    ]
                ]
            ]
        ]

        let data = try await sendRequest(body: body)
        return try extractText(from: data)
    }

    private func sendRequest(body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 120
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AnthropicError.invalidResponse
        }

        if http.statusCode >= 400 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[AnthropicService] API error \(http.statusCode): \(errorBody)")
            throw AnthropicError.httpError(status: http.statusCode, body: errorBody)
        }

        return data
    }

    private func extractText(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            let raw = String(data: data, encoding: .utf8) ?? "empty"
            print("[AnthropicService] Could not parse response: \(raw.prefix(500))")
            throw AnthropicError.invalidResponse
        }

        guard !text.isEmpty else {
            throw AnthropicError.emptyResponse
        }

        return text
    }
}
