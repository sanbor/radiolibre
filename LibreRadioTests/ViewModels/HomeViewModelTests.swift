import XCTest
@testable import LibreRadio

@MainActor
final class HomeViewModelTests: XCTestCase {

    private var discovery: ServerDiscoveryService!
    private var service: RadioBrowserService!
    private var suiteName: String!
    private var cache: StationCacheService!
    private var favoritesService: FavoritesService!
    private var historyService: HistoryService!

    override func setUp() async throws {
        discovery = ServerDiscoveryService()
        await discovery.setServers(["mock.api.radio-browser.info"])

        let session = TestFixtures.makeMockSession()
        service = RadioBrowserService(discovery: discovery, session: session)

        suiteName = "test.home.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        cache = StationCacheService(defaults: testDefaults)
        favoritesService = FavoritesService(defaults: testDefaults, radioBrowserService: service)
        historyService = HistoryService(defaults: testDefaults)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        if let suiteName = suiteName {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
    }

    func testLoadPopulatesAllSections() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 2).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
        XCTAssertEqual(vm.topByClicks.count, 2)
        XCTAssertEqual(vm.topByVotes.count, 2)
        XCTAssertEqual(vm.localStations.count, 2)
        XCTAssertEqual(vm.recentlyChanged.count, 2)
        XCTAssertEqual(vm.currentlyPlaying.count, 2)
    }

    func testLoadSetsErrorOnFailure() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.error)
    }

    func testLoadSetsErrorForServerError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertNotNil(vm.error)
    }

    func testRefreshReloadsData() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()
        let firstCallCount = callCount
        XCTAssertGreaterThan(firstCallCount, 0)

        await vm.refresh()
        XCTAssertGreaterThan(callCount, firstCallCount)
    }

    func testLoadGuardsAgainstConcurrency() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        vm.isLoading = true // simulate already loading

        // Should return immediately due to guard
        await vm.load()

        // isLoading still true because guard returned early
        XCTAssertTrue(vm.isLoading)
    }

    func testInitialState() {
        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)

        XCTAssertTrue(vm.favoriteStations.isEmpty)
        XCTAssertTrue(vm.recentStations.isEmpty)
        XCTAssertTrue(vm.localStations.isEmpty)
        XCTAssertTrue(vm.topByClicks.isEmpty)
        XCTAssertTrue(vm.topByVotes.isEmpty)
        XCTAssertTrue(vm.recentlyChanged.isEmpty)
        XCTAssertTrue(vm.currentlyPlaying.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    // MARK: - Cache Tests

    func testCachedDataShownOnNetworkFailure() async {
        let stations = [TestFixtures.makeStation(uuid: "cached-1", name: "Cached Station")]
        let localCountry = Locale.current.region?.identifier ?? "US"
        await cache.save(key: StationCacheService.localKey(countryCode: localCountry), value: stations)
        await cache.save(key: StationCacheService.homeTopClicks, value: stations)
        await cache.save(key: StationCacheService.homeTopVotes, value: stations)
        await cache.save(key: StationCacheService.homeRecentlyChanged, value: stations)
        await cache.save(key: StationCacheService.homeCurrentlyPlaying, value: stations)

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.topByClicks.count, 1)
        XCTAssertEqual(vm.topByClicks[0].name, "Cached Station")
        XCTAssertNil(vm.error)
        XCTAssertFalse(vm.isLoading)
    }

    func testFreshDataReplacesCachedData() async {
        let oldStations = [TestFixtures.makeStation(uuid: "old-1", name: "Old Station")]
        let localCountry = Locale.current.region?.identifier ?? "US"
        await cache.save(key: StationCacheService.localKey(countryCode: localCountry), value: oldStations)
        await cache.save(key: StationCacheService.homeTopClicks, value: oldStations)
        await cache.save(key: StationCacheService.homeTopVotes, value: oldStations)
        await cache.save(key: StationCacheService.homeRecentlyChanged, value: oldStations)
        await cache.save(key: StationCacheService.homeCurrentlyPlaying, value: oldStations)

        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 3).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.topByClicks.count, 3)
        XCTAssertFalse(vm.isLoading)
    }

    func testCacheUpdatedAfterSuccessfulFetch() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 2).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        let cached: [StationDTO]? = await cache.load(key: StationCacheService.homeTopClicks)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 2)
    }

    func testNetworkFailureWithoutCacheShowsError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertNotNil(vm.error)
        XCTAssertTrue(vm.localStations.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Favorites & Recents Tests

    func testLoadShowsFavorites() async {
        let station = TestFixtures.makeStation(uuid: "fav-1", name: "Favorite Radio")
        await favoritesService.addFavorite(station: station)

        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.favoriteStations.count, 1)
        XCTAssertEqual(vm.favoriteStations[0].name, "Favorite Radio")
    }

    func testLoadShowsRecentStations() async {
        let station = TestFixtures.makeStation(uuid: "recent-1", name: "Recent Radio")
        await historyService.recordPlay(station: station)

        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.recentStations.count, 1)
        XCTAssertEqual(vm.recentStations[0].name, "Recent Radio")
    }

    func testLoadWithNoFavoritesOrRecents() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertTrue(vm.favoriteStations.isEmpty)
        XCTAssertTrue(vm.recentStations.isEmpty)
        XCTAssertFalse(vm.topByClicks.isEmpty)
    }

    func testRefreshReloadsFavoritesAndRecents() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertTrue(vm.favoriteStations.isEmpty)

        // Add a favorite after initial load
        let station = TestFixtures.makeStation(uuid: "fav-new", name: "New Favorite")
        await favoritesService.addFavorite(station: station)

        await vm.refresh()

        XCTAssertEqual(vm.favoriteStations.count, 1)
        XCTAssertEqual(vm.favoriteStations[0].name, "New Favorite")
    }

    func testRecentStationsDeduplicatedByStationUUID() async {
        // Play the same station twice with different HistoryEntry IDs
        // (simulating plays >30 min apart by manipulating the service directly)
        let station = TestFixtures.makeStation(uuid: "dup-station", name: "Duplicate Station")
        let entry1 = HistoryEntry(
            stationuuid: "dup-station", name: "Duplicate Station",
            urlResolved: "http://stream.test/resolved",
            playedAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        let entry2 = HistoryEntry(
            stationuuid: "dup-station", name: "Duplicate Station",
            urlResolved: "http://stream.test/resolved",
            playedAt: Date() // now
        )
        let otherEntry = HistoryEntry(
            stationuuid: "other-station", name: "Other Station",
            urlResolved: "http://stream.test/other",
            playedAt: Date().addingTimeInterval(-1800) // 30 min ago
        )
        // Insert entries directly: most recent first
        await historyService.setEntries([entry2, otherEntry, entry1])

        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        // Should have 2 unique stations, not 3 (duplicate removed)
        XCTAssertEqual(vm.recentStations.count, 2)
        // First entry should be the most recent play of the duplicate
        XCTAssertEqual(vm.recentStations[0].stationuuid, "dup-station")
        XCTAssertEqual(vm.recentStations[1].stationuuid, "other-station")
    }

    func testFavoriteStationsHaveNoDuplicateIDs() async {
        // Adding the same station twice should be deduplicated by FavoritesService
        let station = TestFixtures.makeStation(uuid: "fav-dup", name: "Dup Favorite")
        await favoritesService.addFavorite(station: station)
        await favoritesService.addFavorite(station: station) // duplicate add

        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.favoriteStations.count, 1)
        let ids = vm.favoriteStations.map(\.stationuuid)
        XCTAssertEqual(ids.count, Set(ids).count, "Favorite stations must have unique stationuuids for ForEach")
    }

    func testFavoritesAndRecentsLoadEvenOnNetworkFailure() async {
        let favStation = TestFixtures.makeStation(uuid: "fav-offline", name: "Offline Favorite")
        let recentStation = TestFixtures.makeStation(uuid: "recent-offline", name: "Offline Recent")
        await favoritesService.addFavorite(station: favStation)
        await historyService.recordPlay(station: recentStation)

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        // Favorites and recents should still load from local storage
        XCTAssertEqual(vm.favoriteStations.count, 1)
        XCTAssertEqual(vm.recentStations.count, 1)
    }

    func testRecentStationsExcludeFavorites() async {
        let favStation = TestFixtures.makeStation(uuid: "both-1", name: "Both Fav and Recent")
        let recentOnly = TestFixtures.makeStation(uuid: "recent-only-1", name: "Recent Only")
        await favoritesService.addFavorite(station: favStation)
        await historyService.recordPlay(station: favStation)
        await historyService.recordPlay(station: recentOnly)

        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.favoriteStations.count, 1)
        XCTAssertEqual(vm.recentStations.count, 1)
        XCTAssertEqual(vm.recentStations[0].stationuuid, "recent-only-1")
    }

    func testRecentSectionEmptyWhenAllRecentsAreFavorites() async {
        let station1 = TestFixtures.makeStation(uuid: "all-fav-1", name: "Fav 1")
        let station2 = TestFixtures.makeStation(uuid: "all-fav-2", name: "Fav 2")
        await favoritesService.addFavorite(station: station1)
        await favoritesService.addFavorite(station: station2)
        await historyService.recordPlay(station: station1)
        await historyService.recordPlay(station: station2)

        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = HomeViewModel(service: service, cache: cache, favoritesService: favoritesService, historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.favoriteStations.count, 2)
        XCTAssertTrue(vm.recentStations.isEmpty)
    }
}
