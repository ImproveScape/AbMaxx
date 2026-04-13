import SwiftUI

struct ScienceBackedView: View {
    @State private var phase: Int = 0
    @State private var orbPulse: Bool = false

    private let pillars: [(icon: String, title: String, subtitle: String, color: Color, bgColor: Color)] = [
        ("flame.fill", "PROGRAM", "Targeted core training", Color(red: 0.40, green: 0.60, blue: 1.0), Color(red: 0.10, green: 0.15, blue: 0.35)),
        ("bolt.fill", "FUEL", "Nutrition that reveals abs", Color(red: 0.30, green: 0.95, blue: 0.60), Color(red: 0.08, green: 0.22, blue: 0.14)),
        ("brain.head.profile.fill", "MINDSET", "Consistency over perfection", Color(red: 0.78, green: 0.50, blue: 1.0), Color(red: 0.18, green: 0.10, blue: 0.30)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 52) {
                VStack(spacing: 12) {
                    Text("Anyone can")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("get abs.")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(.clear)
                        .overlay(
                            MeshGradient(
                                width: 3, height: 2,
                                points: [
                                    [0, 0], [0.5, 0], [1, 0],
                                    [0, 1], [0.5, 1], [1, 1]
                                ],
                                colors: [
                                    .blue, .cyan, .mint,
                                    .purple, .blue, .cyan
                                ]
                            )
                            .mask(
                                Text("get abs.")
                                    .font(.system(size: 56, weight: .black))
                            )
                        )
                        .shadow(color: Color.cyan.opacity(0.3), radius: 30)
                }
                .multilineTextAlignment(.center)
                .opacity(phase >= 1 ? 1 : 0)
                .animation(.easeOut(duration: 0.7), value: phase)

                HStack(spacing: 12) {
                    ForEach(Array(pillars.enumerated()), id: \.offset) { index, pillar in
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(pillar.color.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                    .blur(radius: 8)

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [pillar.bgColor, pillar.bgColor.opacity(0.3)],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 28
                                        )
                                    )
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(pillar.color.opacity(0.25), lineWidth: 1)
                                    )

                                Image(systemName: pillar.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(pillar.color)
                            }

                            VStack(spacing: 6) {
                                Text(pillar.title)
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundStyle(pillar.color)
                                    .tracking(2)

                                Text(pillar.subtitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.3))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(pillar.bgColor.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [pillar.color.opacity(0.2), pillar.color.opacity(0.05)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .opacity(phase >= 2 ? 1 : 0)
                        .scaleEffect(phase >= 2 ? 1 : 0.8)
                        .animation(.spring(duration: 0.55, bounce: 0.2).delay(Double(index) * 0.08), value: phase)
                    }
                }

                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(pillars[i].color.opacity(0.5))
                                .frame(width: phase >= 3 ? 20 : 0, height: 3)
                                .animation(.spring(duration: 0.5).delay(Double(i) * 0.08), value: phase)
                        }
                    }

                    Text("Science, not genetics.")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .opacity(phase >= 3 ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: phase)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(orbPulse ? 0.06 : 0.03))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(y: -80)
                Circle()
                    .fill(Color.purple.opacity(orbPulse ? 0.05 : 0.02))
                    .frame(width: 250, height: 250)
                    .blur(radius: 80)
                    .offset(x: 100, y: 200)
            }
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation { phase = 2 }
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation { phase = 3 }
            }
        }
    }
}
