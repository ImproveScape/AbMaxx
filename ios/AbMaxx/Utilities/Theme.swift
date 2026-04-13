import SwiftUI
import UIKit

enum AppTheme {
    static let background = Color(hex: "0D0D0D")
    static let card = Color.white.opacity(0.05)
    static let cardBorder = Color.white.opacity(0.10)
    static let cardSolid = Color(hex: "1C1C1E")
    static let cardBorderSolid = Color(hex: "2C2C2E")
    static let cardElevated = Color(hex: "252525")
    static let dividerColor = Color(hex: "2C2C2E")

    static let primaryAccent = Color(hex: "0A84FF")
    static let success = Color(hex: "30D158")
    static let destructive = Color(hex: "FF3B30")
    static let warning = Color(hex: "FF3B30")
    static let caution = Color(hex: "FF9F0A")
    static let orange = Color(hex: "FF9F0A")
    static let purple = Color(hex: "BF5AF2")
    static let yellow = Color(hex: "FFD60A")

    static let primaryText = Color.white
    static let secondaryText = Color(hex: "8E8E93")
    static let muted = Color(hex: "48484A")
    static let ghost = Color(hex: "636366")

    static let navBarBg = Color(hex: "0A0A0A")
    static let navBarBorder = Color(hex: "1C1C1E")

    static let secondaryAccent = Color(hex: "0A84FF").opacity(0.78)
    static let tertiaryAccent = Color(hex: "0A84FF").opacity(0.58)

    static let cardCornerRadius: CGFloat = 18
    static let nestedCornerRadius: CGFloat = 14
    static let buttonCornerRadius: CGFloat = 14
    static let sectionSpacing: CGFloat = 28
    static let pillRadius: CGFloat = 20

    static let cardSurface = card
    static let cardSurfaceElevated = cardElevated
    static let border = cardBorder
    static let borderLight = cardBorder
    static let blueGlow = Color.clear
    static let blueBorder = cardBorder
    static let navBarBackground = navBarBg

    static let accentGradient = LinearGradient(
        colors: [primaryAccent, primaryAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [background, background],
        startPoint: .top,
        endPoint: .bottom
    )

    static let onboardingGradient = LinearGradient(
        colors: [
            Color(red: 8/255, green: 10/255, blue: 22/255),
            Color(red: 5/255, green: 8/255, blue: 20/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let paywallGradient = LinearGradient(
        colors: [
            Color(red: 8/255, green: 10/255, blue: 22/255),
            Color(red: 5/255, green: 8/255, blue: 20/255)
        ],
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
        if score >= 80 { return caution }
        if score >= 70 { return primaryAccent }
        return destructive
    }

    static func subscoreColor(for score: Int) -> Color {
        if score >= 85 { return success }
        if score >= 75 { return yellow }
        if score >= 65 { return caution }
        return destructive
    }

    static func glowShadow(radius: CGFloat = 20, opacity: Double = 0.5) -> Color {
        Color.clear
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")

            GeometryReader { geo in
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.04, green: 0.12, blue: 0.28).opacity(0.55),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.35),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.70
                )

                Image(uiImage: FilmGrain.shared)
                    .resizable()

                LinearGradient(
                    colors: [Color.black.opacity(0.45), Color.clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.13)
                )

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.45)],
                    startPoint: UnitPoint(x: 0.5, y: 0.85),
                    endPoint: .bottom
                )

                LinearGradient(
                    colors: [Color.black.opacity(0.3), Color.clear],
                    startPoint: .leading,
                    endPoint: UnitPoint(x: 0.16, y: 0.5)
                )

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.3)],
                    startPoint: UnitPoint(x: 0.84, y: 0.5),
                    endPoint: .trailing
                )
            }
        }
    }
}

enum FilmGrain {
    static let shared: UIImage = {
        let w = 390
        let h = 844
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        return renderer.image { ctx in
            UIColor(white: 0, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for _ in 0..<12000 {
                let x = CGFloat.random(in: 0..<CGFloat(w))
                let y = CGFloat.random(in: 0..<CGFloat(h))
                let a = CGFloat.random(in: 0.0...0.028)
                UIColor.white.withAlphaComponent(a).setFill()
                ctx.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }
    }()
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

struct GlowButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isEnabled ? AppTheme.primaryAccent : AppTheme.muted)
            .clipShape(.rect(cornerRadius: AppTheme.buttonCornerRadius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct CardModifier: ViewModifier {
    var highlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppTheme.card, in: .rect(cornerRadius: AppTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
            )
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppTheme.card, in: .rect(cornerRadius: AppTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
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

    func premiumBackground() -> some View {
        self.background(BackgroundView().ignoresSafeArea())
    }

    func appBackground() -> some View {
        self.background(BackgroundView().ignoresSafeArea())
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
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .medium))
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
        BackgroundView()
            .ignoresSafeArea()
    }
}
