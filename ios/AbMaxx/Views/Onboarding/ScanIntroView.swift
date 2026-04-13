import SwiftUI

struct ScanIntroView: View {
    let username: String
    let onContinue: () -> Void

    @State private var showBadge: Bool = false
    @State private var showTitle: Bool = false
    @State private var showSubtitle: Bool = false
    @State private var showSteps: Bool = false
    @State private var showButton: Bool = false
    @State private var revealedSteps: Int = 0
    @State private var glowPulse: Bool = false

    private let steps: [(number: String, text: String)] = [
        ("1", "Remove your shirt"),
        ("2", "Stand in good lighting"),
        ("3", "Face the camera straight on"),
    ]

    var body: some View {
        ZStack {
            backgroundGlow

            VStack(spacing: 0) {
                Spacer()

                scanIcon
                    .opacity(showBadge ? 1 : 0)
                    .scaleEffect(showBadge ? 1 : 0.8)
                    .padding(.bottom, 32)

                VStack(spacing: 12) {
                    Text("\(username), Let's Analyze\nYour Abs")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 8)

                    Text("Our AI maps your core to identify weak points and build your plan.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 6)
                }
                .padding(.bottom, 44)

                VStack(spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        let isRevealed = index < revealedSteps

                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(isRevealed ? AppTheme.primaryAccent.opacity(0.12) : Color.white.opacity(0.04))
                                    .frame(width: 40, height: 40)

                                if isRevealed {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(AppTheme.primaryAccent)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Text(step.number)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                            }

                            Text(step.text)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(isRevealed ? .white : .white.opacity(0.35))

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isRevealed ? Color.white.opacity(0.04) : Color.white.opacity(0.02))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(
                                            isRevealed ? AppTheme.primaryAccent.opacity(0.12) : Color.white.opacity(0.03),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .opacity(showSteps ? 1 : 0)
                        .offset(y: showSteps ? 0 : 8)
                        .animation(.spring(duration: 0.5).delay(Double(index) * 0.06), value: showSteps)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                if showButton {
                    VStack(spacing: 10) {
                        Button(action: onContinue) {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Scan My Abs")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.accentGradient)
                            .clipShape(.capsule)
                            .shadow(color: AppTheme.primaryAccent.opacity(0.45), radius: 24, y: 6)
                        }

                        Text("Takes less than 10 seconds")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 36)
            }
        }
        .onAppear { startSequence() }
    }

    private var backgroundGlow: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primaryAccent.opacity(0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 140)
                .offset(y: -160)
                .scaleEffect(glowPulse ? 1.08 : 0.95)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: glowPulse)
        }
    }

    private var scanIcon: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primaryAccent.opacity(0.06))
                .frame(width: 100, height: 100)

            Image(systemName: "viewfinder")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppTheme.primaryAccent)
        }
    }

    private func startSequence() {
        glowPulse = true

        Task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) { showBadge = true }

            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeOut(duration: 0.45)) { showTitle = true }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 0.4)) { showSubtitle = true }

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(duration: 0.4)) { showSteps = true }

            for i in 1...steps.count {
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.spring(duration: 0.3, bounce: 0.25)) {
                    revealedSteps = i
                }
            }

            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) { showButton = true }
        }
    }
}
