import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    let onContinue: () -> Void

    @State private var titleOpacity: Double = 0
    @State private var hasRequested: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Be reminded to\ntrain your abs")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(titleOpacity)
                .padding(.horizontal, 24)

            Spacer()
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                titleOpacity = 1.0
            }
            requestNotificationPermission()
        }
    }

    private func requestNotificationPermission() {
        guard !hasRequested else { return }
        hasRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                onContinue()
            }
        }
    }
}
