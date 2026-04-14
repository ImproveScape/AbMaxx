import Foundation
import UIKit

nonisolated struct AbAnalysisResponse: Codable, Sendable {
    let upper_abs: Int
    let lower_abs: Int
    let obliques: Int
    let deep_core: Int
    let symmetry: Int
    let v_taper: Int
    let overall_score: Int
    let body_fat_estimate: Double
    let abs_structure: String
    let genetic_potential: String
    let coach_verdict: String
    let visibility_timeline: String
    var poorPhoto: Bool = false
    var rejectionReason: String? = nil

    nonisolated enum CodingKeys: String, CodingKey {
        case upper_abs, lower_abs, obliques, deep_core, symmetry, v_taper
        case overall_score, body_fat_estimate, abs_structure, genetic_potential
        case coach_verdict, visibility_timeline, poorPhoto, rejectionReason
    }
}

class AbScanService {
    static let shared = AbScanService()

    private let systemPrompt = """
You are the world's most precise abs analysis system. You have scored thousands of physiques from beginner to elite bodybuilder. Your scores are brutally accurate and never inflated. You score ABS DEFINITION ONLY — never influenced by muscle size, body mass, or how impressive someone looks overall.

YOUR SINGLE MOST IMPORTANT RULE: Score what you can literally see in the midsection. If you cannot clearly see it, it does not exist. Shadows, guesses, and assumptions score zero. Only visible, clear, undeniable definition scores high. Large muscles with soft undefined abs score LOW. Size is not definition.

PHOTO VALIDATION — check FIRST before anything else. Return ONLY rejection JSON if true:
1. Midsection covered by clothing → {"error": "no_abs_visible", "reason": "Your midsection needs to be visible. Remove your shirt and try again."}
2. No human torso visible → {"error": "no_body", "reason": "No person detected. Take a front-facing photo of your midsection."}
3. Abs not visible → {"error": "no_abs_visible", "reason": "Your abs aren't visible. Stand straight, shirt off, facing camera."}
4. Extremely dark or overexposed → {"error": "bad_lighting", "reason": "Lighting too poor. Move to a well-lit area and try again."}
5. Blurry → {"error": "blurry", "reason": "Photo too blurry. Hold steady and try again."}
6. Sideways or back facing → {"error": "bad_angle", "reason": "Face the camera directly with midsection centered."}

BIOMETRIC DATA RULE — CRITICAL: The user biometric data in the user message is ONLY for genetic_potential calculation. Do NOT use self-reported body fat category, abs description, weight, or activity level to influence any visual scores. Score only what you can literally see in the photo. A user calling themselves Athletic does not make them score higher. Visual evidence only.

BODY FAT ESTIMATION — do this FIRST before scoring anything. Estimate body fat by looking at:
- Facial leanness and jaw definition
- Visibility of veins on arms and hands
- Separation between muscle groups on chest and shoulders
- How much fat covers the lower abs specifically
- Overall skin tightness across the midsection
- CRITICAL: Do not let large muscle mass push your BF estimate higher. A very muscular person can be 11-12% BF. Judge fat layer thickness, not body size.

Body fat reference scale:
5-7% = stage ready, extreme vascularity everywhere, paper thin skin, every muscle fully striated
8-10% = very lean, clear veins on abs, razor sharp separation everywhere, typical contest prep
11-13% = athletic and lean, abs clearly visible including below navel, some vascularity, tight midsection
14-16% = fit, upper abs clearly visible, lower abs beginning to show, little to no vascularity
17-19% = some upper ab outline only, lower belly has a clear fat layer, looks healthy and fit
20-24% = minimal ab visibility, smooth midsection, some muscle shape visible
25%+ = no ab visibility, significant fat covering entire midsection

BODY FAT CROSS-VALIDATION — enforce these hard caps strictly. No exceptions:
- If body fat above 19%: upper_abs cannot exceed 68, lower_abs cannot exceed 58, structure cannot be 6-pack or 8-pack
- If body fat 17-19%: upper_abs cannot exceed 76, lower_abs cannot exceed 67, structure cannot be 6-pack
- If body fat 14-16%: upper_abs cannot exceed 84, lower_abs cannot exceed 78, structure cannot be 6-pack or 8-pack
- If body fat 11-13%: full range available, 6-pack possible only if lower blocks show clear visible separation
- If body fat below 11%: full range available including 8-pack if 4th row clearly visible

ANCHOR MATCHING — match the physique to exactly one anchor based solely on what you see. Score at the CENTER of the anchor range. Only move toward the top of the range if 3 or more zones show exceptional detail clearly above the anchor midpoint. Never score at the top by default.

ANCHOR 1 — COMPETITION ELITE (overall 96-98):
Body fat 5-8%. Paper thin skin. Veins visible on abs themselves. Every single block razor separated with extreme deep grooves. Lower abs fully shredded. Obliques striated. Looks like a natural bodybuilding competitor on stage.
upper_abs 95-98, lower_abs 93-96, obliques 93-96, deep_core 93-96, v_taper 91-94, symmetry 91-94

ANCHOR 2 — ELITE (overall 92-95):
Body fat 8-11%. All 6 blocks clearly visible with deep razor grooves including below navel. Strong 3D thickness. Extremely tight skin. Sharp oblique cuts visible both sides. Clear V-taper lines. Top 2% of people who train. ONLY apply this anchor if body fat is visually confirmed below 12% AND all 6 blocks show undeniable razor grooves. Muscular physiques with soft definition do not qualify for this anchor regardless of muscle size.
upper_abs 92-95, lower_abs 89-93, obliques 89-93, deep_core 89-93, v_taper 87-91, symmetry 87-91

ANCHOR 3 — VERY ADVANCED (overall 85-89):
Body fat 11-13%. Clear 6-pack with solid groove depth. All 6 blocks visible including below navel. Tight skin. Good obliques visible. Strong athletic midsection with real definition.
upper_abs 86-90, lower_abs 82-87, obliques 83-88, deep_core 83-88, v_taper 80-85, symmetry 82-87

ANCHOR 4 — ADVANCED (overall 80-84):
Body fat 13-15%. Clear upper abs with grooves. Lower definition present but fading below navel. Good obliques visible. Solid athletic look. Lower blocks may show faint outline.
upper_abs 81-86, lower_abs 74-81, obliques 78-83, deep_core 78-83, v_taper 75-80, symmetry 78-83

ANCHOR 5 — INTERMEDIATE (overall 74-79):
Body fat 15-17%. Clear 4-pack. Upper abs visible with grooves. Zero or minimal separation below navel. Obliques present but soft edges.
upper_abs 75-81, lower_abs 63-72, obliques 72-79, deep_core 74-80, v_taper 70-76, symmetry 73-78

ANCHOR 6 — DEVELOPING (overall 65-73):
Body fat 17-19%. Upper ab outline faint. No real grooves. Lower belly smooth. Some muscle shape barely visible.
upper_abs 67-75, lower_abs 57-65, obliques 65-73, deep_core 68-75, v_taper 62-70, symmetry 67-74

ANCHOR 7 — BEGINNER (overall 50-64):
Body fat 19%+. Minimal or zero ab visibility. Smooth midsection. Fat layer covering everything. No blocks, no grooves, no separation.
upper_abs 50-66, lower_abs 50-61, obliques 50-64, deep_core 54-67, v_taper 50-62, symmetry 54-68

UPPER ABS — top 2 blocks only:
50-61 = zero visibility, smooth skin, no hint of block shape
62-69 = very faint shadow suggesting blocks but no actual groove
70-76 = blocks visible as raised areas but completely soft edges, no groove
77-82 = blocks clearly visible with a shallow groove forming
83-88 = clear deep groove, visible 3D thickness, tight skin
89-93 = very deep groove, pronounced 3D pop, razor edges, extremely tight skin
94-97 = elite separation, competition quality, extreme muscle belly development
98-100 = once in a generation, natural bodybuilding stage winner, extremely rare

LOWER ABS — below the navel only:
50-61 = completely smooth below navel, zero definition, clear fat layer
62-69 = lower belly flat but absolutely no block outline or separation
70-76 = faint hint of lower structure but no actual visible blocks
77-82 = one or two lower blocks faintly visible, very soft edges
83-88 = lower blocks clearly visible with groove, completely flat lower belly
89-93 = razor lower ab definition, deep grooves between lower blocks
94-97 = competition quality lower abs, extreme definition
98-100 = extremely rare, elite natural athlete

OBLIQUES — both sides from ribs to hip:
50-61 = completely smooth sides, no muscle visible
62-69 = slight muscle shape on sides, no definition
70-76 = oblique muscle outline present, soft edges
77-82 = clear oblique muscle visible both sides with separation
83-88 = defined diagonal lines clearly running rib to hip
89-93 = razor sharp oblique cuts, strong separation from abs
94-97 = extreme oblique definition, striations visible
98-100 = competition level, extremely rare

DEEP CORE — waist tightness and compression:
50-61 = soft waist, rounded sides, no compression
62-69 = reasonably flat but no compression, average width
70-76 = flat midsection, some tightness beginning
77-82 = clearly tight compressed waist, narrow athletic appearance
83-88 = very tight midsection, noticeable narrow waist from front
89-93 = extreme compression, vacuum effect visible, very narrow waist
94-97 = stage ready waist tightness
98-100 = extreme vacuum, extremely rare

V_TAPER — inguinal ligament and hip crease:
50-61 = no V lines whatsoever, straight sides into waistband
62-69 = very slight hip crease beginning to form
70-76 = faint V shape visible but not defined
77-82 = clear V lines forming on both sides
83-88 = sharp defined V-taper lines clearly visible
89-93 = razor cut inguinal ligaments prominently visible
94-97 = extreme V-taper, competition quality
98-100 = exceptionally rare extreme taper

SYMMETRY — left vs right comparison:
50-61 = dramatic asymmetry, one side clearly much larger
62-69 = noticeable differences between sides
70-76 = mostly symmetrical with visible minor differences
77-82 = nearly equal both sides, only very minor variation
83-88 = essentially equal both sides
89-93 = almost perfect bilateral symmetry
94-97 = near perfect mirror image
98-100 = perfect symmetry, extremely rare

OVERALL SCORE VERIFICATION — after scoring all zones compute this weighted formula exactly: weighted = (upper_abs × 0.25) + (lower_abs × 0.25) + (obliques × 0.20) + (deep_core × 0.15) + (v_taper × 0.10) + (symmetry × 0.05). Verify this result matches the correct visual bracket below. If your weighted result lands in the wrong bracket, adjust your zone scores until they match what you actually see — do not force a higher bracket to flatter the user.
50-64 = beginner, zero ab visibility
65-72 = developing, faint outline only
73-79 = intermediate, upper abs clear no lower definition
80-85 = advanced, solid 4-pack or very soft 6-pack
86-90 = very advanced, clear defined 6-pack with real grooves
91-95 = elite, razor sharp full 6-pack deep grooves everywhere
96-100 = competition stage, once in a generation

ABS STRUCTURE — count only blocks with unmistakable clear grooves:
"flat" = zero blocks visible. Completely smooth. Upper abs below 65.
"2-pack" = only top 2 blocks with groove between them. Nothing below. Upper abs 65-79, lower abs below 67.
"4-pack" = top 4 blocks with grooves. Zero separation below navel. Upper abs 74+ but lower abs below 78.
"6-pack" = all 6 blocks visible including below navel with clear groove. Lower abs MUST score 78+ to qualify. Body fat must be below 16%.
"8-pack" = rare 4th row clearly visible. Body fat below 11%. Lower abs must score 90+.

GENETIC POTENTIAL — use biometric data for this calculation only:
"low" = wide waist, short muscle bellies, limited natural taper
"moderate" = average insertions, decent waist-to-hip ratio
"high" = good insertion points, narrow waist, natural V-taper
"elite" = exceptional insertions, naturally narrow waist, strong V-taper, about 5% of people

coach_verdict: Write exactly 3 sentences separated by | with no spaces around pipes. Each sentence under 15 words. No markdown. Write about what you specifically see in THIS photo. Sentence 1: name the single strongest visual element visible in the midsection. Sentence 2: name the single weakest element and describe exactly what it looks like. Sentence 3: one specific actionable recommendation based on exact scores. Example: 'Your upper two blocks show razor deep grooves with elite 3D thickness.|Your lower abs are completely smooth — zero separation below the navel yet.|Drop to 11% body fat and your lower blocks will physically emerge.'

visibility_timeline: Return exactly this format — number followed by weeks or Visible now, pipe |, target body fat as number followed by %, pipe |, one specific action under 8 words. Example: '6 weeks|12%|Train lower abs and obliques daily'

Do not return overall_score — calculated automatically by app.

Return ONLY this exact JSON with no other text:
{
"upper_abs": 0-100,
"lower_abs": 0-100,
"obliques": 0-100,
"deep_core": 0-100,
"symmetry": 0-100,
"v_taper": 0-100,
"body_fat_estimate": number between 6 and 30,
"abs_structure": "flat" or "2-pack" or "4-pack" or "6-pack" or "8-pack",
"genetic_potential": "low" or "moderate" or "high" or "elite",
"coach_verdict": "sentence1|sentence2|sentence3",
"visibility_timeline": "weeks|target%|action",
"error": null
}
"""

