import SwiftUI

struct BeforeAfterCompareView: View {
    @Bindable var vm: AppViewModel
    @State private var beforeIndex: Int = 0
    @State private var afterIndex: Int = 0
    @State private var sliderPosition: CGFloat = 0.5

    private var scansWithPhotos: [ScanResult] {
        vm.scanResults.filter { $0.hasPhoto }.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                if scansWithPhotos.count < 2 {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            comparisonSlider
                            scoreComparison
                            selectorSection
                            Color.clear.frame(height: 40)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Before & After")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if scansWithPhotos.count >= 2 {
                    beforeIndex = 0
                    afterIndex = scansWithPhotos.count - 1
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.muted)
            Text("Need 2+ Scans")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Complete at least 2 scans with photos\nto compare your progress")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var comparisonSlider: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h: CGFloat = 420

            ZStack {
                if let beforeImage = scansWithPhotos[safe: beforeIndex]?.loadImage() {
                    AppTheme.cardSurface
                        .overlay {
                            Image(uiImage: beforeImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 20))
                }

                if let afterImage = scansWithPhotos[safe: afterIndex]?.loadImage() {
                    AppTheme.cardSurface
                        .overlay {
                            Image(uiImage: afterImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 20))
                        .mask(
                            HStack(spacing: 0) {
                                Color.clear.frame(width: w * sliderPosition)
                                Color.black
                            }
                        )
                }

                Rectangle()
                    .fill(.white)
                    .frame(width: 3)
                    .position(x: w * sliderPosition, y: h / 2)
                    .shadow(color: .black.opacity(0.5), radius: 4)

                Circle()
                    .fill(.white)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "arrow.left.and.right")
                            .font(.caption.bold())
                            .foregroundStyle(.black)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 8)
                    .position(x: w * sliderPosition, y: h / 2)

                VStack {
                    HStack {
                        Text("BEFORE")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.black.opacity(0.6)))
                            .padding(12)
                        Spacer()
                        Text("AFTER")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.black.opacity(0.6)))
                            .padding(12)
                    }
                    Spacer()
                }
            }
            .frame(height: h)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        sliderPosition = max(0.05, min(0.95, value.location.x / w))
                    }
            )
        }
        .frame(height: 420)
    }

    private var scoreComparison: some View {
        Group {
            if let before = scansWithPhotos[safe: beforeIndex],
               let after = scansWithPhotos[safe: afterIndex] {
                let diff = after.overallScore - before.overallScore
                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("\(before.overallScore)")
                            .font(.system(size: 32, weight: .black, design: .default))
                            .foregroundStyle(.white)
                        Text(before.date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.title3.bold())
                            .foregroundStyle(diff >= 0 ? AppTheme.success : AppTheme.destructive)
                        Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundStyle(diff >= 0 ? AppTheme.success : AppTheme.destructive)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 6) {
                        Text("\(after.overallScore)")
                            .font(.system(size: 32, weight: .black, design: .default))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text(after.date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 18)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
                )
            }
        }
    }

    private var selectorSection: some View {
        VStack(spacing: 14) {
            Text("Select Photos")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                VStack(spacing: 8) {
                    Text("Before")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.muted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(scansWithPhotos.enumerated()), id: \.element.id) { index, scan in
                                selectorThumb(scan: scan, isSelected: index == beforeIndex) {
                                    withAnimation(.spring(duration: 0.3)) { beforeIndex = index }
                                }
                            }
                        }
                    }
                    .contentMargins(.horizontal, 0)
                }

                VStack(spacing: 8) {
                    Text("After")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.muted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(scansWithPhotos.enumerated()), id: \.element.id) { index, scan in
                                selectorThumb(scan: scan, isSelected: index == afterIndex) {
                                    withAnimation(.spring(duration: 0.3)) { afterIndex = index }
                                }
                            }
                        }
                    }
                    .contentMargins(.horizontal, 0)
                }
            }
        }
        .cardStyle()
    }

    private func selectorThumb(scan: ScanResult, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let img = scan.loadImage() {
                    AppTheme.cardSurface
                        .frame(width: 56, height: 72)
                        .overlay {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(isSelected ? AppTheme.primaryAccent : .clear, lineWidth: 2)
                        )
                }
                Text(scan.date, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.primaryAccent : AppTheme.muted)
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
