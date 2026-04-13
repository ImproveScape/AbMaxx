import UIKit

nonisolated enum PhotoStorageService {
    private static var photosDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ScanPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func savePhoto(_ data: Data, fileName: String) {
        let url = photosDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
    }

    static func loadPhoto(fileName: String) -> Data? {
        let url = photosDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: url)
    }

    static func loadImage(fileName: String) -> UIImage? {
        guard let data = loadPhoto(fileName: fileName) else { return nil }
        return UIImage(data: data)
    }

    static func deletePhoto(fileName: String) {
        let url = photosDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    static func generateFileName() -> String {
        "scan_\(UUID().uuidString).jpg"
    }

    static func deleteAllPhotos() {
        let dir = photosDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        for file in files {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
        }
    }
}
