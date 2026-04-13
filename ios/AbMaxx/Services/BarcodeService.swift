import Foundation

nonisolated struct OpenFoodFactsProduct: Sendable {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let imageURL: String?
}

nonisolated struct OFFResponse: Codable, Sendable {
    let status: Int?
    let product: OFFProduct?
}

nonisolated struct OFFProduct: Codable, Sendable {
    let product_name: String?
    let nutriments: OFFNutriments?
    let image_front_url: String?
    let image_url: String?
}

nonisolated struct OFFNutriments: Codable, Sendable {
    let energy_kcal_100g: Double?
    let proteins_100g: Double?
    let carbohydrates_100g: Double?
    let fat_100g: Double?
    let fiber_100g: Double?
    let sugars_100g: Double?
    let sodium_100g: Double?

    private enum CodingKeys: String, CodingKey {
        case energy_kcal_100g = "energy-kcal_100g"
        case proteins_100g = "proteins_100g"
        case carbohydrates_100g = "carbohydrates_100g"
        case fat_100g = "fat_100g"
        case fiber_100g = "fiber_100g"
        case sugars_100g = "sugars_100g"
        case sodium_100g = "sodium_100g"
    }
}

@MainActor
class BarcodeService {
    static let shared = BarcodeService()

    func lookupBarcode(_ barcode: String) async -> OpenFoodFactsProduct? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("AbMaxx iOS App", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let offResponse = try JSONDecoder().decode(OFFResponse.self, from: data)

            guard let status = offResponse.status, status == 1,
                  let product = offResponse.product,
                  let name = product.product_name, !name.isEmpty else {
                return nil
            }

            let n = product.nutriments
            return OpenFoodFactsProduct(
                name: name,
                calories: Int(n?.energy_kcal_100g ?? 0),
                protein: n?.proteins_100g ?? 0,
                carbs: n?.carbohydrates_100g ?? 0,
                fat: n?.fat_100g ?? 0,
                fiber: n?.fiber_100g ?? 0,
                sugar: n?.sugars_100g ?? 0,
                sodium: (n?.sodium_100g ?? 0) * 1000,
                imageURL: product.image_front_url ?? product.image_url
            )
        } catch {
            return nil
        }
    }
}
