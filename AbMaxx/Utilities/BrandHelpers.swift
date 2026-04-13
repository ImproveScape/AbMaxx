import SwiftUI

enum BrandColors {
    static let red = Color(red: 0.95, green: 0.23, blue: 0.15)
    static let orange = Color(red: 1.0, green: 0.45, blue: 0.18)
}

struct BrandRedGradientDeep: View {
    var body: some View {
        LinearGradient(
            colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct BrandDeepGradientBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}

struct PolishedCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color(white: 0.08), in: .rect(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
    }
}

extension View {
    func brandDeepGradientBackground(cornerRadius: CGFloat = 14) -> some View {
        modifier(BrandDeepGradientBackgroundModifier(cornerRadius: cornerRadius))
    }

    func polishedCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(PolishedCardModifier(cornerRadius: cornerRadius))
    }
}
