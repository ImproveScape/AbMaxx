import SwiftUI

struct DailyMotivationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0
    @State private var animateIn: Bool = false
    @State private var pulseScale: Bool = false
    @State private var showFinale: Bool = false

    private let pages: [(icon: String, headline: String, body: String, accent: Color)] = [
        (
            "sun.max.fill",
            "Summer Is Coming.",
            "Every year you say \"next summer.\" Every year you watch from the sidelines while others show up ready. This is the summer you stop wishing and start building. No more excuses. No more \"I'll start Monday.\" The countdown has already begun.",
            Color(red: 1.0, green: 0.6, blue: 0.15)
        ),
        (
            "flame.fill",
            "Nobody Is Coming\nTo Save You.",
            "No one is going to drag you out of bed. No one is going to put the work in for you. The only person standing between you and the body you want is the version of you that keeps quitting. Kill that version. Today.",
            Color(red: 1.0, green: 0.3, blue: 0.35)
        ),
        (
            "figure.core.training",
            "Pain Is Temporary.\nRegret Is Forever.",
            "That burn in your abs? It lasts minutes. That feeling of looking in the mirror and being disappointed? That lasts all summer. Every rep you skip is a rep someone else is doing. Every day you waste is a day you can't get back.",
            AppTheme.primaryAccent
        ),
        (
            "bolt.fill",
            "You're Closer Than\nYou Think.",
            "You didn't download this app by accident. Something inside you is hungry for change. That fire? Feed it. Every single scan, every single day — that's how legends are built. Not in one day, but every day.",
            AppTheme.success
        ),
        (
            "trophy.fill",
            "This Is Your Summer.",
            "Imagine pulling your shirt off with zero hesitation. Imagine the confidence. Imagine the looks. That's not a fantasy — that's a few weeks of discipline away. Lock in. Stay consistent. Trust the process. Your future self will thank you.",
            Color(red: 1.0, green: 0.84, blue: 0.0)
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if showFinale {
                finaleView
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                motivationPageView
            }
        }
    }

    private var motivationPageView: some View {
        let page = pages[currentPage]

        return VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.cardSurface)
                        .clipShape(Circle())
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentPage ? page.accent : AppTheme.border)
                            .frame(width: i == currentPage ? 24 : 8, height: 4)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [page.accent.opacity(0.3), page.accent.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseScale ? 1.15 : 0.95)

                    Circle()
                        .fill(page.accent.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: page.icon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(page.accent)
                        .shadow(color: page.accent.opacity(0.5), radius: 12)
                }
                .scaleEffect(animateIn ? 1 : 0.5)
                .opacity(animateIn ? 1 : 0)

                VStack(spacing: 18) {
                    Text(page.headline)
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                    Text(page.body)
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 30)
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            Button {
                if currentPage < pages.count - 1 {
                    animateIn = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        currentPage += 1
                        withAnimation(.spring(duration: 0.6)) { animateIn = true }
                    }
                } else {
                    withAnimation(.spring(duration: 0.5)) { showFinale = true }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage < pages.count - 1 ? "Keep Going" : "Lock In")
                        .font(.headline.bold())
                    Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "lock.fill")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [page.accent, page.accent.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(.capsule)
                .shadow(color: page.accent.opacity(0.4), radius: 20, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6)) { animateIn = true }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { pulseScale = true }
        }
    }

    private var finaleView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.primaryAccent.opacity(0.4), AppTheme.primaryAccent.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(pulseScale ? 1.1 : 0.95)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 2)
                        )
                        .shadow(color: AppTheme.primaryAccent.opacity(0.6), radius: 30)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 12) {
                    Text("YOU'RE LOCKED IN.")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)

                    Text("No more excuses. No more waiting.\nThis is your summer. Go earn it.")
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                HStack(spacing: 24) {
                    finaleStatBubble(value: "100%", label: "Commitment", color: AppTheme.success)
                    finaleStatBubble(value: "0", label: "Excuses Left", color: AppTheme.destructive)
                    finaleStatBubble(value: "NOW", label: "Start Time", color: AppTheme.orange)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button { dismiss() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.subheadline.bold())
                    Text("Let's Get to Work")
                        .font(.headline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.accentGradient)
                .clipShape(.capsule)
                .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 24, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func finaleStatBubble(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .default))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.25), lineWidth: 1)
        )
    }
}
