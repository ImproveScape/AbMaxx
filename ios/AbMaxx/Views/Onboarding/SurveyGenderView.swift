import SwiftUI

struct SurveyGenderView: View {
    @Binding var gender: Gender?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your gender?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Your ab plan depends on your hormones & metabolism.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(Gender.allCases, id: \.self) { g in
                    OnboardingPillButton(
                        title: g.rawValue,
                        icon: genderIcon(g),
                        isSelected: gender == g
                    ) {
                        gender = g
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()
        }
    }

    private func genderIcon(_ g: Gender) -> String {
        switch g {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .other: return "person.fill"
        }
    }
}
