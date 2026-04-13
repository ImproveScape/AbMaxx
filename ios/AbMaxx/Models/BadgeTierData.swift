import SwiftUI

struct RankTier: Identifiable {
    let id: Int
    let name: String
    let color1: Color
    let color2: Color
    let minScore: Int
    let imageURL: String

    static let allTiers: [RankTier] = [
        RankTier(id: 0,  name: "Starter",     color1: Color(red: 0.35, green: 0.40, blue: 0.55), color2: Color(red: 0.25, green: 0.30, blue: 0.45), minScore: 45, imageURL: "https://r2-pub.rork.com/generated-images/31f3d1cc-ff49-459d-8c47-436113eeb2b2.png"),
        RankTier(id: 1,  name: "Foundation",   color1: Color(red: 0.38, green: 0.44, blue: 0.62), color2: Color(red: 0.28, green: 0.34, blue: 0.52), minScore: 47, imageURL: "https://r2-pub.rork.com/generated-images/3cb50b8a-f8ee-4ecd-82bc-57eb05e3d9cf.png"),
        RankTier(id: 2,  name: "Rising",       color1: Color(red: 0.32, green: 0.46, blue: 0.72), color2: Color(red: 0.22, green: 0.36, blue: 0.60), minScore: 49, imageURL: "https://r2-pub.rork.com/generated-images/f358ac07-b612-491a-bf99-01d957d1a681.png"),
        RankTier(id: 3,  name: "Defined",      color1: Color(red: 0.28, green: 0.48, blue: 0.82), color2: Color(red: 0.18, green: 0.38, blue: 0.70), minScore: 53, imageURL: "https://r2-pub.rork.com/generated-images/2962c2a1-adfe-49f3-a89b-6e92387a1cf0.png"),
        RankTier(id: 4,  name: "Sculpted",     color1: Color(red: 0.25, green: 0.50, blue: 0.92), color2: Color(red: 0.18, green: 0.40, blue: 0.80), minScore: 56, imageURL: "https://r2-pub.rork.com/generated-images/11f99cb1-4fdf-4300-a415-98810dc606e3.png"),
        RankTier(id: 5,  name: "Chiseled",     color1: Color(red: 0.30, green: 0.55, blue: 1.00), color2: Color(red: 0.20, green: 0.42, blue: 0.88), minScore: 59, imageURL: "https://r2-pub.rork.com/generated-images/2bd8bb78-92e1-48d0-a86c-6ff3f62858e9.png"),
        RankTier(id: 6,  name: "Forged",       color1: Color(red: 0.35, green: 0.58, blue: 1.00), color2: Color(red: 0.22, green: 0.45, blue: 0.90), minScore: 63, imageURL: "https://r2-pub.rork.com/generated-images/83d206a9-afac-4605-89a3-3f07ee684d22.png"),
        RankTier(id: 7,  name: "Refined",      color1: Color(red: 0.40, green: 0.62, blue: 1.00), color2: Color(red: 0.28, green: 0.50, blue: 0.92), minScore: 66, imageURL: "https://r2-pub.rork.com/generated-images/d6d2440e-1888-4217-8630-20d85d86c902.png"),
        RankTier(id: 8,  name: "Elite",        color1: Color(red: 0.45, green: 0.68, blue: 1.00), color2: Color(red: 0.30, green: 0.55, blue: 0.95), minScore: 69, imageURL: "https://r2-pub.rork.com/generated-images/1f1a65e3-5e9b-4314-b2c2-314613e50c98.png"),
        RankTier(id: 9,  name: "Prime",        color1: Color(red: 0.50, green: 0.72, blue: 1.00), color2: Color(red: 0.35, green: 0.58, blue: 0.95), minScore: 74, imageURL: "https://r2-pub.rork.com/generated-images/c4d4914c-8c49-4767-be1f-b6bf27850e59.png"),
        RankTier(id: 10, name: "Apex",         color1: Color(red: 0.55, green: 0.75, blue: 1.00), color2: Color(red: 0.38, green: 0.60, blue: 0.98), minScore: 78, imageURL: "https://r2-pub.rork.com/generated-images/411a5021-35eb-4912-a06f-e675f75881ef.png"),
        RankTier(id: 11, name: "Titan",        color1: Color(red: 0.60, green: 0.78, blue: 1.00), color2: Color(red: 0.42, green: 0.64, blue: 0.98), minScore: 82, imageURL: "https://r2-pub.rork.com/generated-images/852aa313-8be5-4c4d-b7a2-ff565baf0a77.png"),
        RankTier(id: 12, name: "Diamond",      color1: Color(red: 0.65, green: 0.82, blue: 1.00), color2: Color(red: 0.48, green: 0.68, blue: 0.98), minScore: 86, imageURL: "https://r2-pub.rork.com/generated-images/f2ac56cf-6a5c-4ae5-a1c8-76311ecc256d.png"),
        RankTier(id: 13, name: "Master",       color1: Color(red: 0.72, green: 0.85, blue: 1.00), color2: Color(red: 0.52, green: 0.72, blue: 1.00), minScore: 90, imageURL: "https://r2-pub.rork.com/generated-images/ffd82824-af89-4020-9ee6-944ea34c1a2b.png"),
        RankTier(id: 14, name: "Legend",       color1: Color(red: 0.78, green: 0.88, blue: 1.00), color2: Color(red: 0.58, green: 0.76, blue: 1.00), minScore: 93, imageURL: "https://r2-pub.rork.com/generated-images/6eba34d3-2580-4930-b505-ee819e38e4b7.png"),
        RankTier(id: 15, name: "Icon",         color1: Color(red: 0.85, green: 0.92, blue: 1.00), color2: Color(red: 0.65, green: 0.80, blue: 1.00), minScore: 96, imageURL: "https://r2-pub.rork.com/generated-images/67a3b934-15f4-426e-82d4-5afa5a33d90b.png"),
        RankTier(id: 16, name: "Prestige",     color1: Color(red: 0.92, green: 0.96, blue: 1.00), color2: Color(red: 0.75, green: 0.86, blue: 1.00), minScore: 98, imageURL: "https://r2-pub.rork.com/generated-images/087583ea-20c9-490b-95a4-7dcca86193da.png"),
    ]

