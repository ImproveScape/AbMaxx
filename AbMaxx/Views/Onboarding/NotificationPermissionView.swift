import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    let onContinue: () -> Void

    @State private var titleOpacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()

            VStack {
                Spacer()

                Text("Stay on track with\ndaily reminders")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(titleOpacity)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1
            }
            requestPermission()
        }
    }

    private func requestPermission() {
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                Task { @MainActor in
                    onContinue()
                }
            }
        }
    }
}
