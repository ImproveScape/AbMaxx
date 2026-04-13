import SwiftUI

struct RedMotivationPageView: View {
    let currentPage: Int
    let totalPages: Int
    let onBack: () -> Void
    let onNext: () -> Void

    private let redBG = Color(red: 0.90, green: 0.22, blue: 0.17)

    private var pageData: (title: String, subtitle: String, stat: String, imageURL: String) {
        switch currentPage {
        case 0:
            return (
                "Habit Tracking",
                "Feeling Burnt Out",
                "Those who don't track their habits are 68%\nmore likely to burn out",
                "https://r2-pub.rork.com/generated-images/f8e0ce5a-5b59-4fa1-b6d0-854f3c0139e0.png"
            )
        case 1:
            return (
                "Goal Tracking",
                "Falling Short",
                "People who never track their goals are 40%\nless likely to reach them",
                "https://r2-pub.rork.com/generated-images/86a66552-1cd0-40d9-acf8-de636695e95f.png"
            )
        case 2:
            return (
                "Progress Tracking",
                "Feeling Lost",
                "Those who don't measure their progress are 2x\nlikely to feel lost",
                "https://r2-pub.rork.com/generated-images/6c93158f-f261-4dd5-9fa6-8b157effa6b5.png"
            )
        default:
            return ("", "", "", "")
        }
    }

    var body: some View {
        if currentPage == 3 {
            disciplinePathSlide
        } else {
            standardSlide
        }
    }

    private var standardSlide: some View {
        ZStack {
            redBG.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer()
                    .frame(minHeight: 12, maxHeight: 40)

                Text(pageData.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)

                Text(pageData.subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.18))
                    )
                    .padding(.top, 8)

                Spacer()
                    .frame(minHeight: 16, maxHeight: 32)

                PreloadedImage(urlString: pageData.imageURL)
                    .frame(maxHeight: 280)
                    .padding(.horizontal, 40)

                Spacer()
                    .frame(minHeight: 16, maxHeight: 32)

                Text(pageData.stat)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)

                Spacer()

                Button(action: onNext) {
                    HStack(spacing: 8) {
                        Text("Next")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 52)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(.white)
                    )
                }
                .padding(.bottom, 16)

                pageDots
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var disciplinePathSlide: some View {
        GrowthChartSlide(onBack: onBack, onNext: onNext, currentPage: currentPage, totalPages: totalPages)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(index == currentPage ? 1.0 : 0.35))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
