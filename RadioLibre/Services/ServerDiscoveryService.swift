import Foundation

actor ServerDiscoveryService {
    static let shared = ServerDiscoveryService()

    private var servers: [String] = []
    private var currentIndex: Int = 0
    private var lastResolved: Date?
    private let ttl: TimeInterval = 86400 // 24 hours

    private let defaults: UserDefaults
    private let cacheServersKey = "radio_browser_servers"
    private let cacheTimestampKey = "radio_browser_servers_ts"

    private let dnsResolver: () async throws -> [String]

    init(
        defaults: UserDefaults = .standard,
        dnsResolver: @escaping @Sendable () async throws -> [String] = DNSResolver.resolveRadioBrowserServers
    ) {
        self.defaults = defaults
        self.dnsResolver = dnsResolver
    }

    var currentBaseURL: URL {
        guard !servers.isEmpty else {
            return URL(string: "https://de1.api.radio-browser.info")!
        }
        let host = servers[currentIndex % servers.count]
        return URL(string: "https://\(host)")!
    }

    func resolveIfNeeded() async {
        if let lastResolved, Date().timeIntervalSince(lastResolved) < ttl, !servers.isEmpty {
            return
        }

        if loadFromCache() {
            return
        }

        do {
            let resolved = try await dnsResolver()
            if !resolved.isEmpty {
                servers = resolved.shuffled()
                currentIndex = 0
                lastResolved = Date()
                saveToCache()
            }
        } catch {
            // DNS failed — keep any previously loaded servers
        }
    }

    func rotateServer() {
        guard servers.count > 1 else { return }
        currentIndex = (currentIndex + 1) % servers.count
    }

    // MARK: - UserDefaults Cache

    private func loadFromCache() -> Bool {
        guard let cached = defaults.stringArray(forKey: cacheServersKey),
              !cached.isEmpty,
              let timestamp = defaults.object(forKey: cacheTimestampKey) as? Date,
              Date().timeIntervalSince(timestamp) < ttl else {
            return false
        }
        servers = cached
        currentIndex = 0
        lastResolved = timestamp
        return true
    }

    private func saveToCache() {
        defaults.set(servers, forKey: cacheServersKey)
        defaults.set(lastResolved, forKey: cacheTimestampKey)
    }

    // MARK: - Testing Support

    /// Replaces servers with provided list. For testing only.
    func setServers(_ newServers: [String]) {
        servers = newServers
        currentIndex = 0
        lastResolved = Date()
    }

    /// Clears cached state. For testing only.
    func clearState() {
        servers = []
        currentIndex = 0
        lastResolved = nil
    }
}
