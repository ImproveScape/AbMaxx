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

    func analyzeFoodImage(_ image: UIImage) async -> FoodScanResponse? {
        guard let base64 = imageToBase64(image) else { return nil }

        let systemPrompt = """
        You are a nutrition analysis AI. Analyze the food in the image and estimate its nutritional content. \
        Return ONLY a raw JSON object with these fields, no markdown, no code fences: \
        {"name": "food name", "calories": number, "protein": number, "carbs": number, "fat": number, "fiber": number, "sugar": number} \
        All numbers should be per serving shown in the image. Be as accurate as possible. \
        If you cannot clearly identify food, still provide your best estimate based on what you see. \
        Always return valid JSON. Never wrap in markdown code blocks.
        """

        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": [
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]],
                ["type": "text", "text": "Analyze this food and estimate the nutritional content. Return only raw JSON, no markdown."]
            ]]
        ]

        for attempt in 1...2 {
            do {
                let text = try await OpenAIService.shared.chat(
                    model: "gpt-4o",
                    messages: messages,
                    temperature: 0.3,
                    maxTokens: 1024
                )
                if let result = parseResponse(text) {
                    return result
                }
            } catch {
                if attempt == 2 { return nil }
            }
        }
        return nil
    }

    private func parseResponse(_ text: String) -> FoodScanResponse? {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
        jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = jsonString.range(of: "{"), let end = jsonString.range(of: "}", options: .backwards) {
            jsonString = String(jsonString[start.lowerBound...end.lowerBound])
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
        let maxDimension: CGFloat = 1024
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resizedImage.jpegData(compressionQuality: 0.8)?.base64EncodedString()
    }
}
