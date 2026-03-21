import Foundation

actor StationCacheService {
    static let shared = StationCacheService()

    private let keyPrefix = "libreradio.cache."
    private let ttlSeconds: TimeInterval
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, ttlSeconds: TimeInterval = 7 * 24 * 60 * 60) {
        self.defaults = defaults
        self.ttlSeconds = ttlSeconds
    }

    // MARK: - Cache Keys

    static let homeTopClicks = "homeTopClicks"
    static let homeTopVotes = "homeTopVotes"
    static let homeRecentlyChanged = "homeRecentlyChanged"
    static let homeCurrentlyPlaying = "homeCurrentlyPlaying"
    static let browseCountries = "browseCountries"
    static let browseLanguages = "browseLanguages"
    static let browseTags = "browseTags"

    static func localKey(countryCode: String) -> String {
        "homeLocal.\(countryCode)"
    }

    // MARK: - Public API

    func load<T: Decodable>(key: String) -> T? {
        let dataKey = keyPrefix + key
        let timestampKey = dataKey + ".ts"

        let timestamp = defaults.double(forKey: timestampKey)
        guard timestamp > 0,
              Date().timeIntervalSince1970 - timestamp < ttlSeconds,
              let data = defaults.data(forKey: dataKey) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Encodable>(key: String, value: T) {
        let dataKey = keyPrefix + key
        let timestampKey = dataKey + ".ts"

        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: dataKey)
        defaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
    }

    func clear(key: String) {
        let dataKey = keyPrefix + key
        let timestampKey = dataKey + ".ts"
        defaults.removeObject(forKey: dataKey)
        defaults.removeObject(forKey: timestampKey)
    }

    func clearAll() {
        let dict = defaults.dictionaryRepresentation()
        for key in dict.keys where key.hasPrefix(keyPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
