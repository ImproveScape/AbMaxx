import SwiftUI

struct StruggleSolutionView: View {
    let selectedStruggles: Set<String>
    let username: String
    @State private var phase: Int = 0
    @State private var currentCardIndex: Int = 0
    @State private var glowPulse: Bool = false

    private var solutions: [(id: String, icon: String, struggle: String, hook: String, solution: String, color: Color)] {
        var result: [(id: String, icon: String, struggle: String, hook: String, solution: String, color: Color)] = []

        if selectedStruggles.contains("consistency") {
            result.append((
                "consistency",
                "arrow.trianglehead.2.counterclockwise",
                "CONSISTENCY",
                "You don't lack discipline.\nYou lack a system.",
                "AbMaxx builds micro-habits that stack. 10-minute daily sessions, streak tracking, and smart reminders that adapt to YOUR schedule.",
                Color(red: 0.95, green: 0.45, blue: 0.25)
            ))
        }
        if selectedStruggles.contains("eating") {
            result.append((
                "eating",
                "fork.knife",
                "EATING HABITS",
                "You know what to eat.\nYou just can't stick to it.",
                "Our AI meal scanner removes the guesswork. Snap your food, get instant macros, and stay in a deficit without counting every calorie.",
                Color(red: 0.90, green: 0.30, blue: 0.35)
            ))
        }
        if selectedStruggles.contains("schedule") {
            result.append((
                "schedule",
                "clock.badge.exclamationmark",
                "BUSY SCHEDULE",
                "Everyone has 24 hours.\nThe difference is how you use 10 minutes.",
                "Every AbMaxx workout is under 15 minutes. No gym required. No excuses. Your abs don't need an hour — they need intensity.",
                Color(red: 0.40, green: 0.55, blue: 1.0)
            ))
        }
        if selectedStruggles.contains("motivation") {
            result.append((
                "motivation",
                "battery.25percent",
                "MOTIVATION",
                "Motivation fades.\nIdentity doesn't.",
                "AbMaxx uses visual progress tracking, daily streaks, and your ab score to make you addicted to improvement. You won't need motivation when you see results.",
                Color(red: 0.75, green: 0.50, blue: 1.0)
            ))
        }
        if selectedStruggles.contains("direction") {
            result.append((
                "direction",
                "questionmark.circle",
                "WHERE TO START",
                "Information overload\nis the real enemy.",
                "One personalized plan. One daily focus. AbMaxx tells you exactly what to do, when to do it, and how to progress — zero thinking required.",
                Color(red: 0.30, green: 0.85, blue: 0.65)
            ))
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 10) {
                    Text("\(username), we hear you.")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(2)
                        .opacity(phase >= 1 ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: phase)

                    Text("Here's how we\nfix this.")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(phase >= 1 ? 1 : 0)
                        .animation(.easeIn(duration: 0.6).delay(0.15), value: phase)
                }

                if phase >= 2 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(Array(solutions.enumerated()), id: \.element.id) { index, sol in
                                solutionCard(sol, index: index)
                                    .containerRelativeFrame(.horizontal, count: solutions.count > 1 ? 10 : 10, span: solutions.count > 1 ? 9 : 10, spacing: 0)
                            }
                        }
                    }
                    .contentMargins(.horizontal, 24)
                    .scrollTargetBehavior(.viewAligned)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    if solutions.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(0..<solutions.count, id: \.self) { i in
                                Capsule()
                                    .fill(solutions[i].color.opacity(0.7))
                                    .frame(width: 20, height: 4)
                            }
                        }
                        .transition(.opacity)
                    }
                }

                if phase >= 3 {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.primaryAccent)
                            Text("Your personalized plan addresses all \(solutions.count) struggle\(solutions.count == 1 ? "" : "s")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            Spacer()
        }
        .background(
            ZStack {
                ForEach(Array(solutions.enumerated()), id: \.element.id) { index, sol in
                    Circle()
                        .fill(sol.color.opacity(glowPulse ? 0.06 : 0.02))
                        .frame(width: 250, height: 250)
                        .blur(radius: 100)
                        .offset(
                            x: CGFloat(index % 2 == 0 ? -80 : 80),
                            y: CGFloat(index * 120 - 100)
                        )
                }
            }
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(.spring(duration: 0.6)) { phase = 2 }
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation(.easeIn(duration: 0.4)) { phase = 3 }
            }
        }
    }

    private func solutionCard(_ sol: (id: String, icon: String, struggle: String, hook: String, solution: String, color: Color), index: Int) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(sol.color.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: sol.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(sol.color)
                }

                Text(sol.struggle)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(sol.color)
                    .tracking(2)
            }

            Text(sol.hook)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.white)
                .lineSpacing(4)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [sol.color, sol.color.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .frame(maxWidth: 60)

            Text(sol.solution)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(sol.color)
                Text("Built into your plan")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(sol.color.opacity(0.8))
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(sol.color.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [sol.color.opacity(0.3), sol.color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}
