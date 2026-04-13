import Foundation

nonisolated enum AnthropicError: LocalizedError, Sendable {
    case noAPIKey
    case httpError(status: Int, body: String)
    case invalidResponse
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API key not configured"
        case .httpError(let status, let body):
            return "API error \(status): \(body)"
        case .invalidResponse:
            return "Invalid response from API"
        case .emptyResponse:
            return "Empty response from API"
        }
    }
}

class AnthropicService {
    static let shared = AnthropicService()

    private var baseURL: String {
        let url = Config.EXPO_PUBLIC_TOOLKIT_URL
        if url.isEmpty { return "https://toolkit.rork.com" }
        return url
    }

    private var secretKey: String { Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY }

    func chat(
        systemPrompt: String,
        messages: [[String: String]],
        model: String = "claude-sonnet-4-20250514",
        maxTokens: Int = 1024,
        temperature: Double = 0.7
    ) async throws -> String {
        guard !secretKey.isEmpty else { throw AnthropicError.noAPIKey }

        let mappedModel = mapModel(model)

        var openAIMessages: [[String: Any]] = []
        if !systemPrompt.isEmpty {
            openAIMessages.append(["role": "system", "content": systemPrompt])
        }
        for msg in messages {
            openAIMessages.append([
                "role": msg["role"] ?? "user",
                "content": msg["content"] ?? ""
            ])
        }

        let body: [String: Any] = [
            "model": mappedModel,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "messages": openAIMessages
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
        guard !secretKey.isEmpty else { throw AnthropicError.noAPIKey }

        let mappedModel = mapModel(model)

        var openAIMessages: [[String: Any]] = []
        if !systemPrompt.isEmpty {
            openAIMessages.append(["role": "system", "content": systemPrompt])
        }
        openAIMessages.append([
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

        let body: [String: Any] = [
            "model": mappedModel,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "messages": openAIMessages
        ]

        let data = try await sendRequest(body: body)
        return try extractText(from: data)
    }

    private func mapModel(_ model: String) -> String {
        switch model {
        case "claude-sonnet-4-20250514", "claude-3-5-sonnet-20241022":
            return "anthropic/claude-sonnet-4.6"
        case "claude-3-haiku-20240307", "claude-3-5-haiku-20241022":
            return "anthropic/claude-haiku-4.5"
        default:
            if model.contains("/") { return model }
            return "anthropic/claude-sonnet-4.6"
        }
    }

    private func sendRequest(body: [String: Any]) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/v2/vercel/v1/chat/completions") else {
            throw AnthropicError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
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
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any] else {
            let raw = String(data: data, encoding: .utf8) ?? "empty"
            print("[AnthropicService] Could not parse response: \(raw.prefix(500))")
            throw AnthropicError.invalidResponse
        }

        if let text = message["content"] as? String, !text.isEmpty {
            return text
        }

        if let contentArray = message["content"] as? [[String: Any]] {
            for part in contentArray {
                if let type = part["type"] as? String, type == "text",
                   let text = part["text"] as? String, !text.isEmpty {
                    return text
                }
            }
        }

        throw AnthropicError.emptyResponse
    }
}
