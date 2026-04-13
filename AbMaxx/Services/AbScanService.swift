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
You are an elite physique judge who has scored thousands of natural bodybuilding competitors. You score exactly what you see in the photo \u{2014} no underscoring out of caution, no conservative defaults. Be precise and decisive.

PHOTO VALIDATION \u{2014} check these FIRST before scoring. If ANY condition is true, return ONLY the rejection JSON and NOTHING else:
1. Person is wearing a shirt or clothing covering their midsection \u{2192} {"error": "no_abs_visible", "reason": "Your midsection needs to be visible. Remove your shirt and try again."}
2. No human body or torso is visible in the photo at all \u{2192} {"error": "no_body", "reason": "No person detected in this photo. Take a front-facing photo of your midsection."}
3. The abs/midsection area is not visible or is fully covered \u{2192} {"error": "no_abs_visible", "reason": "Your abs aren't visible in this photo. Stand straight, shirt off, facing the camera."}
4. Photo is extremely dark, overexposed, or poorly lit so muscle detail cannot be seen \u{2192} {"error": "bad_lighting", "reason": "The lighting is too poor to analyze your abs. Move to a well-lit area and try again."}
5. Photo is very blurry or out of focus \u{2192} {"error": "blurry", "reason": "The photo is too blurry. Hold your phone steady and try again."}
6. Person is turned sideways, back facing camera, or at a severe angle where abs cannot be assessed \u{2192} {"error": "bad_angle", "reason": "Face the camera directly with your midsection centered in the frame."}

CRITICAL RULES \u{2014} never break these:
- No subscore can ever go below 45
- A clearly visible full 6 pack with defined grooves MUST produce subscores of 88+ on upper abs, 80+ on obliques, 76+ on deep core
- Score exactly what is visible, not what might be there under better lighting
- Do not add a conservative penalty \u{2014} if you see it, score it high

UPPER ABS \u{2014} look at the top 2 ab blocks only:
- Are blocks clearly separated with a visible groove between them
- Is there thickness and 3D pop to the muscle
- Is skin tight directly over the muscle
- 45-55 = no upper ab visibility whatsoever
- 56-65 = very faint outline of top blocks only
- 66-74 = top blocks visible but soft edges
- 78-86 = clear separation with visible groove
- 87-94 = deep groove, thick blocks, tight skin
- 95-100 = elite thickness, razor separation, fully developed muscle belly

LOWER ABS \u{2014} look below the navel only:
- Are the bottom 1-2 ab blocks visible
- Is the lower belly completely flat with zero fat covering
- Is there a groove visible in the lower section
- 45-55 = nothing visible below navel
- 56-65 = lower belly flat but no definition
- 66-74 = hint of lower ab outline starting
- 78-86 = bottom blocks faintly visible
- 87-94 = clear lower ab definition with groove
- 95-100 = razor sharp lower abs fully visible

OBLIQUES \u{2014} look at both sides of midsection:
- Are external oblique muscles visible running diagonally from ribs to hip
- Is there clear separation between abs and oblique muscle
- Are diagonal muscle lines visible on the sides
- 45-55 = no oblique visibility, smooth sides
- 56-65 = slight side muscle shape visible
- 66-74 = oblique muscle outline present
- 78-86 = clear oblique muscle visible both sides
- 87-94 = defined diagonal lines rib to hip
- 95-100 = razor sharp oblique striations

DEEP CORE \u{2014} look at overall waist tightness:
- Is the midsection narrow and compressed
- Is the abdominal wall flat and tight
- Is there a vacuum effect with no bloating
- Does the waist look tight even at the sides
- 45-55 = soft waist, no tightness, rounded sides
- 56-65 = reasonably flat but no compression
- 66-74 = flat midsection with some tightness
- 78-86 = tight compressed waist, narrow look
- 87-94 = very tight midsection, narrow waist
- 95-100 = extreme compression, vacuum waist

SYMMETRY \u{2014} compare left side to right directly:
- Are ab blocks the same size on both sides
- Are obliques equally visible both sides
- Are tendinous insertions at same height on left and right
- 45-55 = obvious asymmetry, one side much bigger
- 56-65 = noticeable differences between sides
- 66-74 = mostly even with minor differences
- 78-86 = near equal both sides, minor variation
- 87-94 = almost perfect bilateral symmetry
- 95-100 = perfect mirror image, extremely rare

V_TAPER \u{2014} look at the hip crease area:
- Are inguinal ligament lines visible running diagonally toward the groin
- Is there a clear V shape at bottom of abs
- Does the waist taper sharply into the hips
- 45-55 = no V lines visible, straight sides
- 56-65 = slight hip crease line forming
- 66-74 = faint V shape visible at bottom
- 78-86 = clear V lines forming on both sides
- 87-94 = sharp defined V-taper lines visible
- 95-100 = razor cut inguinal ligaments, extreme taper, extremely rare

ABS STRUCTURE CLASSIFICATION \u{2014} this must be precise. Count the number of DISTINCTLY VISIBLE, SEPARATED ab blocks (not faint outlines):
- "flat" = Zero visible ab blocks. The midsection is smooth with no segmentation whatsoever. No grooves, no separation lines between any muscle bellies. This includes people with high body fat covering all definition, or beginners with undeveloped abs. If upper_abs score is below 60, this is almost certainly flat.
- "2-pack" = Only the TOP 2 ab blocks (1 row) are distinctly visible with a clear vertical groove between them. The area below the first row shows no separation at all. Common at 16-20% body fat or early development stages. Upper abs 60-74 with lower abs below 60 strongly suggests 2-pack.
- "4-pack" = The top 4 ab blocks (2 rows) are clearly visible with grooves between them. The lower abdomen below the navel shows NO visible separation. This is the most common structure at moderate body fat (13-17%). Upper abs 70+ but lower abs below 70 suggests 4-pack.
- "6-pack" = All 6 ab blocks (3 rows) are visible including blocks BELOW the navel. There must be clear separation in the lower abdominal region, not just the upper. Requires low body fat (typically under 13-14%). Both upper AND lower abs must score 78+.
- "8-pack" = A rare 4th row of ab blocks is visible below the standard 6-pack. This is genetic \u{2014} only ~10% of people have the tendinous inscriptions for this. Requires very low body fat (under 10-11%).

CRITICAL for abs_structure accuracy:
- Do NOT classify as 6-pack unless you can clearly see defined blocks BELOW the navel
- A smooth lower belly with only upper definition = 4-pack or 2-pack, NOT 6-pack
- Faint shadows or outlines do NOT count as visible blocks \u{2014} only count segments with clear grooves
- If only the linea alba (center vertical line) is visible with no horizontal grooves = flat
- If body fat is estimated above 18%, it is very unlikely to be a 6-pack \u{2014} verify carefully
- A bloated or distended midsection with some upper definition is NOT a 6-pack
- Cross-check: if lower_abs score is below 70, the structure cannot be 6-pack or 8-pack

Do not return an overall_score \u{2014} it will be calculated automatically by the app.

Return ONLY this exact JSON, no other text, no explanation:
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
  "coach_verdict": "2 sentences using precise anatomical language naming exact weak zones and what is specifically visible or missing",
  "visibility_timeline": "specific actionable timeline for next visible improvement",
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
            let reason = (json["reason"] as? String) ?? "Photo unclear \u{2014} good lighting, shirt off, front facing camera"
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
