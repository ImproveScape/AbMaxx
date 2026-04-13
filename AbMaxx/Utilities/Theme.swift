import SwiftUI

enum AppTheme {
    static let background = Color(red: 8/255, green: 10/255, blue: 24/255)
    static let primaryAccent = Color(red: 45/255, green: 59/255, blue: 255/255)
    static let secondaryAccent = Color(red: 45/255, green: 59/255, blue: 255/255).opacity(0.8)
    static let tertiaryAccent = Color(red: 45/255, green: 59/255, blue: 255/255).opacity(0.6)
    static let cardSurface = Color(red: 18/255, green: 22/255, blue: 48/255)
    static let cardSurfaceElevated = Color(red: 26/255, green: 32/255, blue: 60/255)
    static let border = Color.white.opacity(0.06)
    static let borderLight = Color.white.opacity(0.08)
    static let primaryText = Color(red: 240/255, green: 240/255, blue: 255/255)
    static let secondaryText = Color(red: 170/255, green: 182/255, blue: 210/255)
    static let muted = Color(red: 90/255, green: 102/255, blue: 138/255)
    static let destructive = Color(red: 255/255, green: 82/255, blue: 82/255)
    static let success = Color(red: 76/255, green: 175/255, blue: 80/255)
    static let warning = Color(red: 255/255, green: 217/255, blue: 61/255)
    static let orange = Color(red: 1.0, green: 0.58, blue: 0.20)

    static let blueGlow = Color(red: 45/255, green: 59/255, blue: 255/255).opacity(0.12)
    static let blueBorder = Color(red: 45/255, green: 59/255, blue: 255/255).opacity(0.25)
    static let navBarBackground = Color(red: 10/255, green: 12/255, blue: 28/255)

    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 28

    static let accentGradient = LinearGradient(
        colors: [primaryAccent, primaryAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 12/255, green: 16/255, blue: 48/255),
            Color(red: 9/255, green: 12/255, blue: 34/255),
            Color(red: 8/255, green: 10/255, blue: 24/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let onboardingGradient = LinearGradient(
        colors: [
            Color(red: 12/255, green: 16/255, blue: 48/255),
            Color(red: 9/255, green: 12/255, blue: 34/255),
            Color(red: 8/255, green: 10/255, blue: 24/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let paywallGradient = LinearGradient(
        colors: [background, background],
        startPoint: .top,
        endPoint: .bottom
    )

    static let shimmerGradient = LinearGradient(
        colors: [primaryAccent.opacity(0), primaryAccent.opacity(0.3), primaryAccent.opacity(0)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func scoreColor(for score: Int) -> Color {
        if score >= 87 { return success }
        if score >= 80 { return warning }
        if score >= 70 { return primaryAccent }
        return destructive
    }

    static func glowShadow(radius: CGFloat = 20, opacity: Double = 0.35) -> Color {
        primaryAccent.opacity(opacity)
    }
}

struct GlowButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if isEnabled {
                        AppTheme.primaryAccent
                    } else {
                        AppTheme.muted.opacity(0.6)
                    }
                }
            )
            .clipShape(.capsule)
            .shadow(color: isEnabled ? AppTheme.primaryAccent.opacity(0.35) : .clear, radius: 24, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct CardModifier: ViewModifier {
    var highlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(highlighted ? AppTheme.cardSurfaceElevated : AppTheme.cardSurface)
                    .shadow(color: highlighted ? AppTheme.primaryAccent.opacity(0.08) : Color.black.opacity(0.18), radius: highlighted ? 16 : 8, y: 4)
            )
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(AppTheme.cardSurface)
                    .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
            )
    }
}

extension View {
    func cardStyle(highlighted: Bool = false) -> some View {
        modifier(CardModifier(highlighted: highlighted))
    }

    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}

struct PageHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            Spacer()
            if let trailing {
                trailing
            }
        }
    }
}

struct StandardBackgroundOrbs: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 20/255, green: 30/255, blue: 90/255).opacity(0.35),
                            Color(red: 15/255, green: 20/255, blue: 60/255).opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                )
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .offset(x: -80, y: -180)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 25/255, green: 35/255, blue: 100/255).opacity(0.2),
                            Color(red: 10/255, green: 15/255, blue: 50/255).opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 70)
                .offset(x: 120, y: 300)

            Circle()
                .fill(
                    Color(red: 30/255, green: 40/255, blue: 110/255).opacity(0.08)
                )
                .frame(width: 250, height: 250)
                .blur(radius: 100)
                .offset(x: 60, y: 50)
        }
        .ignoresSafeArea()
    }
}
