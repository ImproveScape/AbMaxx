import Foundation
import UIKit

@Observable
@MainActor
class NutritionService {
    var searchResults: [NutritionLookupResult] = []
    var errorMessage: String?

    private var baseURL: String {
        let url = Config.EXPO_PUBLIC_TOOLKIT_URL
        if url.isEmpty { return "https://toolkit.rork.com" }
        return url
    }

    private var secretKey: String { Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY }

    func searchFood(_ query: String) async {
        searchResults = []
        errorMessage = nil

        let prompt = """
        You are a nutrition database. The user searched for: "\(query)"
        Return a JSON array of 5-8 food items matching this search. For each item:
        [{"name":"food name","calories":number,"protein":number,"carbs":number,"fat":number,"serving_size":"description"}]
        Be accurate with real USDA nutritional data. Return ONLY the JSON array.
        """

        do {
            let text = try await AnthropicService.shared.chat(
                systemPrompt: "",
                messages: [["role": "user", "content": prompt]],
                model: "claude-sonnet-4-20250514",
                maxTokens: 2048,
                temperature: 0.3
            )
            searchResults = parseSearchResults(text)
            if searchResults.isEmpty {
                errorMessage = "No results found. Try a different search."
            }
        } catch {
            errorMessage = "Search failed. Please try again."
        }
    }

    func analyzeFoodImage(_ imageData: Data) async -> [NutritionLookupResult] {
        errorMessage = nil
        guard let base64 = imageToBase64(imageData) else {
            errorMessage = "Could not process image."
            return []
        }

        let systemPrompt = """
        You are a nutrition analysis AI. Analyze the food in the image and estimate nutritional content. \
        Return ONLY a JSON array of food items found: \
        [{"name":"food name","calories":number,"protein":number,"carbs":number,"fat":number,"serving_size":"description"}] \
        If multiple items visible, list each separately. Be accurate with real USDA nutritional data. \
        If you cannot identify food, return [{"name":"Unknown Food","calories":200,"protein":10,"carbs":25,"fat":8,"serving_size":"1 serving"}]
        """

        do {
            let text = try await AnthropicService.shared.chatWithVision(
                systemPrompt: systemPrompt,
                userText: "Analyze this food and estimate nutrition. Return only JSON array.",
                imageBase64: base64,
                model: "claude-sonnet-4-20250514",
                maxTokens: 1024,
                temperature: 0.3
            )
            let results = parseSearchResults(text)
            if results.isEmpty {
                errorMessage = "Could not identify food items."
            }
            return results
        } catch {
            errorMessage = "Analysis failed. Please try again."
            return []
        }
    }

    func lookupBarcode(_ barcode: String) async -> NutritionLookupResult? {
        errorMessage = nil
        if let product = await BarcodeService.shared.lookupBarcode(barcode) {
            return NutritionLookupResult(
                name: product.name,
                calories: product.calories,
                protein: product.protein,
                carbs: product.carbs,
                fat: product.fat,
                servingSize: "per 100g"
            )
        }

        errorMessage = "Product not found. Try a different barcode."
        return nil
    }

    func enrichFoodEntry(name: String, calories: Int, protein: Double, carbs: Double, fat: Double, servingSize: String) async -> EnrichedFoodData? {
        let prompt = """
        For this food item: "\(name)" (\(calories) cal, \(protein)g protein, \(carbs)g carbs, \(fat)g fat, serving: \(servingSize))
        Estimate detailed nutrition and health score. Return ONLY JSON:
        {"health_score":0-100,"health_label":"Excellent/Good/Fair/Poor","health_description":"brief description",
        "fiber":number,"sugar":number,"sodium":number,"potassium":number,"cholesterol":number,
        "vitamin_a":number,"vitamin_c":number,"calcium":number,"iron":number,
        "vitamin_d":number,"magnesium":number,"zinc":number}
        All values per serving. Be accurate based on USDA data.
        """

        do {
            let text = try await AnthropicService.shared.chat(
                systemPrompt: "",
                messages: [["role": "user", "content": prompt]],
                model: "claude-sonnet-4-20250514",
                maxTokens: 1024,
                temperature: 0.2
            )
            return parseEnrichedData(text)
        } catch {
            return nil
        }
    }

    private func parseSearchResults(_ text: String) -> [NutritionLookupResult] {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = jsonString.firstIndex(of: "["), let end = jsonString.lastIndex(of: "]") {
            jsonString = String(jsonString[start...end])
        } else if let start = jsonString.firstIndex(of: "{"), let end = jsonString.lastIndex(of: "}") {
            jsonString = "[\(String(jsonString[start...end]))]"
        }

        guard let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return array.compactMap { item in
            guard let name = item["name"] as? String else { return nil }
            let calories: Int
            if let c = item["calories"] as? Int { calories = c }
            else if let c = item["calories"] as? Double { calories = Int(c) }
            else { calories = 0 }

            let protein = (item["protein"] as? Double) ?? (item["protein"] as? Int).map(Double.init) ?? 0
            let carbs = (item["carbs"] as? Double) ?? (item["carbs"] as? Int).map(Double.init) ?? 0
            let fat = (item["fat"] as? Double) ?? (item["fat"] as? Int).map(Double.init) ?? 0
            let serving = item["serving_size"] as? String ?? "1 serving"

            return NutritionLookupResult(name: name, calories: calories, protein: protein, carbs: carbs, fat: fat, servingSize: serving)
        }
    }

    private func parseEnrichedData(_ text: String) -> EnrichedFoodData? {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = jsonString.range(of: "{"), let end = jsonString.range(of: "}", options: .backwards) {
            jsonString = String(jsonString[start.lowerBound...end.upperBound])
        }
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        func d(_ key: String) -> Double { (json[key] as? Double) ?? (json[key] as? Int).map(Double.init) ?? 0 }

        let score: Int
        if let s = json["health_score"] as? Int { score = s }
        else if let s = json["health_score"] as? Double { score = Int(s) }
        else { score = 50 }

        return EnrichedFoodData(
            healthScore: score,
            healthLabel: json["health_label"] as? String ?? "Good",
            healthDescription: json["health_description"] as? String ?? "",
            fiber: d("fiber"), sugar: d("sugar"), sodium: d("sodium"),
            potassium: d("potassium"), cholesterol: d("cholesterol"),
            vitaminA: d("vitamin_a"), vitaminC: d("vitamin_c"),
            calcium: d("calcium"), iron: d("iron"),
            vitaminD: d("vitamin_d"), vitaminE: d("vitamin_e"), vitaminK: d("vitamin_k"),
            vitaminB6: d("vitamin_b6"), vitaminB12: d("vitamin_b12"), folate: d("folate"),
            magnesium: d("magnesium"), zinc: d("zinc"), phosphorus: d("phosphorus"),
            thiamin: d("thiamin"), riboflavin: d("riboflavin"), niacin: d("niacin"),
            manganese: d("manganese"), selenium: d("selenium"), copper: d("copper")
        )
    }


    private func extractContentText(from response: [String: Any]) -> String {
        let choices = response["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        if let text = message?["content"] as? String {
            return text
        }
        if let contentArray = message?["content"] as? [[String: Any]] {
            for part in contentArray {
                if let type = part["type"] as? String, type == "text",
                   let text = part["text"] as? String {
                    return text
                }
            }
        }
        return ""
    }

    private func imageToBase64(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
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
