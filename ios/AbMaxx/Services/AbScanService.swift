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
    let genetic_potential_score: Int
    let coach_verdict: String
    let visibility_timeline: String
    var poorPhoto: Bool = false
    var rejectionReason: String? = nil

    nonisolated enum CodingKeys: String, CodingKey {
        case upper_abs, lower_abs, obliques, deep_core, symmetry, v_taper
        case overall_score, body_fat_estimate, abs_structure, genetic_potential
        case genetic_potential_score, coach_verdict, visibility_timeline, poorPhoto, rejectionReason
    }
}

class AbScanService {
    static let shared = AbScanService()

    private let systemPrompt = """
You are the world's most precise abs scoring system. You score ABS DEFINITION ONLY from photos. Never influenced by muscle size, body mass, or overall impressiveness.

PHOTO VALIDATION — reject immediately if true:
1. Midsection covered → {"error": "no_abs_visible", "reason": "Your midsection needs to be visible. Remove your shirt and try again."}
2. No torso visible → {"error": "no_body", "reason": "No person detected. Take a front-facing photo of your midsection."}
3. Abs not visible → {"error": "no_abs_visible", "reason": "Your abs aren't visible. Stand straight, shirt off, facing camera."}
4. Too dark or overexposed → {"error": "bad_lighting", "reason": "Lighting too poor. Move to a well-lit area and try again."}
5. Blurry → {"error": "blurry", "reason": "Photo too blurry. Hold steady and try again."}
6. Back facing → {"error": "bad_angle", "reason": "Face the camera directly with midsection centered."}

BIOMETRIC DATA: Use ONLY for genetic_potential. Never influence visual scores with self-reported data.

STEP 1 — ESTIMATE BODY FAT:
Judge ONLY fat layer thickness, skin tightness, groove visibility. Muscle size has zero correlation with BF. A very muscular person can be 10-12% BF.
- If upper abs show razor deep grooves with 3D pop → BF cannot exceed 13%
- If full clear 6-pack visible below navel with grooves → BF cannot exceed 13%
- If only upper abs visible, lower belly smooth → BF is 15-17%
- If no abs visible, smooth midsection → BF is 20%+

5-7% = paper thin skin, veins on abs themselves, fully striated everywhere
8-10% = razor sharp everywhere, clear ab veins, extremely tight skin
11-13% = all 6 blocks visible below navel, tight skin, some vascularity on arms
14-16% = upper abs clear with grooves, lower abs beginning to show, no veins
17-19% = upper ab outline only, soft lower belly, healthy fit look
20-24% = smooth midsection, minimal visibility
25%+ = no visibility, significant fat layer everywhere

SKIN TONE CORRECTION: Darker skin reduces photo contrast — not definition. For medium-dark to dark skin tones add 2-3 points to all definition scores. Judge 3D groove depth, not brightness contrast.

ANGLE: Never penalize angled or side photos. Score what is visible. Default symmetry to 87 if angle prevents full bilateral view.

STEP 2 — SCORE EACH ZONE independently on visuals alone.

CALIBRATION REFERENCE — use these exact physique types to anchor your scoring:
- Razor sharp full 6-pack, all blocks deeply grooved below navel, extremely tight skin, ~10% BF = upper_abs 96-98, lower_abs 93-95, overall 94-95
- Clear defined 6-pack, solid grooves all blocks, tight skin, ~12% BF = upper_abs 92-94, lower_abs 89-91, overall 90-92
- Good 6-pack, upper grooves clear, lower fading, ~14% BF = upper_abs 88-90, lower_abs 82-85, overall 87-89
- Clear 4-pack only, lower belly smooth, ~16% BF = upper_abs 80-83, lower_abs 66-71, overall 77-80
- Faint upper ab outline, no real grooves, ~18% BF = upper_abs 71-75, lower_abs 59-64, overall 68-73
- Smooth midsection, no visibility, ~22% BF = upper_abs 52-58, lower_abs 50-54, overall 52-58

UPPER ABS (top 2 blocks only):
50-63 = zero visibility, smooth skin
64-70 = faint shadow, no groove
71-77 = blocks visible, soft edges, no groove
78-83 = shallow groove forming
84-89 = clear deep groove, 3D thickness, tight skin
90-94 = very deep groove, razor edges, pronounced 3D pop
95-97 = elite competition quality, extreme muscle belly development
98-100 = once in a generation

LOWER ABS (below navel only):
50-63 = completely smooth, clear fat layer
64-70 = flat, zero block outline
71-77 = faint hint of structure, no actual blocks
78-83 = one or two blocks faintly visible, soft edges
84-89 = lower blocks clear with groove, flat lower belly
90-94 = razor definition, deep grooves between lower blocks
95-97 = competition quality
98-100 = extremely rare

OBLIQUES (ribs to hip both sides):
50-63 = completely smooth sides
64-70 = slight muscle shape, no definition
71-77 = outline present, soft edges
78-83 = clear oblique muscle both sides
84-89 = diagonal lines clearly running rib to hip
90-94 = razor sharp cuts, strong separation from abs
95-97 = extreme definition, striations visible
98-100 = competition level

DEEP CORE (waist tightness and compression):
50-63 = soft rounded waist
64-70 = flat but no compression
71-77 = some tightness beginning
78-83 = clearly tight narrow athletic waist
84-89 = very tight, noticeable narrow waist
90-94 = extreme compression, vacuum effect
95-97 = stage ready waist tightness
98-100 = extreme vacuum, extremely rare

V_TAPER (inguinal ligament and hip crease):
50-63 = no V lines
64-70 = very faint hip crease
71-77 = faint V shape
78-83 = clear V lines both sides
84-89 = sharp defined V lines clearly visible
90-94 = razor cut inguinal ligaments prominently visible
95-97 = extreme V-taper, competition quality
98-100 = exceptionally rare

SYMMETRY (left vs right):
50-63 = dramatic asymmetry
64-70 = noticeable differences
71-77 = mostly symmetrical
78-83 = nearly equal, minor variation
84-89 = essentially equal both sides
90-94 = almost perfect bilateral symmetry
95-97 = near perfect mirror image
98-100 = perfect symmetry

STEP 3 — VERIFY: Compute weighted = (upper_abs×0.25)+(lower_abs×0.25)+(obliques×0.20)+(deep_core×0.15)+(v_taper×0.10)+(symmetry×0.05). Match to bracket:
50-64 = beginner, zero visibility
65-72 = developing, faint outline
73-79 = intermediate, upper abs clear no lower definition
80-85 = advanced, solid 4-pack or soft 6-pack
86-91 = very advanced, clear defined 6-pack real grooves
92-96 = elite, razor sharp full 6-pack deep grooves everywhere
97-100 = competition stage, once in a generation

ABS STRUCTURE:
"flat" = zero blocks visible
"2-pack" = top 2 blocks only, nothing below
"4-pack" = top 4 blocks, zero below navel
"6-pack" = all 6 blocks visible below navel with clear groove, BF below 16%
"8-pack" = 4th row clearly visible, BF below 11%

GENETIC POTENTIAL (biometric data only):
"low" = wide waist, limited taper
"moderate" = average insertions, decent waist-to-hip ratio
"high" = narrow waist, natural V-taper
"elite" = exceptional insertions, naturally narrow waist, strong V-taper

coach_verdict: Exactly 3 sentences separated by | with no spaces around pipes. Each sentence under 15 words. Sentence 1: strongest visual element in THIS photo. Sentence 2: weakest element and exactly what it looks like. Sentence 3: one specific actionable recommendation.

visibility_timeline: exact format: number+weeks or Visible now | target BF% | action under 8 words

Return ONLY this JSON:
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

    private let userPromptTemplate = "Analyze this physique photo using your exact grading criteria. Estimate body fat first then apply cross-validation rules strictly. Score ABS DEFINITION ONLY \u{2014} not muscle size or overall impressiveness. Compute the weighted score mentally using (upper_abs×0.25)+(lower_abs×0.25)+(obliques×0.20)+(deep_core×0.15)+(v_taper×0.10)+(symmetry×0.05) with no multiplier and verify your subscores land in the correct visual bracket before returning. Sharp visible grooves = high score. Large muscles with soft undefined abs = lower score. Return only the JSON."

    private func buildUserPrompt(profile: UserProfile) -> String {
        var biometrics: [String] = []
        biometrics.append("Age: \(profile.age)")
        biometrics.append("Gender: \(profile.gender.rawValue)")
        let heightStr = profile.useMetric ? "\(Int(profile.heightInCm)) cm" : "\(profile.heightFeet)'\(profile.heightInches)\""
        biometrics.append("Height: \(heightStr)")
        let weightStr = profile.useMetric ? "\(Int(profile.weightLbs)) kg" : "\(Int(profile.weightLbs)) lbs"
        biometrics.append("Weight: \(weightStr)")
        biometrics.append("Self-reported body fat category: \(profile.bodyFatCategory.rawValue) (\(profile.bodyFatCategory.rangeText))")
        biometrics.append("Activity level: \(profile.activityLevel.rawValue)")
        biometrics.append("Self-reported abs description: \(profile.absDescription.rawValue)")
        biometrics.append("Training frequency: \(profile.absTrainingFrequency.rawValue) per week")
        if profile.daysOnProgram > 0 {
            biometrics.append("Days on program: \(profile.daysOnProgram)")
        }
        let biometricBlock = biometrics.joined(separator: ". ")
        return "USER BIOMETRIC DATA for genetic potential calculation: \(biometricBlock). \(userPromptTemplate)"
    }

    var lastScanError: ScanError?
    private var lastScanAttemptDate: Date?
    private static let scanCooldownSeconds: TimeInterval = 30

    var isRateLimited: Bool {
        guard let last = lastScanAttemptDate else { return false }
        return Date().timeIntervalSince(last) < Self.scanCooldownSeconds
    }

    var secondsUntilNextAttempt: Int {
        guard let last = lastScanAttemptDate else { return 0 }
        let remaining = Self.scanCooldownSeconds - Date().timeIntervalSince(last)
        return max(Int(ceil(remaining)), 0)
    }

    nonisolated enum ScanError: Error, Sendable {
        case networkError(String)
        case badPhoto(String)
        case apiError(String)
        case timeout

        var userMessage: String {
            switch self {
            case .networkError: return "Network error \u{2014} check your connection and try again."
            case .badPhoto(let reason): return reason
            case .apiError(let msg): return "Analysis failed: \(msg). Try again."
            case .timeout: return "Analysis timed out \u{2014} try again with better lighting."
            }
        }

        var isBadPhoto: Bool {
            if case .badPhoto = self { return true }
            return false
        }
    }

    func analyzePhoto(_ image: UIImage, profile: UserProfile) async -> AbAnalysisResponse? {
        print("[AbScan] Function called - starting scan via Anthropic API")
        print("[AbScan] Image size: \(image.size), scale: \(image.scale)")
        lastScanError = nil

        if isRateLimited {
            let wait = secondsUntilNextAttempt
            lastScanError = .apiError("Please wait \(wait) seconds before trying again.")
            return nil
        }
        lastScanAttemptDate = Date()

        guard let base64 = imageToBase64(image) else {
            print("[AbScan] ERROR: Failed to convert image to base64")
            lastScanError = .apiError("Failed to process image")
            return nil
        }
        print("[AbScan] Base64 string length: \(base64.count) chars")

        let result = await callRorkAIProxy(base64: base64, profile: profile)

        switch result {
        case .success(let response):
            if response.poorPhoto {
                lastScanError = .badPhoto(response.rejectionReason ?? "Photo unclear")
            }
            return response
        case .failure(let error):
            lastScanError = error
            if case .badPhoto = error {
                return AbAnalysisResponse(
                    upper_abs: 0, lower_abs: 0, obliques: 0,
                    deep_core: 0, symmetry: 0, v_taper: 0,
                    overall_score: 0, body_fat_estimate: 0,
                    abs_structure: "", genetic_potential: "",
                    genetic_potential_score: 0,
                    coach_verdict: "", visibility_timeline: "",
                    poorPhoto: true,
                    rejectionReason: error.userMessage
                )
            }
            return nil
        }
    }

    nonisolated static func runAnalysisNetwork(base64: String, apiKey: String) async -> Result<AbAnalysisResponse, ScanError> {
        await MainActor.run { AbScanService.shared }.callRorkAIProxy(base64: base64, profile: nil)
    }

    func analyzeWithBase64(_ base64: String, profile: UserProfile) async -> AbAnalysisResponse? {
        print("[AbScan] analyzeWithBase64 called, base64 length: \(base64.count)")
        lastScanError = nil

        let result = await callRorkAIProxy(base64: base64, profile: profile)

        switch result {
        case .success(let response):
            if response.poorPhoto {
                lastScanError = .badPhoto(response.rejectionReason ?? "Photo unclear")
            }
            return response
        case .failure(let error):
            lastScanError = error
            if case .badPhoto = error {
                return AbAnalysisResponse(
                    upper_abs: 0, lower_abs: 0, obliques: 0,
                    deep_core: 0, symmetry: 0, v_taper: 0,
                    overall_score: 0, body_fat_estimate: 0,
                    abs_structure: "", genetic_potential: "",
                    genetic_potential_score: 0,
                    coach_verdict: "", visibility_timeline: "",
                    poorPhoto: true,
                    rejectionReason: error.userMessage
                )
            }
            return nil
        }
    }

    private func callRorkAIProxy(base64: String, profile: UserProfile?) async -> Result<AbAnalysisResponse, ScanError> {
        let promptText = profile != nil ? buildUserPrompt(profile: profile!) : userPromptTemplate

        do {
            let text = try await AnthropicService.shared.chatWithVision(
                systemPrompt: systemPrompt,
                userText: promptText,
                imageBase64: base64,
                model: "claude-sonnet-4-20250514",
                maxTokens: 2048,
                temperature: 0.2
            )

            print("[AbScan] Parsed text content: \(text.prefix(200))")

            guard let result = Self.parseAnalysisText(text) else {
                return .failure(.apiError("Could not parse analysis"))
            }

            if result.poorPhoto {
                return .failure(.badPhoto(result.rejectionReason ?? "Photo unclear"))
            }

            return .success(result)
        } catch let error as AnthropicError {
            print("[AbScan] Anthropic error: \(error)")
            return .failure(.apiError(error.localizedDescription))
        } catch let error as URLError where error.code == .timedOut {
            print("[AbScan] Timeout error")
            return .failure(.timeout)
        } catch is CancellationError {
            print("[AbScan] Task cancelled")
            return .failure(.networkError("Cancelled"))
        } catch {
            print("[AbScan] Network error: \(error)")
            return .failure(.networkError(error.localizedDescription))
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
        case .moderatelyActive: activityOffset = 6
        case .veryActive: activityOffset = 9
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

        let profileCeiling = Self.computeProfileCeiling(profile: profile, overallScore: clamp(overall))

        return AbAnalysisResponse(
            upper_abs: ua, lower_abs: la, obliques: ob,
            deep_core: dc, symmetry: sy, v_taper: vt,
            overall_score: clamp(overall),
            body_fat_estimate: (bfEstimate * 10).rounded() / 10,
            abs_structure: absStructure,
            genetic_potential: "moderate",
            genetic_potential_score: profileCeiling,
            coach_verdict: "Profile-based estimate. Scan with a photo for a personalised AI analysis.",
            visibility_timeline: "Scan with a photo for a personalised timeline."
        )
    }

    nonisolated private static func computeProfileCeiling(profile: UserProfile, overallScore: Int) -> Int {
        var base = 78

        switch profile.gender {
        case .male: base += 2
        case .female: base -= 3
        case .other: break
        }

        let age = profile.age
        if age < 25 {
            base += 3
        } else if age < 35 {
            base += 1
        } else if age < 45 {
            base -= 2
        } else {
            base -= 5
        }

        switch profile.bodyFatCategory {
        case .lean: base += 4
        case .athletic: base += 2
        case .average: break
        case .aboveAverage: base -= 2
        }

        switch profile.absDescription {
        case .almostThere: base += 5
        case .fourPackVisible: base += 3
        case .topTwoVisible: base += 1
        case .slightOutline: break
        case .barelyVisible: base -= 2
        }

        switch profile.activityLevel {
        case .veryActive: base += 2
        case .moderatelyActive: base += 1
        default: break
        }

        let ceiling = max(base, overallScore + 8)
        return max(55, min(98, ceiling))
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
        let maxDimension: CGFloat = 1024
        let size = image.size
        guard size.width > 0, size.height > 0 else {
            print("[AbScan] ERROR: Image has zero dimensions")
            return nil
        }
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        let newSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))

        var resizedImage: UIImage?
        autoreleasepool {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            resizedImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }

        guard let resized = resizedImage else {
            print("[AbScan] ERROR: Failed to resize image")
            return nil
        }

        let qualities: [CGFloat] = [0.7, 0.5, 0.3]
        for quality in qualities {
            var jpegData: Data?
            autoreleasepool {
                jpegData = resized.jpegData(compressionQuality: quality)
            }
            if let data = jpegData {
                let sizeKB = data.count / 1024
                print("[AbScan] Image base64 size: \(sizeKB)KB at quality \(quality)")
                if sizeKB < 4000 {
                    return data.base64EncodedString()
                }
            }
        }

        var fallbackData: Data?
        autoreleasepool {
            fallbackData = resized.jpegData(compressionQuality: 0.2)
        }
        if let fallback = fallbackData {
            print("[AbScan] Using fallback compression, size: \(fallback.count / 1024)KB")
            return fallback.base64EncodedString()
        }
        print("[AbScan] ERROR: Failed to compress image")
        return nil
    }

    nonisolated private static func parseIntFromJSON(_ json: [String: Any], key: String) -> Int? {
        if let val = json[key] as? Int { return val }
        if let val = json[key] as? Double { return Int(val) }
        if let val = json[key] as? NSNumber { return val.intValue }
        if let val = json[key] as? String, let parsed = Int(val) { return parsed }
        return nil
    }

    nonisolated private static func clampScoreStatic(_ value: Int) -> Int {
        max(45, min(100, value))
    }

    nonisolated private static func clampStatic(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    nonisolated private static func validateAbsStructure(_ claimed: String, upperAbs: Int, lowerAbs: Int, bodyFat: Double) -> String {
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

    nonisolated static func parseAnalysisText(_ text: String) -> AbAnalysisResponse? {
        print("[AbScan] parseAnalysisText called with text length: \(text.count)")

        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = jsonString.range(of: "{"), let end = jsonString.range(of: "}", options: .backwards) {
            jsonString = String(jsonString[start.lowerBound...end.lowerBound])
        }

        guard let data = jsonString.data(using: .utf8) else {
            print("[AbScan] ERROR: Could not convert JSON string to data")
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("[AbScan] ERROR: JSONSerialization failed. JSON string: \(jsonString.prefix(500))")
            return nil
        }

        print("[AbScan] Parsed JSON keys: \(json.keys.sorted())")

        if let errorValue = json["error"] as? String, !errorValue.isEmpty {
            let reason = (json["reason"] as? String) ?? "Photo unclear \u{2014} good lighting, shirt off, front facing camera"
            print("[AbScan] Photo rejected by Claude: \(errorValue) - \(reason)")
            return AbAnalysisResponse(
                upper_abs: 0, lower_abs: 0, obliques: 0,
                deep_core: 0, symmetry: 0, v_taper: 0,
                overall_score: 0, body_fat_estimate: 0,
                abs_structure: "", genetic_potential: "",
                genetic_potential_score: 0,
                coach_verdict: "", visibility_timeline: "",
                poorPhoto: true,
                rejectionReason: reason
            )
        }

        guard let upperAbs = parseIntFromJSON(json, key: "upper_abs"),
              let lowerAbs = parseIntFromJSON(json, key: "lower_abs"),
              let obl = parseIntFromJSON(json, key: "obliques"),
              let deepCore = parseIntFromJSON(json, key: "deep_core"),
              let sym = parseIntFromJSON(json, key: "symmetry"),
              let vTaper = parseIntFromJSON(json, key: "v_taper") else {
            print("[AbScan] ERROR: Failed to parse score fields from JSON")
            return nil
        }

        print("[AbScan] Parsed scores - UA:\(upperAbs) LA:\(lowerAbs) OB:\(obl) DC:\(deepCore) SY:\(sym) VT:\(vTaper)")

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

        let clampedUA = clampScoreStatic(upperAbs)
        let clampedLA = clampScoreStatic(lowerAbs)
        let clampedOB = clampScoreStatic(obl)
        let clampedDC = clampScoreStatic(deepCore)
        let clampedSY = clampScoreStatic(sym)
        let clampedVT = clampScoreStatic(vTaper)
        let computedOverall = Int(round(Double(clampedUA + clampedLA + clampedOB + clampedDC + clampedSY + clampedVT) / 6.0))

        let rawGPS = parseIntFromJSON(json, key: "genetic_potential_score") ?? 0
        let clamped = clampStatic(computedOverall)
        let motivatingFloor = clamped + max(3, Int(Double(100 - clamped) * 0.65))
        let validatedGPS: Int
        if rawGPS >= 55 && rawGPS <= 98 {
            validatedGPS = max(rawGPS, motivatingFloor)
        } else {
            let (_, legacyScore) = ScanResult.parseGeneticPotential(geneticPotential)
            validatedGPS = max(legacyScore, motivatingFloor)
        }
        let finalGPS = max(motivatingFloor, min(98, validatedGPS))

        let validatedStructure = validateAbsStructure(absStructure, upperAbs: clampedUA, lowerAbs: clampedLA, bodyFat: bodyFat)

        return AbAnalysisResponse(
            upper_abs: clampedUA,
            lower_abs: clampedLA,
            obliques: clampedOB,
            deep_core: clampedDC,
            symmetry: clampedSY,
            v_taper: clampedVT,
            overall_score: clampStatic(computedOverall),
            body_fat_estimate: max(8.0, min(30.0, bodyFat)),
            abs_structure: validatedStructure,
            genetic_potential: geneticPotential,
            genetic_potential_score: finalGPS,
            coach_verdict: coachVerdict,
            visibility_timeline: visibilityTimeline
        )
    }
}
