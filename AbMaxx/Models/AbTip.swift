import Foundation

nonisolated struct AbTip: Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
    let category: TipCategory
    let icon: String

    nonisolated enum TipCategory: String, CaseIterable, Sendable {
        case training = "Training"
        case nutrition = "Nutrition"
        case recovery = "Recovery"
        case mindset = "Mindset"

        var icon: String {
            switch self {
            case .training: return "dumbbell.fill"
            case .nutrition: return "fork.knife"
            case .recovery: return "bed.double.fill"
            case .mindset: return "brain.head.profile.fill"
            }
        }
    }

    static let allTips: [AbTip] = [
        AbTip(id: "tip_progressive", title: "Progressive Overload", body: "To build thicker abs, you need to increase difficulty over time. Add reps, slow the tempo, or add resistance to your core exercises every 2 weeks.", category: .training, icon: "chart.line.uptrend.xyaxis"),
        AbTip(id: "tip_vacuum", title: "Stomach Vacuums", body: "Practice stomach vacuums daily to tighten your transverse abdominis. This deep core muscle acts like a natural corset and makes your waist appear smaller.", category: .training, icon: "wind"),
        AbTip(id: "tip_protein_timing", title: "Protein Timing Matters", body: "Consume 20-40g of protein within 2 hours of your ab workout. This maximizes muscle protein synthesis and helps build thicker, more visible abs.", category: .nutrition, icon: "clock.fill"),
        AbTip(id: "tip_deficit", title: "Calorie Deficit for Visibility", body: "Abs are made in the kitchen. You need to be in a calorie deficit to reduce body fat and reveal your ab muscles. Aim for 300-500 calorie deficit.", category: .nutrition, icon: "flame.fill"),
        AbTip(id: "tip_sleep", title: "Sleep Is Non-Negotiable", body: "Growth hormone peaks during deep sleep. Get 7-9 hours to maximize recovery and fat burning. Poor sleep increases cortisol which stores belly fat.", category: .recovery, icon: "moon.fill"),
        AbTip(id: "tip_stress", title: "Manage Cortisol", body: "High stress = high cortisol = belly fat storage. Practice deep breathing, meditation, or walks in nature to keep cortisol low and abs visible.", category: .recovery, icon: "heart.fill"),
        AbTip(id: "tip_consistency", title: "Consistency Over Intensity", body: "15 minutes of core work 5 days a week beats 1 hour once a week. Abs respond to frequency. Build the daily habit.", category: .mindset, icon: "calendar.badge.checkmark"),
        AbTip(id: "tip_patience", title: "Trust The Process", body: "Visible abs take 8-16 weeks of consistent effort. Don't quit at week 3. The results are exponential — most progress happens in the final weeks.", category: .mindset, icon: "hourglass"),
        AbTip(id: "tip_water", title: "Hydration for Definition", body: "Drinking enough water reduces water retention and bloating. Aim for 3-4 liters daily. Dehydration actually makes you look softer, not leaner.", category: .nutrition, icon: "drop.fill"),
        AbTip(id: "tip_compound", title: "Don't Skip Compound Lifts", body: "Squats, deadlifts, and overhead presses activate your core more than most isolation exercises. Build a strong foundation with heavy compounds.", category: .training, icon: "figure.strengthtraining.traditional"),
        AbTip(id: "tip_breathing", title: "Breathe Into Your Abs", body: "Proper breathing during ab exercises doubles the activation. Exhale forcefully on the contraction, inhale on the stretch. Never hold your breath.", category: .training, icon: "lungs.fill"),
        AbTip(id: "tip_fiber", title: "Fiber Fights Bloating", body: "25-35g of fiber daily keeps your digestive system running smooth and reduces the bloating that hides your abs. Eat vegetables, oats, and berries.", category: .nutrition, icon: "leaf.fill"),
        AbTip(id: "tip_foam", title: "Foam Roll Your Hip Flexors", body: "Tight hip flexors pull your pelvis forward and push your belly out. Foam rolling and stretching daily can instantly make your abs look better.", category: .recovery, icon: "figure.flexibility"),
        AbTip(id: "tip_photos", title: "Take Progress Photos", body: "Your mirror lies. Weekly progress photos in the same lighting and angle are the most accurate way to track ab development. Trust the camera.", category: .mindset, icon: "camera.fill"),
    ]

    static func dailyTip(for dayIndex: Int) -> AbTip {
        allTips[dayIndex % allTips.count]
    }

    static func tips(for category: TipCategory) -> [AbTip] {
        allTips.filter { $0.category == category }
    }
}