    var lastScanError: String?

    func analyzePhoto(_ image: UIImage, profile: UserProfile) async -> AbAnalysisResponse? {
        print("[AbScan] Function called - starting scan via direct Anthropic API")
        lastScanError = nil

        guard let base64 = imageToBase64(image) else {
            print("[AbScan] ERROR: Failed to convert image to base64")
            lastScanError = "Failed to process image"
            return nil
        }

        let userText = "Score this physique photo using the exact grading criteria and anchors in your instructions. A clearly visible 6 pack with defined grooves between blocks MUST score 91-97 on upper abs and 88+ overall. Do not underscore elite physiques. Score generously within each anchor range — when in doubt between two ranges always choose the higher one. For abs_structure: count ONLY distinctly separated blocks with visible grooves. If lower abs below the navel have no visible separation, do NOT classify as 6-pack. Be precise — flat means zero blocks, 2-pack means only top row visible. Cross-check your structure against subscores. Return only the JSON."

        do {
            let text = try await AnthropicService.shared.chatWithVision(
                systemPrompt: systemPrompt,
                userText: userText,
                imageBase64: base64,
                model: "claude-sonnet-4-20250514",
                maxTokens: 1024,
                temperature: 0.3
            )

            print("[AbScan] Anthropic response received")
            print("[AbScan] Parsed text content: \(text)")

            guard !text.isEmpty else {
                print("[AbScan] Error: Empty response text")
                lastScanError = "AI returned empty response"
                return nil
            }

            return parseAnalysisFromText(text)
        } catch {
            print("[AbScan] CATCH ERROR: \(error)")
            lastScanError = error.localizedDescription
            return nil
        }
    }

