import UIKit
import Photos

struct SamplePhotoLoader {
    private static let hasLoadedKey = "hasLoadedSampleAbsPhoto"

    static func loadIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: hasLoadedKey) else { return }
        guard let image = UIImage(named: "sample_abs_photo") else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                if success {
                    UserDefaults.standard.set(true, forKey: hasLoadedKey)
                }
            }
        }
    }
}
