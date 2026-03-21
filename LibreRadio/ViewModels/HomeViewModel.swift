import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var favoriteStations: [StationDTO] = []
    @Published var recentStations: [StationDTO] = []
    @Published var localStations: [StationDTO] = []
    @Published var topByClicks: [StationDTO] = []
    @Published var topByVotes: [StationDTO] = []
    @Published var recentlyChanged: [StationDTO] = []
    @Published var currentlyPlaying: [StationDTO] = []
    @Published var isLoading = false
    @Published var error: AppError?

    private let service: RadioBrowserService
    private let cache: StationCacheService
    private let favoritesService: FavoritesService
    private let historyService: HistoryService

    init(
        service: RadioBrowserService = .shared,
        cache: StationCacheService = .shared,
        favoritesService: FavoritesService = .shared,
        historyService: HistoryService = .shared
    ) {
        self.service = service
        self.cache = cache
        self.favoritesService = favoritesService
        self.historyService = historyService
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        // Load local data (favorites + recents) immediately
        await loadLocalData()

        let localCountry = Locale.current.region?.identifier ?? "US"
        let localCacheKey = StationCacheService.localKey(countryCode: localCountry)

        // Load from cache first
        let cachedLocal: [StationDTO]? = await cache.load(key: localCacheKey)
        let cachedClicks: [StationDTO]? = await cache.load(key: StationCacheService.homeTopClicks)
        let cachedVotes: [StationDTO]? = await cache.load(key: StationCacheService.homeTopVotes)
        let cachedChanged: [StationDTO]? = await cache.load(key: StationCacheService.homeRecentlyChanged)
        let cachedPlaying: [StationDTO]? = await cache.load(key: StationCacheService.homeCurrentlyPlaying)

        let hasCache = cachedLocal != nil || cachedClicks != nil || cachedVotes != nil
            || cachedChanged != nil || cachedPlaying != nil

        if hasCache {
            localStations = cachedLocal ?? []
            topByClicks = cachedClicks ?? []
            topByVotes = cachedVotes ?? []
            recentlyChanged = cachedChanged ?? []
            currentlyPlaying = cachedPlaying ?? []
        }

        // Always fetch fresh data
        do {
            async let local = service.fetchLocalStations(countrycode: localCountry, limit: 20)
            async let clicks = service.fetchTopByClicks(limit: 20)
            async let votes = service.fetchTopByVotes(limit: 20)
            async let changed = service.fetchLastChange(limit: 20)
            async let playing = service.fetchLastClick(limit: 20)

            localStations = try await local
            topByClicks = try await clicks
            topByVotes = try await votes
            recentlyChanged = try await changed
            currentlyPlaying = try await playing

            // Update cache
            await cache.save(key: localCacheKey, value: localStations)
            await cache.save(key: StationCacheService.homeTopClicks, value: topByClicks)
            await cache.save(key: StationCacheService.homeTopVotes, value: topByVotes)
            await cache.save(key: StationCacheService.homeRecentlyChanged, value: recentlyChanged)
            await cache.save(key: StationCacheService.homeCurrentlyPlaying, value: currentlyPlaying)
        } catch let appError as AppError {
            if !hasCache { error = appError }
        } catch {
            if !hasCache { self.error = .networkUnavailable }
        }

        isLoading = false
    }

    func refresh() async {
        isLoading = false // allow re-entry
        await load()
    }

    private func loadLocalData() async {
        let favorites = await favoritesService.allFavorites()
        favoriteStations = favorites.map { $0.toStationDTO() }

        let recents = await historyService.recentEntries(limit: 10)
        // Deduplicate by stationuuid — history can have repeats of the same station,
        // and StationDTO.id == stationuuid, so duplicates break ForEach rendering.
        var seen = Set<String>()
        recentStations = recents.compactMap { entry -> StationDTO? in
            let dto = entry.toStationDTO()
            guard seen.insert(dto.stationuuid).inserted else { return nil }
            return dto
        }

        // Remove stations already shown in Favorites
        let favoriteIDs = Set(favoriteStations.map(\.stationuuid))
        recentStations.removeAll { favoriteIDs.contains($0.stationuuid) }
    }
}
