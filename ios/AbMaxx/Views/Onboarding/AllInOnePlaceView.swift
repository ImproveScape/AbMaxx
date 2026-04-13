import SwiftUI

struct AllInOnePlaceView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
                Spacer(minLength: 40)

                VStack(spacing: 10) {
                    Text("All In One Place")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Your scores, weak zones, coach insights — one tap away.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 32)
                        .padding(.top, 2)
                }

                Spacer(minLength: 20)

                PreloadedImage(urlString: "https://pub-e001eb4506b145aa938b5d3badbff6a5.r2.dev/attachments/w5vf0xmx5vbw4btfmh3sm.png")
                    .frame(maxHeight: 440)

                Spacer(minLength: 20)

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
