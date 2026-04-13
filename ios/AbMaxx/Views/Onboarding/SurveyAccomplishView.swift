import SwiftUI

struct SurveyAccomplishView: View {
    @Binding var selectedGoal: String?

    private let goals: [(id: String, icon: String, title: String)] = [
        ("confident", "tshirt.fill", "Feel Confident Shirtless"),
        ("energy", "bolt.fill", "Boost My Energy and Mood"),
        ("body", "figure.arms.open", "Feel Better in My Body"),
        ("motivated", "flame.fill", "Stay Motivated and Consistent"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What would you like\nto accomplish?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("This is the feeling we're building your plan around.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(goals, id: \.id) { goal in
                    let isSelected = selectedGoal == goal.id
                    Button {
                        selectedGoal = goal.id
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: goal.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                                .frame(width: 32)

                            Text(goal.title)
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
