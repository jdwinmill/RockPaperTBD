import UIKit

enum StorageBucketConfig {
    // TODO: Replace with your Firebase Storage bucket name (from GoogleService-Info.plist STORAGE_BUCKET)
    static let bucket = "YOUR_PROJECT.firebasestorage.app"
}

@Observable
final class PackImageCache {
    private(set) var cachedPacks: Set<String> = []
    private(set) var downloadingPacks: Set<String> = []

    private let cacheDir: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDir = caches.appendingPathComponent("character-packs", isDirectory: true)
        scanCachedPacks()
    }

    // MARK: - Image Access

    func image(named imageName: String, packId: String) -> UIImage? {
        let url = imageURL(imageName: imageName, packId: packId)
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: - Download

    func downloadPack(_ packId: String, imageNames: [String]) async {
        guard !downloadingPacks.contains(packId) else { return }
        downloadingPacks.insert(packId)

        let packDir = cacheDir.appendingPathComponent(packId, isDirectory: true)
        try? FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)

        await withTaskGroup(of: Void.self) { group in
            for name in imageNames {
                group.addTask {
                    await self.downloadImage(name: name, packId: packId)
                }
            }
        }

        cachedPacks.insert(packId)
        downloadingPacks.remove(packId)
    }

    // MARK: - Delete

    func deletePack(_ packId: String) {
        let packDir = cacheDir.appendingPathComponent(packId, isDirectory: true)
        try? FileManager.default.removeItem(at: packDir)
        cachedPacks.remove(packId)
    }

    func deleteAll() {
        try? FileManager.default.removeItem(at: cacheDir)
        cachedPacks.removeAll()
    }

    // MARK: - Private

    private func imageURL(imageName: String, packId: String) -> URL {
        cacheDir
            .appendingPathComponent(packId, isDirectory: true)
            .appendingPathComponent("\(imageName).png")
    }

    private func downloadImage(name: String, packId: String) async {
        let destination = imageURL(imageName: name, packId: packId)
        guard !FileManager.default.fileExists(atPath: destination.path) else { return }

        let encodedPath = "character-packs%2F\(packId)%2F\(name).png"
        let remoteURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/\(StorageBucketConfig.bucket)/o/\(encodedPath)?alt=media")!
        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            try data.write(to: destination, options: .atomic)
        } catch {
            print("PackImageCache: failed to download \(name) for \(packId): \(error)")
        }
    }

    private func scanCachedPacks() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: nil
        ) else { return }

        for dir in contents where dir.hasDirectoryPath {
            let packId = dir.lastPathComponent
            if let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path),
               !files.isEmpty {
                cachedPacks.insert(packId)
            }
        }
    }
}
