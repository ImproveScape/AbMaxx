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
        Return a JSON array of 5-8 food items matching this search. For each item include ALL macros AND micronutrients:
        [{"name":"food name","calories":number,"protein":number,"carbs":number,"fat":number,"serving_size":"description","fiber":number,"sugar":number,"sodium":number,"potassium":number,"cholesterol":number,"vitamin_a":number,"vitamin_c":number,"calcium":number,"iron":number,"vitamin_d":number,"vitamin_e":number,"vitamin_k":number,"vitamin_b6":number,"vitamin_b12":number,"folate":number,"magnesium":number,"zinc":number,"phosphorus":number,"thiamin":number,"riboflavin":number,"niacin":number,"manganese":number,"selenium":number,"copper":number}]
        Units per serving: fiber/sugar in g, sodium/potassium/calcium/iron/magnesium/zinc/phosphorus in mg, vitamin_a in mcg RAE, vitamin_c in mg, vitamin_d in mcg, vitamin_e in mg, vitamin_k in mcg, vitamin_b6 in mg, vitamin_b12 in mcg, folate in mcg DFE, thiamin/riboflavin/niacin in mg, manganese in mg, selenium in mcg, copper in mg.
        Be accurate with real USDA nutritional data. Return ONLY the JSON array.
        """

        do {
            let response = try await RorkAI.shared.chat(
                model: "anthropic/claude-sonnet-4.6",
                messages: [["role": "user", "content": prompt]],
                options: ["temperature": 0.3]
            )

            let choices = response["choices"] as? [[String: Any]]
            let text = (choices?.first?["message"] as? [String: Any])?["content"] as? String ?? ""
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
            errorMessage = "Could not process image. Please try a different photo."
            return []
        }

        let systemPrompt = """
        You are a nutrition analysis AI. First, determine if the image contains food or drinks. \
        If the image does NOT contain any food or drinks (e.g. it's a wall, person, object, scenery, text, etc.), \
        respond with exactly: {"no_food": true} \
        If the image DOES contain food or drinks, analyze and estimate nutritional content. \
        Return ONLY a raw JSON array of food items found (no markdown, no code fences): \
        [{"name":"food name","calories":number,"protein":number,"carbs":number,"fat":number,"serving_size":"description","fiber":number,"sugar":number,"sodium":number,"potassium":number,"cholesterol":number,"vitamin_a":number,"vitamin_c":number,"calcium":number,"iron":number,"vitamin_d":number,"vitamin_e":number,"vitamin_k":number,"vitamin_b6":number,"vitamin_b12":number,"folate":number,"magnesium":number,"zinc":number,"phosphorus":number,"thiamin":number,"riboflavin":number,"niacin":number,"manganese":number,"selenium":number,"copper":number}] \
        Units per serving: fiber/sugar in g, sodium/potassium/calcium/iron/magnesium/zinc/phosphorus in mg, vitamin_a in mcg RAE, vitamin_c in mg, vitamin_d in mcg, vitamin_e in mg, vitamin_k in mcg, vitamin_b6 in mg, vitamin_b12 in mcg, folate in mcg DFE, thiamin/riboflavin/niacin in mg, manganese in mg, selenium in mcg, copper in mg. \
        If multiple items visible, list each separately. Be accurate with real USDA nutritional data. \
        Always return valid JSON. Never wrap in markdown code blocks.
        """

        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": [
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]],
                ["type": "text", "text": "Analyze this food and estimate nutrition. Return only a raw JSON array, no markdown."]
            ]]
        ]

        for attempt in 1...2 {
            do {
                let response = try await RorkAI.shared.chat(
                    model: "anthropic/claude-sonnet-4.6",
                    messages: messages,
                    options: ["temperature": 0.3, "max_tokens": 1024]
                )

                let choices = response["choices"] as? [[String: Any]]
                let text = (choices?.first?["message"] as? [String: Any])?["content"] as? String ?? ""
                if isNoFoodResponse(text) {
                    errorMessage = "No food or drinks detected. Try a photo of your meal."
                    return []
                }
                let results = parseSearchResults(text)
                if !results.isEmpty {
                    return results
                }
                if attempt == 2 {
                    errorMessage = "Could not identify food items. Try a clearer photo."
                }
            } catch {
                if attempt == 2 {
                    errorMessage = "Analysis failed. Please try again."
                }
            }
        }
        return []
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
        "vitamin_d":number,"vitamin_e":number,"vitamin_k":number,"vitamin_b6":number,"vitamin_b12":number,
        "folate":number,"magnesium":number,"zinc":number,"phosphorus":number,
        "thiamin":number,"riboflavin":number,"niacin":number,"manganese":number,"selenium":number,"copper":number}
        Units: fiber/sugar g, sodium/potassium/calcium/iron/magnesium/zinc/phosphorus mg, vitamin_a mcg RAE, vitamin_c mg, vitamin_d mcg, vitamin_e mg, vitamin_k mcg, vitamin_b6 mg, vitamin_b12 mcg, folate mcg DFE, thiamin/riboflavin/niacin mg, manganese mg, selenium mcg, copper mg.
        Be accurate based on USDA data.
        """

        do {
            let response = try await RorkAI.shared.chat(
                model: "anthropic/claude-sonnet-4.6",
                messages: [["role": "user", "content": prompt]],
                options: ["temperature": 0.2]
            )

            let choices = response["choices"] as? [[String: Any]]
            let text = (choices?.first?["message"] as? [String: Any])?["content"] as? String ?? ""
            return parseEnrichedData(text)
        } catch {
            return nil
        }
    }

    func parseSearchResults(_ text: String) -> [NutritionLookupResult] {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
        jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
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

            func d(_ key: String) -> Double { (item[key] as? Double) ?? (item[key] as? Int).map(Double.init) ?? 0 }

            let protein = d("protein")
            let carbs = d("carbs")
            let fat = d("fat")
            let serving = item["serving_size"] as? String ?? "1 serving"

            return NutritionLookupResult(
                name: name, calories: calories, protein: protein, carbs: carbs, fat: fat, servingSize: serving,
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


    private func isNoFoodResponse(_ text: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = cleaned.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let noFood = json["no_food"] as? Bool, noFood {
            return true
        }
        return false
    }

    private func imageToBase64(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else {
            print("[NutritionService] ERROR: Could not create UIImage from data")
            return nil
        }
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        let qualities: [CGFloat] = [0.7, 0.5, 0.3]
        for quality in qualities {
            if let jpegData = resizedImage.jpegData(compressionQuality: quality) {
                if jpegData.count < 4_000_000 {
                    return jpegData.base64EncodedString()
                }
            }
        }
        return resizedImage.jpegData(compressionQuality: 0.2)?.base64EncodedString()
    }
}
