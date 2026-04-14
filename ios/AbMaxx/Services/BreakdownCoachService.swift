import Foundation

@MainActor
class BreakdownCoachService {
    static let shared = BreakdownCoachService()


    func generateBreakdownTexts(scan: ScanResult, weekNumber: Int, profile: UserProfile) async -> (coachText: String, weeklyAction: String, structureNote: String) {
        let bf = String(format: "%.1f", scan.estimatedBodyFat)
        let bfToGoal = bfGapToSixPack(bf: scan.estimatedBodyFat)
        let weakZone = weakestZoneName(scan: scan)
        let weakScore = weakestZoneScore(scan: scan)
        let strongZone = strongestZoneName(scan: scan)
        let strongScore = strongestZoneScore(scan: scan)
        let gap = strongScore - weakScore

        let structureMeaning = geneticStructureMeaning(scan: scan)
        let goalStr = profile.goal.rawValue
        let ageStr = "\(profile.age)"
        let weightStr = String(format: "%.0f", profile.weightInLbs)
        let activityStr = profile.activityLevel.rawValue
        let freqStr = profile.absTrainingFrequency.rawValue
        let daysStr = "\(profile.daysOnProgram)"
        let genderStr = profile.gender.rawValue
        let gpStr = scan.geneticPotentialLevel.rawValue

        let context = """
        USER PROFILE:
        Gender: \(genderStr), Age: \(ageStr), Weight: \(weightStr) lbs
        Goal: \(goalStr), Activity: \(activityStr)
        Abs training frequency: \(freqStr), Days on program: \(daysStr)
        Genetic potential: \(gpStr)

        SCAN DATA (Week \(weekNumber)):
        Overall: \(scan.overallScore)/100
        Upper Abs: \(scan.upperAbsScore), Lower Abs: \(scan.lowerAbsScore), Obliques: \(scan.obliquesScore), Deep Core: \(scan.deepCoreScore)
        V-Taper: \(scan.frame), Symmetry: \(scan.symmetry)
        Body fat: \(bf)% (\(bfToGoal) away from visible abs threshold)
        Abs structure: \(scan.absStructure.rawValue), Insertion: \(scan.insertionType)
        Genetic structure meaning: \(structureMeaning)
        Dominant zone: \(strongZone) (\(strongScore)), Weakest zone: \(weakZone) (\(weakScore)), Gap: \(gap) pts
        """

        async let coachResult = fetchCoachParagraph(context: context, scan: scan, profile: profile)
        async let structureResult = fetchStructureNote(structure: scan.absStructure, insertionType: scan.insertionType, bf: scan.estimatedBodyFat, geneticPotential: gpStr)

        let coach = await coachResult
        let structure = await structureResult

        return (coach.paragraph, coach.action, structure)
    }

    private func fetchCoachParagraph(context: String, scan: ScanResult, profile: UserProfile) async -> (paragraph: String, action: String) {
        let weakZone = weakestZoneName(scan: scan)
        let strongZone = strongestZoneName(scan: scan)
        let bf = scan.estimatedBodyFat

        let systemPrompt = """
        You are an elite sports physiologist and body composition coach doing a private clinical read of one specific person's ab scan. \
        This person needs to feel like you are reading THEIR exact body — not a template, not anyone else. \
        You have their full biometric profile AND their zone-by-zone scan scores. Use both.

        Write exactly TWO things, separated by |||.

        FIRST — A 3–4 sentence personal clinical assessment. Rules:
        - Open by naming what their \(strongZone) is physically showing right now — use anatomical language. E.g. "rectus abdominis segments separating cleanly above the navel," or "upper fibers showing clear linea alba groove with good tendinous inscription depth."
        - Name what is anatomically absent or underdeveloped in their \(weakZone) right now. Be precise: what specifically is not visible, what muscle is not firing, what fat layer is covering it.
        - Connect their body fat (\(String(format: "%.1f", bf))%) to what will unlock next. Be specific about what physically changes at what body fat threshold.
        - If their genetic potential is high or elite, tell them — and tell them exactly what that means for their ceiling.
        - Close with ONE sentence painting a vivid visual of what they will look like when the weakest zone comes up. Make it aspirational but anatomically grounded.
        - NEVER use generic phrases like "keep it up," "great progress," "stay consistent," or "you're doing well."
        - Do NOT reference "the scan" or "your scan data." Write as if you just looked at their body.

        SECOND — One hyper-specific exercise prescription for their weakest zone:
        - Name the exact exercise, exact sets x reps, exact tempo (e.g. "3-0-2"), and exactly WHY this targets their specific anatomical weak point.
        - Reference their \(weakZone) score and what the exercise will physically change.
        Format: [paragraph]|||[specific action]
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": context]
        ]

        do {
            let text = try await sendChat(messages: messages)
            let parts = text.components(separatedBy: "|||")
            if parts.count >= 2 {
                return (parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
                        parts[1].trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return (text.trimmingCharacters(in: .whitespacesAndNewlines), fallbackAction(scan: scan))
        } catch {
            return (fallbackCoachText(scan: scan, profile: profile), fallbackAction(scan: scan))
        }
    }

    private func fetchStructureNote(structure: AbsStructure, insertionType: String, bf: Double, geneticPotential: String) async -> String {
        let systemPrompt = """
        You are a fitness anatomy expert. Write exactly ONE sentence (max 20 words) that tells someone with \(insertionType) insertions and \(structure.rawValue) abs exactly what their abs will look like when lean. Be vivid, specific, and encouraging. No fluff. No generic statements.
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Describe my \(structure.rawValue) abs with \(insertionType) insertions at low body fat."]
        ]

