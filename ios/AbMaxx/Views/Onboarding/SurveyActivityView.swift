import SwiftUI

struct SurveyActivityView: View {
    @Binding var level: ActivityLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How active are you?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("More active = more calories you can eat and still see abs.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(ActivityLevel.allCases, id: \.self) { activity in
                    OnboardingPillButton(
                        title: activity.rawValue,
                        subtitle: activity.description,
                        icon: activityIcon(activity),
                        isSelected: level == activity
                    ) {
                        level = activity
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()
        }
    }

    private func activityIcon(_ activity: ActivityLevel) -> String {
        switch activity {
        case .sedentary: return "figure.stand"
        case .lightlyActive: return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive: return "flame.fill"
        }
    }
}
