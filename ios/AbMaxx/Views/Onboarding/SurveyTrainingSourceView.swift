import SwiftUI

struct SurveyTrainingSourceView: View {
    @Binding var selectedSource: String?

    private let sources: [(id: String, icon: String, title: String)] = [
        ("social", "play.rectangle.fill", "YouTube / Social media"),
        ("trainer", "person.fill.checkmark", "A personal trainer"),
        ("random", "shuffle", "Random workouts"),
        ("nothing", "figure.stand", "Nothing \u{2014} I wing it"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What\u{2019}s guiding your\nab training right now?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("No wrong answer \u{2014} we\u{2019}ll build something better.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(sources, id: \.id) { source in
                    let isSelected = selectedSource == source.id
                    Button {
                        selectedSource = source.id
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: source.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                                .frame(width: 32)

                            Text(source.title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : .white.opacity(0.85))

                            Spacer()

                            ZStack {
                                Circle()
                                    .strokeBorder(
                                        isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.15),
                                        lineWidth: 2
                                    )
                                    .frame(width: 22, height: 22)

                                if isSelected {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 20)
                        .background(
                            isSelected
                                ? AppTheme.primaryAccent
                                : Color.white.opacity(0.05)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    isSelected ? AppTheme.primaryAccent : Color.white.opacity(0.08),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .sensoryFeedback(.selection, trigger: isSelected)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()
        }
    }
}
