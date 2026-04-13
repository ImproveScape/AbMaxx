import SwiftUI

struct OnboardingPillButton: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                        .frame(width: 32)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.85))

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(isSelected ? .white.opacity(0.7) : AppTheme.muted)
                    }
                }

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
