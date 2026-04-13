import SwiftUI

struct AbsComparisonBarView: View {
    @State private var barProgress: CGFloat = 0

    private let withoutHeight: CGFloat = 0.2
    private let withHeight: CGFloat = 0.85

    var body: some View {
        VStack(spacing: 0) {
            Text("Get visible abs twice\nas fast with AbMaxx\nvs on your own")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.horizontal, 24)

            Spacer().frame(height: 40)

            VStack(spacing: 24) {
                HStack(spacing: 20) {
                    barColumn(
                        title: "Without\nAbMaxx",
                        value: "20%",
                        fillRatio: withoutHeight,
                        barColor: AppTheme.cardSurfaceElevated,
                        valueBackground: Color.white.opacity(0.06),
                        valueTextColor: AppTheme.muted,
                        titleColor: AppTheme.muted
                    )

                    barColumn(
                        title: "With\nAbMaxx",
                        value: "2X",
                        fillRatio: withHeight,
                        barColor: AppTheme.primaryAccent,
                        valueBackground: AppTheme.primaryAccent,
                        valueTextColor: .white,
                        titleColor: .white
                    )
                }
                .frame(height: 260)
                .padding(.horizontal, 32)

                Text("AbMaxx keeps you consistent and accelerates your results.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear { runAnimation() }
    }

    private func barColumn(
        title: String,
        value: String,
        fillRatio: CGFloat,
        barColor: Color,
        valueBackground: Color,
        valueTextColor: Color,
        titleColor: Color
    ) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(titleColor)
                .multilineTextAlignment(.center)

            GeometryReader { geo in
                let maxH = geo.size.height
                let targetH = maxH * fillRatio
                let animatedH = targetH * barProgress

                VStack(spacing: 0) {
                    Spacer()

                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(barColor)
                            .frame(height: animatedH)

                        Text(value)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(valueTextColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(valueBackground)
                            .clipShape(.rect(cornerRadius: 12))
                            .padding(.bottom, 10)
                    }
                }
            }
        }
    }

    private func runAnimation() {
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) { barProgress = 1 }
        }
    }
}