    func profileBasedScoring(profile: UserProfile, previousScan: ScanResult?, daysOnProgram: Int, exercisesCompleted: Int) -> AbAnalysisResponse {
        let bodyFatBase: Int
        switch profile.bodyFatCategory {
        case .lean: bodyFatBase = 65
        case .athletic: bodyFatBase = 55
        case .average: bodyFatBase = 45
        case .aboveAverage: bodyFatBase = 35
        }

        let absOffset: Int
        switch profile.absDescription {
        case .barelyVisible: absOffset = 0
        case .slightOutline: absOffset = 5
        case .topTwoVisible: absOffset = 10
        case .fourPackVisible: absOffset = 15
        case .almostThere: absOffset = 20
        }

        let activityOffset: Int
        switch profile.activityLevel {
        case .sedentary: activityOffset = 0
        case .lightlyActive: activityOffset = 3
        case .moderate, .moderatelyActive: activityOffset = 6
        case .veryActive: activityOffset = 9
        case .extraActive: activityOffset = 10
        }

        let progressBoost = min(Double(daysOnProgram) * 0.08, 8.0)
        let exerciseBoost = min(Double(exercisesCompleted) * 0.03, 5.0)
        let totalBoost = Int(progressBoost + exerciseBoost)

        var upperAbs = bodyFatBase + absOffset + activityOffset + totalBoost
        var lowerAbs = max(upperAbs - Int.random(in: 5...12), 30)
        var obl = bodyFatBase + (absOffset * 2 / 3) + activityOffset + totalBoost - Int.random(in: 2...6)
        var deepCore = bodyFatBase + (absOffset / 2) + activityOffset + totalBoost - Int.random(in: 3...8)
        var sym = bodyFatBase + (absOffset / 2) + activityOffset + totalBoost + Int.random(in: 0...4)
        var vTaper = bodyFatBase + 5 + min(totalBoost, 3)

        if let prev = previousScan {
            let variance = 2
            upperAbs = anchorToPrevious(prev.definition, new: upperAbs, variance: variance)
            lowerAbs = anchorToPrevious(prev.thickness, new: lowerAbs, variance: variance)
            obl = anchorToPrevious(prev.obliques, new: obl, variance: variance)
            deepCore = anchorToPrevious(prev.aesthetic, new: deepCore, variance: variance)
            sym = anchorToPrevious(prev.symmetry, new: sym, variance: variance)
            vTaper = anchorToPrevious(prev.frame, new: vTaper, variance: variance)
        }

        let ua = clamp(upperAbs)
        let la = clamp(lowerAbs)
        let ob = clamp(obl)
        let dc = clamp(deepCore)
        let sy = clamp(sym)
        let vt = clamp(vTaper)
        let overall = Int(round(Double(ua + la + ob + dc + sy + vt) / 6.0))

        let bfEstimate: Double
        switch profile.bodyFatCategory {
        case .lean: bfEstimate = Double.random(in: 10...14)
        case .athletic: bfEstimate = Double.random(in: 14...18)
        case .average: bfEstimate = Double.random(in: 18...23)
        case .aboveAverage: bfEstimate = Double.random(in: 23...28)
        }

        let absStructure: String
        switch profile.absDescription {
        case .almostThere: absStructure = "6-pack"
        case .fourPackVisible: absStructure = "4-pack"
        case .topTwoVisible: absStructure = "2-pack"
        case .slightOutline: absStructure = "2-pack"
        case .barelyVisible: absStructure = "flat"
        }

        return AbAnalysisResponse(
            upper_abs: ua, lower_abs: la, obliques: ob,
            deep_core: dc, symmetry: sy, v_taper: vt,
            overall_score: clamp(overall),
            body_fat_estimate: (bfEstimate * 10).rounded() / 10,
            abs_structure: absStructure,
            genetic_potential: "moderate",
            coach_verdict: "Profile-based estimate. Scan with a photo for a personalised AI analysis.",
            visibility_timeline: "Scan with a photo for a personalised timeline."
        )
    }

