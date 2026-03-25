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
    private let imageCache: ImageCacheService

    init(
        service: RadioBrowserService = .shared,
        cache: StationCacheService = .shared,
        favoritesService: FavoritesService = .shared,
        historyService: HistoryService = .shared,
        imageCache: ImageCacheService = .shared
    ) {
        self.service = service
        self.cache = cache
        self.favoritesService = favoritesService
        self.historyService = historyService
        self.imageCache = imageCache
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        // Load local data (favorites + recents) immediately
        await loadLocalData()

        let localCountry = Locale.current.region?.identifier ?? "US"
        let localCacheKey = StationCacheService.localKey(countryCode: localCountry)

        // Load all cached home data in a single actor hop
        let cached = await cache.loadHomeData(localCountryCode: localCountry)

        if cached.hasData {
            localStations = cached.local ?? []
            topByClicks = cached.topClicks ?? []
            topByVotes = cached.topVotes ?? []
            recentlyChanged = cached.recentlyChanged ?? []
            currentlyPlaying = cached.currentlyPlaying ?? []
            isLoading = false

            // Pre-warm favicon memory cache from disk for visible stations
            let imageCache = self.imageCache
            let faviconURLs = (favoriteStations + recentStations + localStations
                + topByClicks + topByVotes).compactMap(\.faviconURL)
            Task { await imageCache.preWarmMemoryCache(for: Array(Set(faviconURLs))) }
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
            if !cached.hasData { error = appError }
        } catch let urlError as URLError {
            if !cached.hasData {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                    self.error = .networkUnavailable
                case .timedOut:
                    self.error = .serverError(statusCode: 408)
                default:
                    self.error = .networkUnavailable
                }
            }
        } catch {
            if !cached.hasData { self.error = .serverError(statusCode: 0) }
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
