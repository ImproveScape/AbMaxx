import Foundation
import UIKit

nonisolated struct FoodScanResponse: Codable, Sendable {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
}

@MainActor
class FoodScanService {
    static let shared = FoodScanService()

    private var baseURL: String {
        let url = Config.EXPO_PUBLIC_TOOLKIT_URL
        if url.isEmpty { return "https://toolkit.rork.com" }
        return url
    }

    private var secretKey: String { Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY }

    func analyzeFoodImage(_ image: UIImage) async -> FoodScanResponse? {
        guard let base64 = imageToBase64(image) else { return nil }

        let systemPrompt = """
        You are a nutrition analysis AI. Analyze the food in the image and estimate its nutritional content. \
        Return ONLY a JSON object with these fields, nothing else: \
        {"name": "food name", "calories": number, "protein": number, "carbs": number, "fat": number, "fiber": number, "sugar": number} \
        All numbers should be per serving shown in the image. Be as accurate as possible. \
        If you cannot identify food, return {"name": "Unknown Food", "calories": 200, "protein": 10, "carbs": 25, "fat": 8, "fiber": 2, "sugar": 5}
        """

        do {
            let text = try await chatCompletion(
                messages: [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": [
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]],
                        ["type": "text", "text": "Analyze this food and estimate the nutritional content. Return only JSON."]
                    ]]
                ]
            )
            return parseResponse(text)
        } catch {
            return nil
        }
    }

    private func chatCompletion(messages: [[String: Any]]) async throws -> String {
        guard let url = URL(string: "\(baseURL)/v2/vercel/v1/chat/completions") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "model": "anthropic/claude-sonnet-4.6",
            "messages": messages,
            "max_tokens": 1024,
            "temperature": 0.3
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        return message?["content"] as? String ?? ""
    }

    private func parseResponse(_ text: String) -> FoodScanResponse? {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = jsonString.range(of: "{"), let end = jsonString.range(of: "}", options: .backwards) {
            jsonString = String(jsonString[start.lowerBound...end.upperBound])
        }

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let name = json["name"] as? String ?? "Scanned Food"

        let calories: Int
        if let c = json["calories"] as? Int { calories = c }
        else if let c = json["calories"] as? Double { calories = Int(c) }
        else { calories = 200 }

        let protein = (json["protein"] as? Double) ?? (json["protein"] as? Int).map(Double.init) ?? 0
        let carbs = (json["carbs"] as? Double) ?? (json["carbs"] as? Int).map(Double.init) ?? 0
        let fat = (json["fat"] as? Double) ?? (json["fat"] as? Int).map(Double.init) ?? 0
        let fiber = (json["fiber"] as? Double) ?? (json["fiber"] as? Int).map(Double.init) ?? 0
        let sugar = (json["sugar"] as? Double) ?? (json["sugar"] as? Int).map(Double.init) ?? 0

        return FoodScanResponse(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar
        )
    }

    private func imageToBase64(_ image: UIImage) -> String? {
        let maxDimension: CGFloat = 512
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized?.jpegData(compressionQuality: 0.7)?.base64EncodedString()
    }
}
