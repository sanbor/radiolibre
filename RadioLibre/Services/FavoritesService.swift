import Foundation

actor FavoritesService {
    static let shared = FavoritesService()

    private let userDefaultsKey = "radiolibre.favorites"
    private let defaults: UserDefaults
    private let radioBrowserService: RadioBrowserService

    private var favorites: [FavoriteStation] = []
    private var loaded = false

    init(defaults: UserDefaults = .standard, radioBrowserService: RadioBrowserService = .shared) {
        self.defaults = defaults
        self.radioBrowserService = radioBrowserService
    }

    // MARK: - Public API

    func allFavorites() -> [FavoriteStation] {
        loadIfNeeded()
        return favorites.sorted { $0.sortOrder < $1.sortOrder }
    }

    func isFavorite(stationuuid: String) -> Bool {
        loadIfNeeded()
        return favorites.contains { $0.stationuuid == stationuuid }
    }

    func addFavorite(station: StationDTO) {
        loadIfNeeded()

        // Dedup: don't add if already favorited
        guard !favorites.contains(where: { $0.stationuuid == station.stationuuid }) else { return }

        // Bump all existing sort orders
        for i in favorites.indices {
            favorites[i].sortOrder += 1
        }

        let favorite = FavoriteStation(from: station, sortOrder: 0)
        favorites.insert(favorite, at: 0)
        save()

        // Fire-and-forget vote
        Task {
            _ = try? await radioBrowserService.vote(stationuuid: station.stationuuid)
        }
    }

    func removeFavorite(stationuuid: String) {
        loadIfNeeded()
        favorites.removeAll { $0.stationuuid == stationuuid }
        reindexSortOrder()
        save()
    }

    func moveFavorites(from source: IndexSet, to destination: Int) {
        loadIfNeeded()
        var sorted = favorites.sorted { $0.sortOrder < $1.sortOrder }
        sorted.move(fromOffsets: source, toOffset: destination)
        // Assign new sortOrder values based on post-move positions
        favorites = sorted.enumerated().map { (index, fav) in
            var updated = fav
            updated.sortOrder = index
            return updated
        }
        save()
    }

    func syncWithServer() async {
        loadIfNeeded()
        guard !favorites.isEmpty else { return }

        let uuids = favorites.map(\.stationuuid)
        do {
            let serverStations = try await radioBrowserService.fetchStations(uuids: uuids)
            let serverMap = Dictionary(serverStations.map { ($0.stationuuid, $0) }, uniquingKeysWith: { first, _ in first })

            var updated: [FavoriteStation] = []
            for var fav in favorites {
                if let serverStation = serverMap[fav.stationuuid] {
                    // Update metadata from server
                    fav = FavoriteStation(
                        id: fav.id,
                        stationuuid: fav.stationuuid,
                        name: serverStation.name,
                        urlResolved: serverStation.urlResolved ?? serverStation.url,
                        faviconURL: serverStation.favicon,
                        tags: serverStation.tags,
                        countrycode: serverStation.countrycode,
                        language: serverStation.language,
                        codec: serverStation.codec,
                        bitrate: serverStation.bitrate ?? 0,
                        addedAt: fav.addedAt,
                        sortOrder: fav.sortOrder
                    )
                    updated.append(fav)
                }
                // Stale favorites (not on server) are removed
            }

            favorites = updated
            save()
        } catch {
            // Sync is best-effort — keep existing data on failure
        }
    }

    /// For testing
    func setFavorites(_ newFavorites: [FavoriteStation]) {
        favorites = newFavorites
        loaded = true
        save()
    }

    // MARK: - Persistence

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true

        guard let data = defaults.data(forKey: userDefaultsKey) else { return }
        do {
            favorites = try JSONDecoder().decode([FavoriteStation].self, from: data)
        } catch {
            favorites = []
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        defaults.set(data, forKey: userDefaultsKey)
    }

    private func reindexSortOrder() {
        let sorted = favorites.sorted { $0.sortOrder < $1.sortOrder }
        favorites = sorted.enumerated().map { (index, fav) in
            var updated = fav
            updated.sortOrder = index
            return updated
        }
    }
}
