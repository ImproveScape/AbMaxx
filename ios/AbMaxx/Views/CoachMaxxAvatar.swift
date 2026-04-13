import SwiftUI

struct CoachMaxxAvatar: View {
    var size: CGFloat = 32

    private static let imageURL = "https://r2-pub.rork.com/projects/ef37pg3laezo1t2hj7mt0/assets/40968ebc-ef5c-443d-b9cb-66bb030c3ab6.png"

    var body: some View {
        AsyncImage(url: URL(string: Self.imageURL)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "figure.core.training")
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryAccent)
            }
        }
        .frame(width: size, height: size)
    }
}
