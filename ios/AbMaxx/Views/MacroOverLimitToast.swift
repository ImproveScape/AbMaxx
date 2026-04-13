import SwiftUI

struct MacroOverLimitToast: View {
    let macroName: String
    let overByAmount: Int
    let message: String

    @State private var appear: Bool = false
    @State private var iconPulse: Bool = false
    @State private var ringProgress: CGFloat = 0

    private var accentColor: Color {
        switch macroName {
        case "Calories": return Color(red: 1.0, green: 0.35, blue: 0.35)
        case "Protein":  return Color(red: 1.0, green: 0.55, blue: 0.25)
        case "Carbs":    return Color(red: 1.0, green: 0.75, blue: 0.20)
        default:         return Color(red: 1.0, green: 0.45, blue: 0.45)
        }
    }

    private var icon: String {
        switch macroName {
        case "Calories": return "flame.fill"
        case "Protein":  return "fork.knife"
        case "Carbs":    return "leaf.fill"
        default:         return "drop.fill"
        }
    }

    private var unit: String {
        macroName == "Calories" ? "cal" : "g"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(appear ? 0.6 : 0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .stroke(accentColor.opacity(0.12), lineWidth: 4)
                            .frame(width: 90, height: 90)

                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                accentColor.opacity(0.5),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [accentColor.opacity(0.2), accentColor.opacity(0.05)],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 45
                                )
                            )
                            .frame(width: 90, height: 90)

                        Image(systemName: icon)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(accentColor)
                            .scaleEffect(iconPulse ? 1.1 : 1.0)
                    }

                    VStack(spacing: 10) {
                        Text("\(macroName) Limit Hit")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)

                        Text("+\(overByAmount) \(unit) over")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(accentColor.opacity(0.12), in: Capsule())
                    }

                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)
                }
                .padding(.vertical, 36)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.cardSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [accentColor.opacity(0.35), AppTheme.border],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: accentColor.opacity(0.15), radius: 40, y: 10)
                        .shadow(color: .black.opacity(0.5), radius: 30, y: 15)
                }
                .padding(.horizontal, 28)
                .scaleEffect(appear ? 1.0 : 0.8)
                .opacity(appear ? 1.0 : 0)
                .offset(y: appear ? 0 : 40)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appear = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                ringProgress = 1.0
            }
            withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true).delay(0.4)) {
                iconPulse = true
            }
        }
    }
}
