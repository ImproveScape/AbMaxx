import SwiftUI

struct ExpandedPhotoView: View {
    let scan: ScanResult
    let weekIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let uiImage = scan.loadImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            }

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Week \(weekIndex)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Text(scan.date, format: .dateTime.month(.wide).day().year())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(scan.overallScore)")
                            .font(.system(size: 32, weight: .black, design: .default))
                            .foregroundStyle(AppTheme.scoreColor(for: scan.overallScore))
                        Text("Score")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)

                    ForEach(scan.regions, id: \.0) { name, score, _ in
                        VStack(spacing: 4) {
                            Text("\(score)")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                            Text(name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.black.opacity(0.6))
                .background(.ultraThinMaterial.opacity(0.3))
            }
        }
        .statusBarHidden()
    }
}
