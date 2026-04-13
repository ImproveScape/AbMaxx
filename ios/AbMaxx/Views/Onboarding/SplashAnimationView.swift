import SwiftUI

struct SplashAnimationView: View {
    let onFinished: () -> Void

    @State private var phase: Int = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var scanLineOffset: CGFloat = -1
    @State private var finalFade: Bool = false

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.38)
            ZStack {
                if phase >= 1 {
                    RadialGradient(
                        colors: [
                            AppTheme.primaryAccent.opacity(0.15),
                            AppTheme.primaryAccent.opacity(0.04),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 280
                    )
                    .frame(width: 560, height: 560)
                    .scaleEffect(phase >= 3 ? 1.3 : 0.5)
                    .position(center)
                    .animation(.easeOut(duration: 1.8), value: phase)
                }

                if phase >= 2 {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .strokeBorder(
                                AppTheme.primaryAccent.opacity(0.08 - Double(i) * 0.02),
                                lineWidth: 1
                            )
                            .frame(width: 140 + CGFloat(i) * 60, height: 140 + CGFloat(i) * 60)
                            .scaleEffect(pulseScale + CGFloat(i) * 0.05)
                            .position(center)
                    }
                }

                logoContent(center: center, size: geo.size)

                if phase >= 2 && phase < 5 {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, AppTheme.primaryAccent.opacity(0.5), .white.opacity(0.15), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 130, height: 3)
                        .offset(y: scanLineOffset * 70)
                        .position(center)
                }

                if finalFade {
                    AppTheme.background
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { runSequence() }
    }

    private func logoContent(center: CGPoint, size: CGSize) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primaryAccent.opacity(phase >= 3 ? 0.4 : 0),
                                AppTheme.primaryAccent.opacity(phase >= 3 ? 0.1 : 0),
                                .clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)

                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(.rect(cornerRadius: 28))
                    .shadow(color: AppTheme.primaryAccent.opacity(0.6), radius: 30)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 60)
                    .scaleEffect(phase >= 3 ? 1 : 0.3)
                    .opacity(phase >= 3 ? 1 : 0)
                    .animation(.spring(duration: 0.6, bounce: 0.2), value: phase)
            }

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("AB")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(.white)
                        .opacity(phase >= 4 ? 1 : 0)
                        .offset(x: phase >= 4 ? 0 : -20)
                        .animation(.spring(duration: 0.5, bounce: 0.15), value: phase)

                    Text("MAXX")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 20)
                        .opacity(phase >= 4 ? 1 : 0)
                        .offset(x: phase >= 4 ? 0 : 20)
                        .animation(.spring(duration: 0.5, bounce: 0.15).delay(0.08), value: phase)
                }
                .tracking(4)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent.opacity(0), AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .frame(maxWidth: phase >= 5 ? 180 : 0)
                    .animation(.spring(duration: 0.6), value: phase)
                    .padding(.top, 8)

                Text("MAX YOUR ABS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(6)
                    .opacity(phase >= 5 ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: phase)
                    .padding(.top, 12)
            }

            Spacer()
            Spacer()
            Spacer()
        }
    }

    private func runSequence() {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            phase = 1

            try? await Task.sleep(for: .milliseconds(300))
            phase = 2

            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scanLineOffset = 1
            }

            try? await Task.sleep(for: .milliseconds(400))
            phase = 3

            try? await Task.sleep(for: .milliseconds(350))
            phase = 4

            try? await Task.sleep(for: .milliseconds(300))
            phase = 5

            try? await Task.sleep(for: .milliseconds(1200))

            withAnimation(.easeIn(duration: 0.4)) {
                finalFade = true
            }

            try? await Task.sleep(for: .milliseconds(450))
            onFinished()
        }
    }
}