    private func anchorToPrevious(_ previous: Int, new: Int, variance: Int) -> Int {
        let diff = new - previous
        if abs(diff) <= variance {
            return new
        }
        let jitter = Int.random(in: -1...1)
        if diff > 0 {
            return previous + min(diff, variance + 1) + jitter
        } else {
            return previous + max(diff, -(variance + 1)) + jitter
        }
    }

    private func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    private func clampScore(_ value: Int) -> Int {
        max(45, min(100, value))
    }

    private func imageToBase64(_ image: UIImage) -> String? {
        autoreleasepool {
            let maxDimension: CGFloat = 600
            let size = image.size
            let scale: CGFloat
            if size.width > size.height {
                scale = min(maxDimension / size.width, 1.0)
            } else {
                scale = min(maxDimension / size.height, 1.0)
            }
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)

            let renderer = UIGraphicsImageRenderer(size: newSize)
            let jpegData = renderer.jpegData(withCompressionQuality: 0.6) { context in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }

            return jpegData.base64EncodedString()
        }
    }

    private func parseAnalysisFromText(_ text: String) -> AbAnalysisResponse? {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = jsonString.range(of: "{"), let end = jsonString.range(of: "}", options: .backwards) {
            jsonString = String(jsonString[start.lowerBound...end.upperBound])
        }
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        if let errorValue = json["error"] as? String, !errorValue.isEmpty {
            let reason = (json["reason"] as? String) ?? "Photo unclear — good lighting, shirt off, front facing camera"
            print("[AbScan] Photo rejected by Claude: \(errorValue) - \(reason)")
            return AbAnalysisResponse(
                upper_abs: 0, lower_abs: 0, obliques: 0,
                deep_core: 0, symmetry: 0, v_taper: 0,
                overall_score: 0, body_fat_estimate: 0,
                abs_structure: "", genetic_potential: "",
                coach_verdict: "", visibility_timeline: "",
                poorPhoto: true,
                rejectionReason: reason
            )
        }

        guard let upperAbs = json["upper_abs"] as? Int,
              let lowerAbs = json["lower_abs"] as? Int,
              let obl = json["obliques"] as? Int,
              let deepCore = json["deep_core"] as? Int,
              let sym = json["symmetry"] as? Int,
              let vTaper = json["v_taper"] as? Int else { return nil }

        _ = json["overall_score"]

        let bodyFat: Double
        if let bf = json["body_fat_estimate"] as? Double {
            bodyFat = bf
        } else if let bf = json["body_fat_estimate"] as? Int {
            bodyFat = Double(bf)
        } else {
            bodyFat = 20.0
        }

        let absStructure = (json["abs_structure"] as? String) ?? "4-pack"
        let geneticPotential = (json["genetic_potential"] as? String) ?? "moderate"
        let coachVerdict = (json["coach_verdict"] as? String) ?? ""
        let visibilityTimeline = (json["visibility_timeline"] as? String) ?? ""

        let clampedUA = clampScore(upperAbs)
        let clampedLA = clampScore(lowerAbs)
        let clampedOB = clampScore(obl)
        let clampedDC = clampScore(deepCore)
        let clampedSY = clampScore(sym)
        let clampedVT = clampScore(vTaper)
        let computedOverall = Int(round(Double(clampedUA + clampedLA + clampedOB + clampedDC + clampedSY + clampedVT) / 6.0))

        let validatedStructure = validateAbsStructure(absStructure, upperAbs: clampedUA, lowerAbs: clampedLA, bodyFat: bodyFat)

        return AbAnalysisResponse(
            upper_abs: clampedUA,
            lower_abs: clampedLA,
            obliques: clampedOB,
            deep_core: clampedDC,
            symmetry: clampedSY,
            v_taper: clampedVT,
            overall_score: clamp(computedOverall),
            body_fat_estimate: max(8.0, min(30.0, bodyFat)),
            abs_structure: validatedStructure,
            genetic_potential: geneticPotential,
            coach_verdict: coachVerdict,
            visibility_timeline: visibilityTimeline
        )
    }

    private func validateAbsStructure(_ claimed: String, upperAbs: Int, lowerAbs: Int, bodyFat: Double) -> String {
        let structure = claimed.lowercased().trimmingCharacters(in: .whitespaces)

        if (structure == "8-pack" || structure == "8 pack") && lowerAbs < 85 {
            return lowerAbs >= 78 ? "6-pack" : (upperAbs >= 70 ? "4-pack" : "2-pack")
        }

        if (structure == "6-pack" || structure == "6 pack") && lowerAbs < 70 {
            return upperAbs >= 70 ? "4-pack" : (upperAbs >= 60 ? "2-pack" : "flat")
        }

        if (structure == "4-pack" || structure == "4 pack") && upperAbs < 60 {
            return upperAbs >= 55 ? "2-pack" : "flat"
        }

        if (structure == "2-pack" || structure == "2 pack") && upperAbs < 55 {
            return "flat"
        }

        return claimed
    }
}
