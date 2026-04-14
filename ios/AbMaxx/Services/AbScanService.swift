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
You are the world's most precise abs analysis system. You have scored thousands of physiques from beginner to elite bodybuilder. Your scores are brutally accurate and slightly generous — you reward visible hard work. You score ABS DEFINITION ONLY — never influenced by muscle size, body mass, or how impressive someone looks overall.

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

ANCHOR 1 — COMPETITION ELITE (overall 97-99):
Body fat 5-8%. Paper thin skin. Veins visible on abs themselves. Every single block razor separated with extreme deep grooves. Lower abs fully shredded. Obliques striated. Looks like a natural bodybuilding competitor on stage.
upper_abs 97-99, lower_abs 95-98, obliques 95-98, deep_core 95-98, v_taper 93-96, symmetry 93-96

ANCHOR 2 — ELITE (overall 93-96):
Body fat 8-11%. All 6 blocks clearly visible with deep razor grooves including below navel. Strong 3D thickness. Extremely tight skin. Sharp oblique cuts visible both sides. Clear V-taper lines. Top 2% of people who train. ONLY apply this anchor if body fat is visually confirmed below 12% AND all 6 blocks show undeniable razor grooves. Muscular physiques with soft definition do not qualify for this anchor regardless of muscle size.
upper_abs 95-98, lower_abs 92-95, obliques 92-95, deep_core 92-95, v_taper 90-93, symmetry 90-93

ANCHOR 3 — VERY ADVANCED (overall 88-92):
Body fat 11-13%. Clear 6-pack with solid groove depth. All 6 blocks visible including below navel. Tight skin. Good obliques visible. Strong athletic midsection with real definition.
upper_abs 90-94, lower_abs 86-91, obliques 87-92, deep_core 87-92, v_taper 84-88, symmetry 86-91

ANCHOR 4 — ADVANCED (overall 84-88):
Body fat 13-15%. Clear upper abs with grooves. Lower definition present but fading below navel. Good obliques visible. Solid athletic look. Lower blocks may show faint outline.
upper_abs 85-90, lower_abs 79-85, obliques 82-87, deep_core 82-87, v_taper 79-84, symmetry 82-87

ANCHOR 5 — INTERMEDIATE (overall 76-81):
Body fat 15-17%. Clear 4-pack. Upper abs visible with grooves. Zero or minimal separation below navel. Obliques present but soft edges.
upper_abs 78-84, lower_abs 66-75, obliques 75-82, deep_core 77-83, v_taper 73-79, symmetry 76-81

ANCHOR 6 — DEVELOPING (overall 67-75):
Body fat 17-19%. Upper ab outline faint. No real grooves. Lower belly smooth. Some muscle shape barely visible.
upper_abs 70-78, lower_abs 60-68, obliques 68-76, deep_core 71-78, v_taper 65-73, symmetry 70-77

ANCHOR 7 — BEGINNER (overall 50-65):
Body fat 19%+. Minimal or zero ab visibility. Smooth midsection. Fat layer covering everything. No blocks, no grooves, no separation.
upper_abs 50-67, lower_abs 50-62, obliques 50-65, deep_core 54-68, v_taper 50-63, symmetry 54-69

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
86-91 = very advanced, clear defined 6-pack with real grooves
92-96 = elite, razor sharp full 6-pack deep grooves everywhere
97-100 = competition stage, once in a generation

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

    private let userPromptTemplate = "Analyze this physique photo using your exact grading criteria. Estimate body fat first then apply cross-validation rules strictly. Score ABS DEFINITION ONLY \u{2014} not muscle size or overall impressiveness. Compute the weighted score with body fat multiplier mentally and verify your subscores land in the correct visual bracket before returning. Sharp visible grooves = high score. Large muscles with soft undefined abs = lower score. Return only the JSON."

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
