import SwiftUI

struct SurveyAbsFrequencyView: View {
    @Binding var frequency: AbsTrainingFrequency?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How often do you\ntrain abs per week?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("We'll match your starting intensity so you don't burn out.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(AbsTrainingFrequency.allCases, id: \.self) { f in
                    OnboardingPillButton(
                        title: f.rawValue,
                        subtitle: f.detail,
                        icon: f.icon,
                        isSelected: frequency == f
                    ) {
                        frequency = f
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()
        }
    }
}
