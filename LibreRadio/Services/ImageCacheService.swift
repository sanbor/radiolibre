import CryptoKit
import UIKit

actor ImageCacheService {
    static let shared = ImageCacheService()

    private static let memoryCacheLimit = 200

    nonisolated(unsafe) private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = memoryCacheLimit
        return cache
    }()

    private let cacheDirectory: URL
    private let session: URLSession
    private var directoryCreated = false

    init(
        session: URLSession = .shared,
        cacheDirectory: URL? = nil
    ) {
        self.session = session
        if let cacheDirectory {
            self.cacheDirectory = cacheDirectory
        } else {
            guard let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                fatalError("ImageCacheService: system caches directory unavailable")
            }
            self.cacheDirectory = cachesDir.appendingPathComponent("favicons", isDirectory: true)
        }
    }

    // MARK: - Public API

    func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)

        // Memory
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        // Disk
        let diskPath = diskURL(for: key)
        if let data = try? Data(contentsOf: diskPath), let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }

        // Network
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                return nil
            }
            memoryCache.setObject(image, forKey: key as NSString)
            saveToDisk(data: data, key: key)
            return image
        } catch {
            return nil
        }
    }

    nonisolated func cachedImage(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)
        return memoryCache.object(forKey: key as NSString)
    }

    // MARK: - Private

    nonisolated private func cacheKey(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func diskURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key)
    }

    private func saveToDisk(data: Data, key: String) {
        ensureDirectory()
        let fileURL = diskURL(for: key)
        try? data.write(to: fileURL, options: .atomic)
    }

    private func ensureDirectory() {
        guard !directoryCreated else { return }
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        directoryCreated = true
    }
}
