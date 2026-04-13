import SwiftUI

struct ScanReminderToast: View {
    let days: Int
    var onDismiss: () -> Void

    private var message: String {
        if days <= 1 {
            return "Your next scan is tomorrow. Keep grinding."
        } else {
            return "Next scan in \(days) days. Stay locked in."
        }
    }

    var body: some View {
        Button(action: onDismiss) {
            HStack(spacing: 10) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)

                Text(message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                AppTheme.cardSurfaceElevated
                    .shadow(.drop(color: AppTheme.primaryAccent.opacity(0.15), radius: 12, y: 4))
            )
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppTheme.primaryAccent.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 220)
    }
}
