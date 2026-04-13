import SwiftUI

struct FoodLoggedToast: View {
    let foodName: String

    @State private var appear: Bool = false
    @State private var iconBounce: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 80/255, green: 200/255, blue: 120/255))
                .scaleEffect(iconBounce ? 1.3 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: iconBounce)

            Text("\(foodName) Logged")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color(red: 80/255, green: 200/255, blue: 120/255))
                .symbolEffect(.bounce, value: appear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            AppTheme.cardSurfaceElevated
                .shadow(.drop(color: Color(red: 80/255, green: 200/255, blue: 120/255).opacity(0.15), radius: 16, y: 6))
        )
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color(red: 80/255, green: 200/255, blue: 120/255).opacity(0.2),
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
                iconBounce = true
            }
        }
    }
}
