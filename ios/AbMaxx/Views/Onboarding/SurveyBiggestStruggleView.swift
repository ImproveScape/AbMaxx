import SwiftUI

struct SurveyBiggestStruggleView: View {
    @Binding var selectedStruggles: Set<String>

    private let struggles: [(id: String, icon: String, title: String)] = [
        ("wont_show", "eye.slash.fill", "I train abs but they won't show"),
        ("exercises", "questionmark.app.fill", "I don't know which exercises work"),
        ("two_weeks", "calendar.badge.exclamationmark", "I lose motivation after 2 weeks"),
        ("nutrition", "fork.knife", "I can't figure out the nutrition side"),
        ("no_time", "clock.badge.xmark", "I don't have time for long workouts"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's been holding\nyour abs back?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Select all that apply — we'll solve each one.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(struggles, id: \.id) { struggle in
                    let isSelected = selectedStruggles.contains(struggle.id)
                    Button {
                        if isSelected {
                            selectedStruggles.remove(struggle.id)
                        } else {
                            selectedStruggles.insert(struggle.id)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: struggle.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                                .frame(width: 32)

                            Text(struggle.title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : .white.opacity(0.85))

                            Spacer()

                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(
                                        isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.15),
                                        lineWidth: 2
                                    )
                                    .frame(width: 22, height: 22)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
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
