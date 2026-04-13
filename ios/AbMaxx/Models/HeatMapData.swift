import Foundation

nonisolated struct HeatMapZone: Codable, Sendable, Identifiable {
    var id: String { name }
    let name: String
    let centerX: Double
    let centerY: Double
    let width: Double
    let height: Double
    let definitionScore: Int
    let needsWork: Bool
    let note: String
}

nonisolated struct HeatMapAnalysis: Codable, Sendable {
    let zones: [HeatMapZone]
    let overallAssessment: String
    let strongestArea: String
    let weakestArea: String
    let technicalNotes: [String]
}

nonisolated struct HeatMapAIResponse: Codable, Sendable {
    let upper_abs_left: ZoneData
    let upper_abs_right: ZoneData
    let mid_abs_left: ZoneData
    let mid_abs_right: ZoneData
    let lower_abs_left: ZoneData
    let lower_abs_right: ZoneData
    let left_oblique: ZoneData
    let right_oblique: ZoneData
    let v_taper_left: ZoneData
    let v_taper_right: ZoneData
    let overall_assessment: String
    let strongest_area: String
    let weakest_area: String
    let technical_notes: [String]

    nonisolated struct ZoneData: Codable, Sendable {
        let score: Int
        let cx: Double
        let cy: Double
        let w: Double
        let h: Double
        let note: String
    }
}
