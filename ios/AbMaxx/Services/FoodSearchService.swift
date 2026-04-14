import Foundation

nonisolated struct FoodSearchResult: Identifiable, Sendable {
    let id: String
    let name: String
    let emoji: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let servingSize: String
    let servingGrams: Double
}

class FoodSearchService {
    static let shared = FoodSearchService()

    func searchFood(_ query: String) async -> [FoodSearchResult] {
        let prompt = """
        You are a nutrition database. The user searched for: "\(query)"
        Return a JSON array of 5-8 common food items matching this search. For each item include:
        [{"name":"food name","emoji":"single emoji","calories":number,"protein":number,"carbs":number,"fat":number,"fiber":number,"sugar":number,"serving_size":"description like 1 cup or 100g","serving_grams":number}]
        Be accurate with real nutritional data. Include different serving sizes/variations when relevant (e.g. "Chicken Breast (6oz)" and "Chicken Breast (4oz)"). Return ONLY the JSON array, nothing else.
        """

        do {
            let text = try await OpenAIService.shared.chat(
                model: "gpt-4o",
                messages: [["role": "user", "content": prompt]],
                temperature: 0.3
            )
            return parseResults(text)
        } catch {
            return []
        }
    }

    private func parseResults(_ text: String) -> [FoodSearchResult] {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = jsonString.firstIndex(of: "["),
           let end = jsonString.lastIndex(of: "]") {
            jsonString = String(jsonString[start...end])
        }

        guard let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return array.enumerated().compactMap { index, item in
            guard let name = item["name"] as? String else { return nil }

            let calories: Int
            if let c = item["calories"] as? Int { calories = c }
            else if let c = item["calories"] as? Double { calories = Int(c) }
            else { calories = 0 }

            let protein = (item["protein"] as? Double) ?? (item["protein"] as? Int).map(Double.init) ?? 0
            let carbs = (item["carbs"] as? Double) ?? (item["carbs"] as? Int).map(Double.init) ?? 0
            let fat = (item["fat"] as? Double) ?? (item["fat"] as? Int).map(Double.init) ?? 0
            let fiber = (item["fiber"] as? Double) ?? (item["fiber"] as? Int).map(Double.init) ?? 0
            let sugar = (item["sugar"] as? Double) ?? (item["sugar"] as? Int).map(Double.init) ?? 0
            let emoji = item["emoji"] as? String ?? "🍽️"
            let servingSize = item["serving_size"] as? String ?? "1 serving"
            let servingGrams: Double
            if let g = item["serving_grams"] as? Double { servingGrams = g }
            else if let g = item["serving_grams"] as? Int { servingGrams = Double(g) }
            else { servingGrams = 100 }

            return FoodSearchResult(
                id: "\(name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(index)",
                name: name,
                emoji: emoji,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sugar: sugar,
                servingSize: servingSize,
                servingGrams: servingGrams
            )
        }
    }
}