    static func currentTierIndex(for score: Int) -> Int {
        var idx = 0
        for (i, tier) in allTiers.enumerated() {
            if score >= tier.minScore { idx = i }
        }
        return idx
    }

    static func tier(for score: Int) -> RankTier {
        allTiers[currentTierIndex(for: score)]
    }

    var description: String {
        switch id {
        case 0: return "The first step on your journey. You've started building a foundation — keep pushing to develop your core."
        case 1: return "Your consistency is showing. Your core is waking up and starting to take shape."
        case 2: return "You're gaining momentum. Dedication is paying off — real progress is within reach."
        case 3: return "Your abs are developing real definition and structure. A new level of commitment."
        case 4: return "Your symmetry and definition are improving noticeably. The work is speaking for itself."
        case 5: return "Sharp, clean lines emerging. Your core strength and aesthetics are impressive."
        case 6: return "Your abs show clear definition, strong obliques, and balanced development."
        case 7: return "Exceptional core development. You stand out with thick, well-defined abdominals."
        case 8: return "Very few reach this level — your dedication to training is world-class."
        case 9: return "Your abs are sculpted, symmetrical, and aesthetically near-perfect."
        case 10: return "Razor-sharp definition with flawless proportions emerging."
        case 11: return "A force of nature. You've reached a level most only dream of."
        case 12: return "Razor-sharp definition with flawless proportions. Truly exceptional."
        case 13: return "Your physique represents years of disciplined training and nutrition."
        case 14: return "Among the absolute best. Your core is a masterpiece of human performance."
        case 15: return "You've surpassed nearly everyone. Your core development is iconic."
        case 16: return "The pinnacle. Absolute perfection in core development."
        default: return "Keep training to unlock this rank."
        }
    }

    var topPercent: String {
        switch id {
        case 0: return "45%"
        case 1: return "38%"
        case 2: return "32%"
        case 3: return "26%"
        case 4: return "21%"
        case 5: return "17%"
        case 6: return "13%"
        case 7: return "10%"
        case 8: return "8%"
        case 9: return "5.5%"
        case 10: return "4%"
        case 11: return "3%"
        case 12: return "2.5%"
        case 13: return "2%"
        case 14: return "1.5%"
        case 15: return "0.5%"
        case 16: return "0.1%"
        default: return "50%"
        }
    }

    var perks: [String] {
        switch id {
        case 0, 1, 2:
            return ["Beginner exercises unlocked", "Core foundation tracking", "Basic scan analysis"]
        case 3, 4, 5:
            return ["Intermediate routines", "Enhanced scan detail", "Progress trend analysis"]
        case 6, 7, 8:
            return ["Advanced exercises", "Detailed muscle mapping", "Personalized weak-point targeting"]
        case 9, 10, 11:
            return ["Elite training programs", "Deep symmetry analysis", "Recovery optimization"]
        case 12:
            return ["Pro-level routines", "Muscle fiber analysis", "Peak performance tracking"]
        case 13:
            return ["Master-tier challenges", "Full genetic potential report", "Advanced periodization"]
        case 14:
            return ["Legend-exclusive challenges", "Competition-ready analysis", "Elite nutrition protocols"]
        case 15:
            return ["Icon challenges", "Ultimate physique blueprint", "Iconic status perks"]
        case 16:
            return ["All features unlocked", "Legendary status", "Prestige-exclusive content"]
        default:
            return ["Keep training to discover perks"]
        }
    }
}

struct RankBadgeImage: View {
    let tier: RankTier
    let isUnlocked: Bool
    var size: CGFloat = 52

    var body: some View {
        AsyncImage(url: URL(string: tier.imageURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .brightness(isUnlocked ? 0 : -0.45)
                    .saturation(isUnlocked ? 1.0 : 0.4)
            case .failure:
                fallbackPlaceholder
            default:
                ProgressView()
                    .frame(width: size, height: size)
            }
        }
    }

    private var fallbackPlaceholder: some View {
        Circle()
            .fill(AppTheme.cardSurfaceElevated)
            .frame(width: size * 0.85, height: size * 0.85)
            .overlay(
                Circle()
                    .strokeBorder(AppTheme.border.opacity(0.4), lineWidth: 1.5)
            )
            .frame(width: size, height: size)
    }
}
