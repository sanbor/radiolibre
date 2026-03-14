import XCTest
@testable import RadioLibre

@MainActor
final class FavoritesViewModelTests: XCTestCase {

    private var defaults: UserDefaults!
    private var favoritesService: FavoritesService!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "FavoritesViewModelTests")!
        defaults.removePersistentDomain(forName: "FavoritesViewModelTests")

        let mockSession = TestFixtures.makeMockSession()
        let radioBrowser = RadioBrowserService(session: mockSession)
        favoritesService = FavoritesService(defaults: defaults, radioBrowserService: radioBrowser)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = "{\"ok\": true, \"message\": \"voted\"}".data(using: .utf8)!
            return (response, data)
        }
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "FavoritesViewModelTests")
        MockURLProtocol.requestHandler = nil
    }

    // MARK: - Initial State

    func testInitialState() {
        let vm = FavoritesViewModel(favoritesService: favoritesService)
        XCTAssertTrue(vm.favorites.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isSyncing)
        XCTAssertNil(vm.error)
    }

    // MARK: - Load

    func testLoadPopulatesFavorites() async {
        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await favoritesService.addFavorite(station: station)

        let vm = FavoritesViewModel(favoritesService: favoritesService)
        await vm.load()

        XCTAssertEqual(vm.favorites.count, 1)
        XCTAssertEqual(vm.favorites[0].stationuuid, "uuid-1")
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadEmptyFavorites() async {
        let vm = FavoritesViewModel(favoritesService: favoritesService)
        await vm.load()

        XCTAssertTrue(vm.favorites.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Add / Remove

    func testAddFavorite() async {
        let vm = FavoritesViewModel(favoritesService: favoritesService)
        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")

        await vm.addFavorite(station: station)

        XCTAssertEqual(vm.favorites.count, 1)
        XCTAssertEqual(vm.favorites[0].stationuuid, "uuid-1")
    }

    func testRemoveFavorite() async {
        let vm = FavoritesViewModel(favoritesService: favoritesService)
        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")

        await vm.addFavorite(station: station)
        XCTAssertEqual(vm.favorites.count, 1)

        await vm.removeFavorite(stationuuid: "uuid-1")
        XCTAssertTrue(vm.favorites.isEmpty)
    }

    // MARK: - isFavorite

    func testIsFavorite() async {
        let vm = FavoritesViewModel(favoritesService: favoritesService)
        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")

        await vm.addFavorite(station: station)

        XCTAssertTrue(vm.isFavorite(stationuuid: "uuid-1"))
        XCTAssertFalse(vm.isFavorite(stationuuid: "uuid-2"))
    }

    // MARK: - Move

    func testMoveFavorites() async {
        let fav1 = FavoriteStation(stationuuid: "uuid-1", name: "Station 1", urlResolved: "http://test/1", sortOrder: 0)
        let fav2 = FavoriteStation(stationuuid: "uuid-2", name: "Station 2", urlResolved: "http://test/2", sortOrder: 1)
        let fav3 = FavoriteStation(stationuuid: "uuid-3", name: "Station 3", urlResolved: "http://test/3", sortOrder: 2)
        await favoritesService.setFavorites([fav1, fav2, fav3])

        let vm = FavoritesViewModel(favoritesService: favoritesService)
        await vm.load()

        await vm.moveFavorites(from: IndexSet(integer: 2), to: 0)

        XCTAssertEqual(vm.favorites[0].stationuuid, "uuid-3")
        XCTAssertEqual(vm.favorites[1].stationuuid, "uuid-1")
        XCTAssertEqual(vm.favorites[2].stationuuid, "uuid-2")
    }

    // MARK: - Sync

    func testRefreshSyncsAndReloads() async {
        let fav = FavoriteStation(stationuuid: "uuid-1", name: "Old Name", urlResolved: "http://test/1", sortOrder: 0)
        await favoritesService.setFavorites([fav])

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = """
            [{"stationuuid": "uuid-1", "name": "New Name", "url": "http://test/1", "url_resolved": "http://test/1"}]
            """.data(using: .utf8)!
            return (response, data)
        }

        let vm = FavoritesViewModel(favoritesService: favoritesService)
        await vm.refresh()

        XCTAssertEqual(vm.favorites.count, 1)
        XCTAssertEqual(vm.favorites[0].name, "New Name")
        XCTAssertFalse(vm.isSyncing)
    }

    // MARK: - Concurrency Guard

    func testLoadGuardsAgainstConcurrency() async {
        let vm = FavoritesViewModel(favoritesService: favoritesService)
        vm.isLoading = true

        await vm.load()

        // Guard returned early, isLoading still true
        XCTAssertTrue(vm.isLoading)
    }

    func testRefreshGuardsAgainstConcurrency() async {
        let vm = FavoritesViewModel(favoritesService: favoritesService)
        vm.isSyncing = true

        await vm.refresh()

        // Guard returned early, isSyncing still true
        XCTAssertTrue(vm.isSyncing)
    }
}
