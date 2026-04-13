import Foundation

nonisolated struct BodyFatEntry: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var date: Date = Date()
    var estimatedBodyFat: Double

    static func estimateBodyFat(gender: Gender, waistInches: Double, weightLbs: Double, heightInches: Double) -> Double {
        switch gender {
        case .male:
            let bf = 86.010 * log10(waistInches) - 70.041 * log10(heightInches) + 36.76
            return max(5, min(45, bf))
        case .female:
            let bf = 163.205 * log10(waistInches) - 97.684 * log10(heightInches) - 78.387
            return max(10, min(50, bf))
        }
    }

    static func estimateFromScan(overallScore: Int, gender: Gender, bodyFatCategory: BodyFatCategory) -> Double {
        let baseRange: (low: Double, high: Double)
        switch bodyFatCategory {
        case .lean: baseRange = (8, 14)
        case .athletic: baseRange = (12, 20)
        case .average: baseRange = (18, 28)
        case .aboveAverage: baseRange = (25, 38)
        }
        let scoreNormalized = Double(max(55, min(99, overallScore)) - 55) / 44.0
        let estimated = baseRange.high - (scoreNormalized * (baseRange.high - baseRange.low))
        if gender == .female {
            return estimated + 6
        }
        return estimated
    }
}
