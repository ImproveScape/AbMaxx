import Foundation

nonisolated enum RorkAPIError: LocalizedError, Sendable {
    case httpError(status: Int, body: String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .httpError(let status, let body):
            return "Rork API error \(status): \(body)"
        case .invalidResponse:
            return "Invalid response from Rork API"
        }
    }
}

actor RorkAI {
    @MainActor static let shared = RorkAI()

    private let _baseURL: URL
    private let _secretKey: String
    private let _anthropicAPIKey: String

    private var baseURL: URL { _baseURL }
    private var secretKey: String { _secretKey }
    private var anthropicAPIKey: String { _anthropicAPIKey }

    @MainActor
    init() {
        _baseURL = URL(string: Config.EXPO_PUBLIC_TOOLKIT_URL) ?? URL(string: "https://placeholder")!
        _secretKey = Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY
        _anthropicAPIKey = Config.EXPO_PUBLIC_ANTHROPIC_API_KEY
    }

    private func request(_ path: String, body: [String: Any], timeout: TimeInterval = 60) async throws -> Data {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = timeout
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw RorkAPIError.invalidResponse
        }
        if http.statusCode >= 400 {
            throw RorkAPIError.httpError(
                status: http.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }
        return data
    }

    private func providerOptions(for model: String, existing: [String: Any]?) -> [String: Any]? {
        guard model.hasPrefix("anthropic/"), !anthropicAPIKey.isEmpty else {
            return existing
        }

        var providerOptions: [String: Any] = existing ?? [:]
        var gatewayOptions: [String: Any] = providerOptions["gateway"] as? [String: Any] ?? [:]
        var byokOptions: [String: Any] = gatewayOptions["byok"] as? [String: Any] ?? [:]

        byokOptions["anthropic"] = [["apiKey": anthropicAPIKey]]
        gatewayOptions["byok"] = byokOptions
        gatewayOptions["only"] = ["anthropic"]
        providerOptions["gateway"] = gatewayOptions

        return providerOptions
    }

    func chat(model: String, messages: [[String: Any]], options: [String: Any] = [:], timeout: TimeInterval = 60) async throws -> [String: Any] {
        var body: [String: Any] = [
            "model": model,
            "messages": messages,
        ]
        for (key, value) in options where key != "providerOptions" {
            body[key] = value
        }
        if let providerOptions = providerOptions(for: model, existing: options["providerOptions"] as? [String: Any]) {
            body["providerOptions"] = providerOptions
        }
        let data = try await request("/v2/vercel/chat/completions", body: body, timeout: timeout)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    func generateImage(prompt: String, model: String = "openai/gpt-image-1", size: String = "1024x1024", options: [String: Any] = [:]) async throws -> String {
        var body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "n": 1,
            "size": size,
            "response_format": "b64_json",
        ]
        for (key, value) in options { body[key] = value }
        let data = try await request("/v2/vercel/images/generations", body: body)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["data"] as? [[String: Any]]
        return items?.first?["b64_json"] as? String ?? ""
    }

    func embed(input: String, model: String = "openai/text-embedding-3-small", options: [String: Any] = [:]) async throws -> [Double] {
        var body: [String: Any] = [
            "model": model,
            "input": input,
        ]
        for (key, value) in options { body[key] = value }
        let data = try await request("/v2/vercel/embeddings", body: body)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["data"] as? [[String: Any]]
        return items?.first?["embedding"] as? [Double] ?? []
    }

    func editImage(imageData: Data, prompt: String, model: String = "gpt-image-1", size: String = "1024x1536") async throws -> String {
        let url = baseURL.appendingPathComponent("/v2/openai/v1/images/edits")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 120

        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\nContent-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"prompt\"\r\n\r\n\(prompt)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"model\"\r\n\r\n\(model)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"size\"\r\n\r\n\(size)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"response_format\"\r\n\r\nb64_json\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw RorkAPIError.invalidResponse
        }
        if http.statusCode >= 400 {
            throw RorkAPIError.httpError(
                status: http.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["data"] as? [[String: Any]]
        return items?.first?["b64_json"] as? String ?? ""
    }

    func transcribe(audioData: Data, filename: String, model: String = "gpt-4o-mini-transcribe") async throws -> String {
        let url = baseURL.appendingPathComponent("/v2/openai/v1/audio/transcriptions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\nContent-Type: audio/\(filename.split(separator: ".").last ?? "wav")\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"model\"\r\n\r\n\(model)\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw RorkAPIError.invalidResponse
        }
        if http.statusCode >= 400 {
            throw RorkAPIError.httpError(
                status: http.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["text"] as? String ?? ""
    }
}
