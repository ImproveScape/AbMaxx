import SwiftUI

struct PainPointQuestionView: View {
    let question: String
    let subtitle: String
    let options: [(icon: String, text: String)]
    @Binding var selected: String

    @State private var appeared: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(question)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(2)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4), value: appeared)

            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    OnboardingPillButton(
                        title: option.text,
                        icon: option.icon,
                        isSelected: selected == option.text
                    ) {
                        selected = option.text
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.05 + Double(index) * 0.04), value: appeared)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)

            Spacer()
        }
        .sensoryFeedback(.selection, trigger: selected)
        .onAppear { appeared = true }
    }
}
