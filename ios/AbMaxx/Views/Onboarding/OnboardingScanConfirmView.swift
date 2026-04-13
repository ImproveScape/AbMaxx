import SwiftUI

struct OnboardingScanConfirmView: View {
    let capturedImage: UIImage?
    let onAnalyze: () -> Void
    let onRetake: () -> Void

    @State private var appeared: Bool = false

    var body: some View {
        ZStack {

            VStack(spacing: 0) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 16))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }

                Spacer(minLength: 16)

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Ready to scan?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Make sure your midsection is clearly visible")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                    VStack(spacing: 12) {
                        Button {
                            onAnalyze()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "waveform.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Analyze My Abs")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.accentGradient)
                            .clipShape(.capsule)
                            .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 20, y: 6)
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: appeared)

                        Button {
                            onRetake()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Retake")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.12))
                            .clipShape(.capsule)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                appeared = true
            }
        }
    }
}