        do {
            return try await sendChat(messages: messages)
        } catch {
            return fallbackStructureNote(structure: structure, insertionType: insertionType)
        }
    }

    private func sendChat(messages: [[String: String]]) async throws -> String {
        var systemPrompt = ""
        var apiMessages: [[String: Any]] = []

        for msg in messages {
            if msg["role"] == "system" {
                systemPrompt = msg["content"] ?? ""
            } else {
                apiMessages.append(msg as [String: Any])
            }
        }

        let allMessages: [[String: Any]]
        if !systemPrompt.isEmpty {
            allMessages = [["role": "system", "content": systemPrompt]] + apiMessages
        } else {
            allMessages = apiMessages
        }

        let text = try await OpenAIService.shared.chat(
            model: "gpt-4o",
            messages: allMessages,
            temperature: 0.7,
            maxTokens: 1024
        )

        if text.isEmpty {
            throw CoachError.emptyResponse
        }

        return text
    }

    private func weakestZoneName(scan: ScanResult) -> String {
        let zones: [(String, Int)] = [
            ("Upper Abs", scan.upperAbsScore),
            ("Lower Abs", scan.lowerAbsScore),
            ("Obliques", scan.obliquesScore),
            ("Deep Core", scan.deepCoreScore)
        ]
        return zones.min(by: { $0.1 < $1.1 })?.0 ?? "Lower Abs"
    }

    private func weakestZoneScore(scan: ScanResult) -> Int {
        [scan.upperAbsScore, scan.lowerAbsScore, scan.obliquesScore, scan.deepCoreScore].min() ?? 0
    }

    private func strongestZoneName(scan: ScanResult) -> String {
        let zones: [(String, Int)] = [
            ("Upper Abs", scan.upperAbsScore),
            ("Lower Abs", scan.lowerAbsScore),
            ("Obliques", scan.obliquesScore),
            ("Deep Core", scan.deepCoreScore)
        ]
        return zones.max(by: { $0.1 < $1.1 })?.0 ?? "Upper Abs"
    }

    private func strongestZoneScore(scan: ScanResult) -> Int {
        [scan.upperAbsScore, scan.lowerAbsScore, scan.obliquesScore, scan.deepCoreScore].max() ?? 0
    }

    private func bfGapToSixPack(bf: Double) -> String {
        let target = 12.0
        if bf <= target { return "already there" }
        let gap = bf - target
        return String(format: "%.1f%%", gap)
    }

    private func geneticStructureMeaning(scan: ScanResult) -> String {
        switch scan.absStructure {
        case .eightPack: return "Rare eight-segment structure — more visible blocks than 97% of people"
        case .sixPack: return "Classic symmetrical six-pack structure — segments will pop cleanly when lean"
        case .fourPack: return "Short tendon insertions — upper four will be razor-sharp, lower region stays smooth"
        case .twoPack: return "High insertion point — strong upper ab pop, lower section genetically smooth"
        case .asymmetric: return "Offset tendon insertions — distinctive staggered look, highly unique"
        case .flat: return "Insertions still emerging — structure will clarify as body fat drops"
        }
    }

    private func fallbackCoachText(scan: ScanResult, profile: UserProfile) -> String {
        let weak = weakestZoneName(scan: scan)
        let weakScore = weakestZoneScore(scan: scan)
        let strong = strongestZoneName(scan: scan)
        let strongScore = strongestZoneScore(scan: scan)
        let bf = String(format: "%.0f", scan.estimatedBodyFat)

        return "Your \(strong) at \(strongScore) is showing real development — the muscle belly is there. But \(weak) at \(weakScore) is the gap that's keeping your midsection from reading as complete. At \(bf)% body fat, you have the structure, it's just behind a layer. Every week of locked-in training closes that \(strongScore - weakScore)-point gap and brings your entire midsection into frame."
    }

    private func fallbackAction(scan: ScanResult) -> String {
        let weak = weakestZoneName(scan: scan)
        switch weak {
        case "Lower Abs":
            return "Dead bug: 4 sets × 10 reps each side, 3-1-3 tempo. Arms and opposite leg lower simultaneously — forces the transverse abdominis to stabilize the pelvis, hitting the exact lower fibers that aren't activating."
        case "Obliques":
            return "Pallof press: 3 sets × 12 reps each side, 2-1-2 tempo. The anti-rotation demand forces your external obliques and QL to fire isometrically — directly targeting the zone that's lagging."
        case "Deep Core":
            return "Hollow body hold: 4 sets × 30 seconds, full exhale at the top. Forces the transverse abdominis to compress the entire core cylinder — this is the foundational strength your deep core is missing."
        default:
            return "Cable crunch: 4 sets × 12 reps, 3-1-2 tempo. Spine flexion under load targets the upper rectus directly — the only way to add density to the visible segments above the navel."
        }
    }

    private func fallbackStructureNote(structure: AbsStructure, insertionType: String) -> String {
        switch structure {
        case .eightPack:
            return "Eight blocks will cut in symmetrically from sternum to pelvis — an extremely rare genetic structure."
        case .sixPack:
            return "Six clean, stacked segments will emerge symmetrically as body fat drops — the classic athletic look."
        case .asymmetric:
            return "Offset blocks create a striking, distinctive look that stands apart from cookie-cutter symmetry."
        case .fourPack:
            return "Upper four segments will be razor-sharp and deep — lower region stays smooth by design."
        case .twoPack:
            return "Strong upper ab pop with a naturally smooth lower section — defined and powerful looking."
        default:
            return "Your structure will reveal itself clearly as body fat drops — stay the course."
        }
    }
}
