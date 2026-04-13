import SwiftUI

enum BrandColors {
    static let red = Color(hex: "FF3B30")
    static let orange = Color(hex: "FF9F0A")
}

struct BrandRedGradientDeep: View {
    var body: some View {
        AppTheme.primaryAccent
    }
}

struct BrandDeepGradientBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(AppTheme.primaryAccent, in: .rect(cornerRadius: cornerRadius))
    }
}

struct PolishedCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(AppTheme.card, in: .rect(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
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
