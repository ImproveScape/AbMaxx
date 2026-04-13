import Foundation

nonisolated struct MindsetTask: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let description: String
    let type: MindsetType

    nonisolated enum MindsetType: String, Codable, Sendable {
        case visualization = "Visualization"
        case manifestation = "Manifestation"

        var icon: String {
            switch self {
            case .visualization: "eye.fill"
            case .manifestation: "bolt.fill"
            }
        }
    }

    static let pairs: [(MindsetTask, MindsetTask)] = [
        (MindsetTask(id: "vis_1", title: "Visualize Your Six-Pack", description: "Close your eyes for 2 minutes. Picture yourself with defined, chiseled abs. Feel the confidence.", type: .visualization),
         MindsetTask(id: "man_1", title: "Claim Your 6-Pack", description: "Say out loud: 'I am building the body I deserve. My abs are getting more defined every day.'", type: .manifestation)),
        (MindsetTask(id: "vis_2", title: "See the Transformation", description: "Imagine looking in the mirror 30 days from now. Your abs are visible. You feel unstoppable.", type: .visualization),
         MindsetTask(id: "man_2", title: "Set the Standard", description: "Write down: 'I don't skip workouts. I am disciplined. I am becoming my best self.'", type: .manifestation)),
        (MindsetTask(id: "vis_3", title: "Beach Confidence", description: "Picture yourself at the beach, shirt off, turning heads. Feel that energy.", type: .visualization),
         MindsetTask(id: "man_3", title: "Own Your Power", description: "Repeat 3x: 'Every rep brings me closer. Every meal is fuel. I am in control.'", type: .manifestation)),
        (MindsetTask(id: "vis_4", title: "Morning Mirror Moment", description: "Visualize waking up, looking in the mirror, and seeing clear ab definition for the first time.", type: .visualization),
         MindsetTask(id: "man_4", title: "Declare Your Discipline", description: "Say: 'I choose discipline over comfort. My future self thanks me for today's effort.'", type: .manifestation)),
        (MindsetTask(id: "vis_5", title: "Feel the Burn", description: "Close your eyes. Feel the workout burn. Associate that burn with progress and growth.", type: .visualization),
         MindsetTask(id: "man_5", title: "Embrace the Grind", description: "Write: 'The grind is temporary. The results are permanent. I am built different.'", type: .manifestation)),
        (MindsetTask(id: "vis_6", title: "Compliment Scene", description: "Imagine someone you respect complimenting your physique. How does that feel?", type: .visualization),
         MindsetTask(id: "man_6", title: "I Am Worthy", description: "Repeat: 'I deserve this body. I am putting in the work. Results are inevitable.'", type: .manifestation)),
        (MindsetTask(id: "vis_7", title: "Before & After", description: "Visualize your before photo next to your future after photo. See the dramatic difference.", type: .visualization),
         MindsetTask(id: "man_7", title: "No Excuses", description: "Declare: 'Excuses are for the average. I am extraordinary. I finish what I start.'", type: .manifestation)),
        (MindsetTask(id: "vis_8", title: "Athletic Performance", description: "See yourself moving with power and agility. Your core is your foundation of strength.", type: .visualization),
         MindsetTask(id: "man_8", title: "Built to Last", description: "Say: 'I am not building a temporary body. I am creating a lifestyle of excellence.'", type: .manifestation)),
        (MindsetTask(id: "vis_9", title: "Flex in the Mirror", description: "Imagine flexing and seeing every ab muscle defined and separated. Pure satisfaction.", type: .visualization),
         MindsetTask(id: "man_9", title: "Relentless Focus", description: "Write: 'I don't negotiate with laziness. I show up every single day, no matter what.'", type: .manifestation)),
        (MindsetTask(id: "vis_10", title: "Goal Achievement", description: "Picture the exact moment you hit your abs goal. The celebration, the pride, the achievement.", type: .visualization),
         MindsetTask(id: "man_10", title: "Champion Mindset", description: "Repeat: 'Champions are made in the dark. When no one is watching, I am still working.'", type: .manifestation)),
    ]

    static func dailyPair(for dayIndex: Int) -> (MindsetTask, MindsetTask) {
        pairs[dayIndex % pairs.count]
    }
}
