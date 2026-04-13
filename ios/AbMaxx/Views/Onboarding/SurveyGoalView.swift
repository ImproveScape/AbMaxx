import SwiftUI

struct SurveyGoalView: View {
    @Binding var goal: AbsGoal?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your main goal?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Every workout, meal plan & scan will target this.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(AbsGoal.allCases, id: \.self) { g in
                    OnboardingPillButton(
                        title: g.rawValue,
                        subtitle: g.calorieHint,
                        icon: g.icon,
                        isSelected: goal == g
                    ) {
                        goal = g
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()
        }
    }
}
