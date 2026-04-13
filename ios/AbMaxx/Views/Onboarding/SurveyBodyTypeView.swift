import SwiftUI

struct SurveyBodyTypeView: View {
    @Binding var category: BodyFatCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What best describes\nyour current body?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("This determines how fast your abs will show.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(BodyFatCategory.allCases, id: \.self) { cat in
                    OnboardingPillButton(
                        title: cat.rawValue,
                        subtitle: cat.rangeText + " body fat",
                        icon: cat.icon,
                        isSelected: category == cat
                    ) {
                        category = cat
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()
        }
    }
}
