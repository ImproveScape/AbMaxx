import UIKit

nonisolated enum AbsStructure: String, Codable, Sendable {
    case flat = "Flat"
    case twoPack = "2-Pack"
    case fourPack = "4-Pack"
    case sixPack = "6-Pack"
    case eightPack = "8-Pack"
    case asymmetric = "Asymmetric"
}

nonisolated enum GeneticPotentialLevel: String, Codable, Sendable {
    case low, moderate, high, elite
}

nonisolated struct ScanResult: Codable, Identifiable, Sendable {
    static let minimumScore: Int = 0

    var id: UUID = UUID()
    var date: Date = Date()
    var photoData: Data?
    var photoFileName: String?
    var overallScore: Int = 0
    var definition: Int = 0
    var symmetry: Int = 0
    var thickness: Int = 0
    var obliques: Int = 0
    var frame: Int = 0
    var aesthetic: Int = 0
    var geneticPotential: Int = 0
    var absStructure: AbsStructure = .flat
    var phase: Int = 0
    var level: Int = 0
    var wasAIAnalyzed: Bool = false
    var bodyFatFromAI: Double?
    var coachVerdict: String?
    var visibilityTimeline: String?
    var geneticPotentialLevel: GeneticPotentialLevel = .moderate

    var breakdownCoachText: String?
    var breakdownWeeklyAction: String?
    var breakdownStructureNote: String?

    var insertionType: String {
        switch absStructure {
        case .sixPack, .eightPack: return "Stacked"
        case .asymmetric: return "Offset"
        case .fourPack: return "Short tendon"
        case .twoPack: return "High insertion"
        case .flat: return "Developing"
        }
    }

    var abWidth: String {
        let avg = Double(obliques + symmetry) / 2.0
        if avg >= 70 { return "Wide" }
        if avg >= 55 { return "Average" }
        return "Narrow"
    }

    var dominantZone: String {
        let zones: [(String, Int)] = [
            ("Upper Abs", upperAbsScore),
            ("Lower Abs", lowerAbsScore),
            ("Obliques", obliquesScore),
            ("Deep Core", deepCoreScore)
        ]
        return zones.max(by: { $0.1 < $1.1 })?.0 ?? "Upper Abs"
    }

    var upperAbsScore: Int { definition }
    var lowerAbsScore: Int { thickness }
    var obliquesScore: Int { obliques }
    var deepCoreScore: Int { aesthetic }

    static func clampScore(_ score: Int) -> Int {
        max(minimumScore, min(score, 99))
    }

    static func calculateOverall(definition: Int, thickness: Int, symmetry: Int, obliques: Int, frame: Int, aesthetic: Int) -> Int {
        let weighted = (Double(clampScore(definition)) * 0.25) +
                       (Double(clampScore(thickness)) * 0.25) +
                       (Double(clampScore(obliques)) * 0.20) +
                       (Double(clampScore(aesthetic)) * 0.15) +
                       (Double(clampScore(symmetry)) * 0.10) +
                       (Double(clampScore(frame)) * 0.05)
        return max(45, min(100, Int(weighted.rounded())))
    }

    static func parseAbsStructure(_ value: String) -> AbsStructure {
        switch value.lowercased().trimmingCharacters(in: .whitespaces) {
        case "8-pack", "8 pack", "eightpack": return .eightPack
        case "6-pack", "6 pack", "sixpack": return .sixPack
        case "4-pack", "4 pack", "fourpack": return .fourPack
        case "2-pack", "2 pack", "twopack": return .twoPack
        case "flat", "none", "no visible abs": return .flat
        case "asymmetric": return .asymmetric
        default: return .fourPack
        }
    }

    static func parseGeneticPotential(_ value: String) -> (GeneticPotentialLevel, Int) {
        switch value.lowercased().trimmingCharacters(in: .whitespaces) {
        case "elite": return (.elite, 90)
        case "high": return (.high, 75)
        case "moderate": return (.moderate, 60)
        case "low": return (.low, 40)
        default: return (.moderate, 60)
        }
    }

    static func fromAnalysis(_ analysis: AbAnalysisResponse) -> ScanResult {
        let def = clampScore(analysis.upper_abs)
        let thk = clampScore(analysis.lower_abs)
        let obl = clampScore(analysis.obliques)
        let aes = clampScore(analysis.deep_core)
        let sym = clampScore(analysis.symmetry)
        let frm = clampScore(analysis.v_taper)
        let weighted = (Double(def) * 0.25) +
                       (Double(thk) * 0.25) +
                       (Double(obl) * 0.20) +
                       (Double(aes) * 0.15) +
                       (Double(sym) * 0.10) +
                       (Double(frm) * 0.05)
        let overall = max(45, min(100, Int(weighted.rounded())))
        let structure = parseAbsStructure(analysis.abs_structure)
        let (gpLevel, gpScore) = parseGeneticPotential(analysis.genetic_potential)

        return ScanResult(
            overallScore: overall,
            definition: def, symmetry: sym,
            thickness: thk, obliques: obl,
            frame: frm, aesthetic: aes,
            geneticPotential: gpScore,
            absStructure: structure,
            wasAIAnalyzed: true,
            bodyFatFromAI: analysis.body_fat_estimate,
            coachVerdict: analysis.coach_verdict.isEmpty ? nil : analysis.coach_verdict,
            visibilityTimeline: analysis.visibility_timeline.isEmpty ? nil : analysis.visibility_timeline,
            geneticPotentialLevel: gpLevel
        )
    }

    static let scoreDescriptions: [String: String] = [
        "V Taper": "V-shaped torso tapering from shoulders to waist",
        "Symmetry": "Evenness of development between left/right and top/bottom",
        "Thickness": "Muscle belly depth and how much the abs protrude",
        "Obliques": "External oblique development and V-taper visibility",
        "Frame": "Waist-to-shoulder ratio and overall torso structure",
        "Aesthetic": "Overall visual appeal, proportionality, muscle-to-fat balance"
    ]

    static func ratingLabel(for score: Int) -> String {
        if score >= 88 { return "Elite" }
        if score >= 78 { return "Excellent" }
        if score >= 68 { return "Good" }
        if score >= 58 { return "Developing" }
        return "Beginner"
    }

    var estimatedBodyFat: Double {
        if let aiBf = bodyFatFromAI, aiBf > 0 {
            return aiBf
        }
        let def = Double(Self.clampScore(definition))
        let thk = Double(Self.clampScore(thickness))
        let aes = Double(Self.clampScore(aesthetic))
        let frm = Double(Self.clampScore(frame))
        let obl = Double(Self.clampScore(obliques))
        let weighted = def * 0.35 + aes * 0.25 + thk * 0.15 + frm * 0.15 + obl * 0.10
        let bf = 28.0 - (weighted - 30.0) * 0.22
        return max(6.0, min(30.0, (bf * 10).rounded() / 10))
    }

    var bodyFatCategory: String {
        let bf = estimatedBodyFat
        if bf <= 8 { return "Competition" }
        if bf <= 12 { return "Shredded" }
        if bf <= 15 { return "Lean" }
        if bf <= 20 { return "Athletic" }
        if bf <= 25 { return "Average" }
        return "Above Average"
    }

    var hasPhoto: Bool {
        photoFileName != nil || photoData != nil
    }

    @MainActor func loadImage() -> UIImage? {
        if let fileName = photoFileName {
            return PhotoStorageService.loadImage(fileName: fileName)
        }
        if let data = photoData {
            return UIImage(data: data)
        }
        return nil
    }

    var subscores: [(String, Int, String)] {
        [
            ("Upper Abs", definition, "chevron.up.2"),
            ("Lower Abs", thickness, "chevron.down.2"),
            ("Obliques", obliques, "arrow.triangle.branch"),
            ("Deep Core", aesthetic, "circle.grid.cross.fill"),
            ("Symmetry", symmetry, "arrow.left.arrow.right"),
            ("V Taper", frame, "chart.bar.fill")
        ]
    }

    var regions: [(String, Int, String)] {
        [
            ("Upper Abs", upperAbsScore, "chevron.up.2"),
            ("Lower Abs", lowerAbsScore, "chevron.down.2"),
            ("Obliques", obliquesScore, "arrow.left.and.right"),
            ("Deep Core", deepCoreScore, "circle.grid.cross.fill")
        ]
    }

    mutating func enforceMinimums() {
        definition = Self.clampScore(definition)
        symmetry = Self.clampScore(symmetry)
        thickness = Self.clampScore(thickness)
        obliques = Self.clampScore(obliques)
        frame = Self.clampScore(frame)
        aesthetic = Self.clampScore(aesthetic)
        geneticPotential = Self.clampScore(geneticPotential)
        overallScore = Self.clampScore(overallScore)
    }

    static let sample = ScanResult(
        overallScore: 62,
        definition: 68,
        symmetry: 64,
        thickness: 52,
        obliques: 58,
        frame: 65,
        aesthetic: 55,
        geneticPotential: 65,
        absStructure: .fourPack,
        phase: 0,
        level: 0,
        bodyFatFromAI: 17.5,
        coachVerdict: "Your upper abs show clear separation but lower abs are soft — reverse crunches with full posterior pelvic tilt will target those lower fibres directly.",
        visibilityTimeline: "Lower abs visible in approximately 8 weeks at 300 calorie deficit."
    )
}
