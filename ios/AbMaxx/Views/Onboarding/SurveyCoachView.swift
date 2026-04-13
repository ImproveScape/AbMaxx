import SwiftUI

struct SurveyCoachView: View {
    @Binding var hasCoach: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Do you currently work with a personal fitness coach?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("This helps us tailor your program.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                OnboardingPillButton(
                    title: "Yes",
                    subtitle: "I train with a coach",
                    icon: "person.fill.checkmark",
                    isSelected: hasCoach
                ) {
                    hasCoach = true
                }

                OnboardingPillButton(
                    title: "No",
                    subtitle: "I train on my own",
                    icon: "figure.strengthtraining.traditional",
                    isSelected: !hasCoach
                ) {
                    hasCoach = false
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()
        }
    }
}
