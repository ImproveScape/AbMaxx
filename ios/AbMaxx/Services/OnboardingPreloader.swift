import SwiftUI
import AVFoundation

@Observable
final class OnboardingPreloader {
    static let shared = OnboardingPreloader()

    private var imageCache: [String: UIImage] = [:]
    private var loadingURLs: Set<String> = []
    var videoAsset: AVAsset?

    static let allImageURLs: [String] = [
        "https://pub-e001eb4506b145aa938b5d3badbff6a5.r2.dev/attachments/w5vf0xmx5vbw4btfmh3sm.png",
        "https://pub-e001eb4506b145aa938b5d3badbff6a5.r2.dev/attachments/7zu0xrkayupf9dtypumm5.png",
        "https://r2-pub.rork.com/generated-images/f8e0ce5a-5b59-4fa1-b6d0-854f3c0139e0.png",
        "https://r2-pub.rork.com/generated-images/86a66552-1cd0-40d9-acf8-de636695e95f.png",
        "https://r2-pub.rork.com/generated-images/6c93158f-f261-4dd5-9fa6-8b157effa6b5.png",
        "https://r2-pub.rork.com/attachments/5w7fk2fm3wxzv0wlzhe0y.jpg",
        "https://r2-pub.rork.com/attachments/poyw0g4265wf1btqdlx24.jpg",
        "https://r2-pub.rork.com/attachments/r203f9lz3n4ld9m71zsxg.jpg",
        "https://r2-pub.rork.com/attachments/4hmwmqwasyxfm28uixzhu.jpg",
        "https://r2-pub.rork.com/projects/ef37pg3laezo1t2hj7mt0/assets/6b727322-5397-4f3d-a42d-c1601cd9210e.png",
        "https://r2-pub.rork.com/projects/ef37pg3laezo1t2hj7mt0/assets/26816233-f129-427e-920c-25245ea7785b.png"
    ]

    static let videoURL = "https://pub-e001eb4506b145aa938b5d3badbff6a5.r2.dev/attachments/qhlnprcialdv766s8a139.mov"

    func preloadAll() {
        for urlString in Self.allImageURLs {
            preloadImage(urlString)
        }
        preloadVideo()
    }

    func image(for urlString: String) -> UIImage? {
        imageCache[urlString]
    }

    private func preloadImage(_ urlString: String) {
        guard imageCache[urlString] == nil, !loadingURLs.contains(urlString) else { return }
        loadingURLs.insert(urlString)
        guard let url = URL(string: urlString) else { return }
        Task.detached(priority: .userInitiated) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.imageCache[urlString] = uiImage
                        self.loadingURLs.remove(urlString)
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadingURLs.remove(urlString)
                }
            }
        }
    }

    private func preloadVideo() {
        guard videoAsset == nil else { return }
        guard let url = URL(string: Self.videoURL) else { return }
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        Task.detached(priority: .userInitiated) {
            _ = try? await asset.load(.isPlayable)
            await MainActor.run {
                self.videoAsset = asset
            }
        }
    }
}

struct PreloadedImage: View {
    let urlString: String
    var contentMode: ContentMode = .fit

    @State private var preloader = OnboardingPreloader.shared

    var body: some View {
        if let uiImage = preloader.image(for: urlString) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            Color.clear
        }
    }
}
