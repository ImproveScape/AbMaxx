import Foundation

nonisolated enum OpenAIError: LocalizedError, Sendable {
    case noAPIKey
    case httpError(status: Int, body: String)
    case invalidResponse
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "OpenAI API key not configured"
        case .httpError(let status, let body): return "OpenAI API error \(status): \(body)"
        case .invalidResponse: return "Invalid response from OpenAI API"
        case .emptyResponse: return "Empty response from OpenAI API"
        }
    }
}

class OpenAIService {
    static let shared = OpenAIService()

    private let baseURL = "https://api.openai.com/v1"
    private var apiKey: String { Config.EXPO_PUBLIC_OPENAI_API_KEY }

    func chat(
        model: String = "gpt-4o",
        messages: [[String: Any]],
        temperature: Double = 0.7,
        maxTokens: Int = 1024,
        timeout: TimeInterval = 60
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw OpenAIError.noAPIKey }

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": maxTokens
        ]

        let url = URL(string: "\(baseURL)/chat/completions")!
        let data = try await sendRequest(url: url, body: body, timeout: timeout)
        return try extractChatText(from: data)
    }

    func transcribe(audioData: Data, filename: String, model: String = "gpt-4o-mini-transcribe") async throws -> String {
        guard !apiKey.isEmpty else { throw OpenAIError.noAPIKey }

        let url = URL(string: "\(baseURL)/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let ext = filename.split(separator: ".").last ?? "wav"
        var body = Data()
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\nContent-Type: audio/\(ext)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"model\"\r\n\r\n\(model)\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OpenAIError.invalidResponse }
        if http.statusCode >= 400 {
            throw OpenAIError.httpError(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["text"] as? String ?? ""
    }

    func editImage(imageData: Data, prompt: String, model: String = "gpt-image-1", size: String = "1024x1536") async throws -> String {
        guard !apiKey.isEmpty else { throw OpenAIError.noAPIKey }

        let url = URL(string: "\(baseURL)/images/edits")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\nContent-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"prompt\"\r\n\r\n\(prompt)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"model\"\r\n\r\n\(model)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"size\"\r\n\r\n\(size)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"response_format\"\r\n\r\nb64_json\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OpenAIError.invalidResponse }
        if http.statusCode >= 400 {
            throw OpenAIError.httpError(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["data"] as? [[String: Any]]
        return items?.first?["b64_json"] as? String ?? ""
    }

    private func sendRequest(url: URL, body: [String: Any], timeout: TimeInterval = 60) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OpenAIError.invalidResponse }
        if http.statusCode >= 400 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[OpenAIService] API error \(http.statusCode): \(errorBody)")
            throw OpenAIError.httpError(status: http.statusCode, body: errorBody)
        }
        return data
    }

    private func extractChatText(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            let raw = String(data: data, encoding: .utf8) ?? "empty"
            print("[OpenAIService] Could not parse response: \(raw.prefix(500))")
            throw OpenAIError.invalidResponse
        }
        guard !content.isEmpty else { throw OpenAIError.emptyResponse }
        return content
    }
}
