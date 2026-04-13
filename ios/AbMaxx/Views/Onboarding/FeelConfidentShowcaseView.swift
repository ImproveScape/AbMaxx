import SwiftUI

struct FeelConfidentShowcaseView: View {
    let onContinue: () -> Void

    private let mockupImageURL = "https://pub-e001eb4506b145aa938b5d3badbff6a5.r2.dev/attachments/7zu0xrkayupf9dtypumm5.png"

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            VStack(spacing: 10) {
                Text("Start Feeling Confident")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Without Your Shirt")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 24)

            PreloadedImage(urlString: mockupImageURL)
                .padding(.horizontal, 16)

            Spacer(minLength: 24)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.accentGradient)
                    .clipShape(.capsule)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}
