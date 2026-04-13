import SwiftUI

struct TransformationVisionView: View {
    let username: String
    @State private var phase: Int = 0
    @State private var glowPulse: Bool = false
    @State private var orbPulse: Bool = false

    private let killedHabits = [
        "Hiding at the pool",
        "Shirt on at the beach",
        "Avoiding the mirror",
        "Making excuses",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                VStack(spacing: 6) {
                    Text(username + ",")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .opacity(phase >= 1 ? 1 : 0)
                        .animation(.easeIn(duration: 0.4), value: phase)

                    VStack(spacing: 4) {
                        Text("This summer you won't be")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)

                        Text("anxious")
                            .font(.system(size: 48, weight: .black))
                            .foregroundStyle(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [AppTheme.primaryAccent, Color(red: 0.45, green: 0.65, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .mask(
                                    Text("anxious")
                                        .font(.system(size: 48, weight: .black))
                                )
                            )
                            .shadow(color: AppTheme.primaryAccent.opacity(glowPulse ? 0.6 : 0.15), radius: glowPulse ? 35 : 12)

                        Text("taking your shirt off.")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(phase >= 2 ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: phase)
                }

                if phase >= 3 {
                    VStack(spacing: 10) {
                        ForEach(Array(killedHabits.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 12) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(AppTheme.destructive.opacity(0.6))
                                    .frame(width: 22, height: 22)
                                    .background(AppTheme.destructive.opacity(0.1))
                                    .clipShape(Circle())

                                Text(item)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.muted)
                                    .strikethrough(true, color: AppTheme.destructive.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(phase >= 3 ? 1 : 0)
                            .offset(x: phase >= 3 ? 0 : -20)
                            .animation(.spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.08), value: phase)
                        }
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity)
                }

                if phase >= 4 {
                    VStack(spacing: 16) {
                        Capsule()
                            .fill(AppTheme.primaryAccent)
                            .frame(width: 40, height: 3)

                        Text("It's time to feel")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)

                        Text("CONFIDENT")
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(.white)
                            .shadow(color: AppTheme.primaryAccent.opacity(glowPulse ? 0.5 : 0.1), radius: glowPulse ? 30 : 8)

                        Text("in your own body.")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(orbPulse ? 0.06 : 0.02))
                    .frame(width: 350, height: 350)
                    .blur(radius: 120)
                    .offset(y: -60)
            }
            .ignoresSafeArea()
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: phase)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation { phase = 2 }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(.spring(duration: 0.5)) { phase = 3 }
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.spring(duration: 0.6, bounce: 0.15)) { phase = 4 }
            }
        }
    }
}
