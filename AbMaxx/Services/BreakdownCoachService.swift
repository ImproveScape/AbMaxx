import Foundation

@MainActor
class BreakdownCoachService {
    static let shared = BreakdownCoachService()


    func generateBreakdownTexts(scan: ScanResult, weekNumber: Int) async -> (coachText: String, weeklyAction: String, structureNote: String) {
        let bf = String(format: "%.1f", scan.estimatedBodyFat)
        let context = """
        Scores: Upper Abs \(scan.upperAbsScore), Lower Abs \(scan.lowerAbsScore), \
        Obliques \(scan.obliquesScore), Deep Core \(scan.deepCoreScore), \
        V-Taper \(scan.frame), Symmetry \(scan.symmetry), Overall \(scan.overallScore). \
        Body fat: \(bf)%. Structure: \(scan.absStructure.rawValue). \
        Insertion type: \(scan.insertionType). Dominant zone: \(scan.dominantZone). Week \(weekNumber).
        """

        async let coachResult = fetchCoachParagraph(context: context, weekNumber: weekNumber)
        async let structureResult = fetchStructureNote(structure: scan.absStructure, insertionType: scan.insertionType)

        let coach = await coachResult
        let structure = await structureResult

        return (coach.paragraph, coach.action, structure)
    }

    private func fetchCoachParagraph(context: String, weekNumber: Int) async -> (paragraph: String, action: String) {
        let systemPrompt = """
        You are an elite sports physiologist doing a clinical read of someone's ab scan. They need to feel like you see THEIR exact body — not anyone else's. \
        Write exactly TWO things, separated by |||. \
        FIRST: A 3-4 sentence clinical assessment that makes them think "holy shit, this is exactly me." \
        Use precise anatomical language. Reference their EXACT scores. \
        - Name what's physically visible on their strongest zone (e.g. "rectus segments separating above the navel", "oblique striations cutting in from the iliac crest"). \
        - Name what's anatomically missing on their weakest zone (e.g. "zero linea alba definition below the umbilicus", "transverse abdominis isn't pulling the waist in — your lower belly still rounds forward"). \
        - Be blunt about what this means for how they look right now. Not mean, but honest. Like a doctor who respects them enough to tell the truth. \
        - End with ONE sentence on the specific anatomical change that will happen when they fix the weak zone. Paint the visual. \
        Do NOT use generic phrases like "keep it up" or "stay consistent" or "you're doing great." \
        SECOND: One hyper-specific action for this week — exact exercise name, exact rep count, exact tempo (e.g. "3-1-3"), and WHY this targets their specific weak point anatomically. \
        Format: verdict paragraph|||specific action sentence
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
            return (text, "Focus on your weakest zone this week.")
        } catch {
            return (fallbackCoachText(context: context), "Focus on your weakest zone this week.")
        }
    }

    private func fetchStructureNote(structure: AbsStructure, insertionType: String) async -> String {
        let systemPrompt = """
        You are a fitness anatomy expert. Write exactly ONE sentence (max 2 lines) explaining what \
        a \(insertionType) insertion type with \(structure.rawValue) abs means for how the user's abs \
        will look when lean. Be specific and encouraging. No fluff.
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Explain my ab structure."]
        ]

        do {
            return try await sendChat(messages: messages)
        } catch {
            return fallbackStructureNote(structure: structure, insertionType: insertionType)
        }
    }

    private func sendChat(messages: [[String: String]]) async throws -> String {
        var systemPrompt = ""
        var apiMessages: [[String: String]] = []

        for msg in messages {
            if msg["role"] == "system" {
                systemPrompt = msg["content"] ?? ""
            } else {
                apiMessages.append(msg)
            }
        }

        let text = try await AnthropicService.shared.chat(
            systemPrompt: systemPrompt,
            messages: apiMessages,
            model: "claude-sonnet-4-20250514",
            maxTokens: 1024,
            temperature: 0.7
        )

        if text.isEmpty {
            throw CoachError.emptyResponse
        }

        return text
    }

    private func fallbackCoachText(context: String) -> String {
        "Your scan data tells the full story. The scores don't lie — where you're strong, you're genuinely strong, and where you're weak, that's where the biggest visual gains are hiding. Every percentage point of body fat you drop from here reveals dramatically more definition. Stay locked in."
    }

    private func fallbackStructureNote(structure: AbsStructure, insertionType: String) -> String {
        switch structure {
        case .sixPack, .eightPack:
            return "Your \(insertionType.lowercased()) insertion pattern means clean, symmetrical blocks that pop at low body fat — the classic look."
        case .asymmetric:
            return "Your offset insertion creates a distinctive staggered look that many top athletes share — at low body fat it looks striking and unique."
        case .fourPack:
            return "Your \(insertionType.lowercased()) insertion means a razor-sharp four-pack at low body fat, which looks more impressive than a soft six-pack."
        default:
            return "Your structure is still emerging — as body fat drops, your unique insertion pattern will define how your abs look."
        }
    }
}
