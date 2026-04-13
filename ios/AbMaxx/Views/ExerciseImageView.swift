import SwiftUI

struct ExerciseImageView: View {
    let exercise: Exercise
    let size: CGFloat
    var regionScore: Int = 0

    private var regionColor: Color {
        AppTheme.subscoreColor(for: regionScore)
    }

    private var exerciseIcon: String {
        switch exercise.id {
        case "plank", "side_plank": return "figure.core.training"
        case "dead_bug", "bird_dog": return "figure.flexibility"
        case "hollow_hold", "l_sit_hold": return "figure.gymnastics"
        case "stomach_vacuum": return "wind"
        case "slow_mountain_climbers", "mountain_climbers", "cross_body_mountain_climbers": return "figure.highintensity.intervaltraining"
        case "crunches", "decline_crunch", "crunch_hold", "weighted_crunch", "pulse_crunches", "oblique_crunch": return "figure.core.training"
        case "sit_ups", "twisting_sit_ups": return "figure.core.training"
        case "toe_touch_control": return "hand.raised.fill"
        case "cable_crunch": return "figure.strengthtraining.traditional"
        case "ab_rollout": return "figure.rolling"
        case "v_ups": return "figure.gymnastics"
        case "hanging_leg_raises": return "figure.climbing"
        case "reverse_crunches", "reverse_crunch_pulse": return "arrow.up.circle.fill"
        case "flutter_kicks", "scissor_kicks": return "figure.pool.swim"
        case "leg_raises", "bench_leg_raises", "toe_raise_lying": return "arrow.up"
        case "russian_twists": return "arrow.left.arrow.right"
        case "bicycle_crunch": return "bicycle"
        case "side_plank_dips": return "arrow.down.circle.fill"
        case "heel_taps": return "hand.point.down.fill"
        case "windshield_wipers": return "arrow.left.and.right"
        default: return exercise.region.icon
        }
    }

    var body: some View {
        Color(AppTheme.cardSurfaceElevated)
            .frame(width: size, height: size)
            .overlay {
                AsyncImage(url: URL(string: exercise.demoImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    case .failure:
                        offlinePlaceholder
                    case .empty:
                        offlinePlaceholder
                            .overlay {
                                ProgressView()
                                    .tint(regionColor.opacity(0.5))
                                    .scaleEffect(0.6)
                            }
                    @unknown default:
                        offlinePlaceholder
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 12))
    }

    private var offlinePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [regionColor.opacity(0.15), regionColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 4) {
                Image(systemName: exerciseIcon)
                    .font(.system(size: size * 0.3, weight: .semibold))
                    .foregroundStyle(regionColor.opacity(0.6))

                if size >= 56 {
                    Text(exercise.region.rawValue)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(regionColor.opacity(0.4))
                        .tracking(0.5)
                }
            }
        }
    }
}
