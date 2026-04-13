import SwiftUI

struct WaterLoggedToast: View {
    let glassCount: Int
    let waterGoal: Int

    @State private var appear: Bool = false
    @State private var dropBounce: Bool = false

    private var isGoalHit: Bool {
        glassCount >= waterGoal && waterGoal > 0
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isGoalHit ? "checkmark.circle.fill" : "drop.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isGoalHit ? AppTheme.success : Color(red: 60/255, green: 160/255, blue: 255/255))
                .scaleEffect(dropBounce ? 1.3 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: dropBounce)

            VStack(alignment: .leading, spacing: 2) {
                Text(isGoalHit ? "Water Goal Hit!" : "+1 Water Logged")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(glassCount)/\(waterGoal) glasses today")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            if isGoalHit {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.orange)
                    .symbolEffect(.bounce, value: appear)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            AppTheme.cardSurfaceElevated
                .shadow(.drop(color: Color(red: 30/255, green: 100/255, blue: 255/255).opacity(0.2), radius: 16, y: 6))
        )
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isGoalHit
                        ? AppTheme.success.opacity(0.3)
                        : Color(red: 40/255, green: 120/255, blue: 255/255).opacity(0.2),
                    lineWidth: 0.5
                )
        )
        .padding(.horizontal, 20)
        .scaleEffect(appear ? 1.0 : 0.8)
        .opacity(appear ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                appear = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dropBounce = true
            }
        }
    }
}
