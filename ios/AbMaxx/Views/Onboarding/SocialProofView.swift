import SwiftUI
import StoreKit

struct SocialProofView: View {
    let onContinue: () -> Void
    var onBack: (() -> Void)? = nil

    @State private var buttonEnabled: Bool = false
    @State private var hasRequestedReview: Bool = false

    private let profileImages: [String] = [
        "https://r2-pub.rork.com/attachments/5w7fk2fm3wxzv0wlzhe0y.jpg",
        "https://r2-pub.rork.com/attachments/poyw0g4265wf1btqdlx24.jpg",
        "https://r2-pub.rork.com/attachments/r203f9lz3n4ld9m71zsxg.jpg",
        "https://r2-pub.rork.com/attachments/4hmwmqwasyxfm28uixzhu.jpg",
        "https://r2-pub.rork.com/projects/ef37pg3laezo1t2hj7mt0/assets/6b727322-5397-4f3d-a42d-c1601cd9210e.png"
    ]

    private let reviews: [(name: String, text: String, imageIndex: Int)] = [
        ("Luca Leighton", "My abs looked better than they ever have! This app making getting in shape so fun and simple. Would definitely recommend!", 3),
        ("Anthony Aureliano", "Finally comfortable taking off my shirt at the beach ever since I started to AbMaxx", 1),
        ("Antonio George", "Absolutely love this app. My abs have been looking insane lately and my bottom 2 abs are finally starting to come in. Cant wait to see what my abs are gonna look like in 5 weeks!", 4),
        ("Lukz Mandel", "Literally a life changer. I struggled to get abs my entire life and it always felt impossible for me to have actual abs. Now random people are asking me what my Ab routine is. LOL", 0)
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        overlappingAvatars
                            .padding(.top, 24)

                        Text("Join thousands of people\ntransforming their abs")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)

                        statsRow

                        reviewsList

                        Spacer().frame(height: 100)
                    }
                }
                .scrollIndicators(.hidden)

                continueButton
            }
        }
        .onAppear {
            requestStoreReview()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    buttonEnabled = true
                }
            }
        }
    }

    private var overlappingAvatars: some View {
        HStack(spacing: -14) {
            ForEach(0..<3, id: \.self) { index in
                avatarCircle(urlString: profileImages[index])
                    .zIndex(Double(3 - index))
            }
        }
    }

    private func avatarCircle(urlString: String) -> some View {
        PreloadedImage(urlString: urlString, contentMode: .fill)
            .frame(width: 56, height: 56)
            .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(AppTheme.background, lineWidth: 3)
        )
        .overlay(
            Circle()
                .strokeBorder(AppTheme.primaryAccent.opacity(0.3), lineWidth: 1)
        )
    }

    private var statsRow: some View {
        HStack(spacing: 24) {
            statBadge(value: "1K+", label: "App Ratings", icon: "star.fill")

            Rectangle()
                .fill(AppTheme.border)
                .frame(width: 1, height: 36)

            statBadge(value: "4.9", label: "Loved by users", icon: "heart.fill")
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardSurface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.border.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 32)
    }

    private func statBadge(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.orange)
                Text(value)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.muted)
        }
    }

    private var reviewsList: some View {
        VStack(spacing: 10) {
            ForEach(Array(reviews.enumerated()), id: \.offset) { index, review in
                reviewCard(name: review.name, text: review.text, imageUrl: profileImages[review.imageIndex])
            }
        }
        .padding(.horizontal, 24)
    }

    private func reviewCard(name: String, text: String, imageUrl: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                PreloadedImage(urlString: imageUrl, contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(AppTheme.orange)
                        }
                    }
                }

                Spacer()
            }

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(AppTheme.cardSurface.opacity(0.5))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.border.opacity(0.2), lineWidth: 1)
        )
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    buttonEnabled
                        ? AppTheme.accentGradient
                        : LinearGradient(colors: [Color(white: 0.25)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(.capsule)
                .shadow(color: buttonEnabled ? AppTheme.primaryAccent.opacity(0.4) : .clear, radius: 20, y: 6)
        }
        .disabled(!buttonEnabled)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func requestStoreReview() {
        guard !hasRequestedReview else { return }
        hasRequestedReview = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}
