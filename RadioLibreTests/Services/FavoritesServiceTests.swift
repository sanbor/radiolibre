import XCTest
@testable import RadioLibre

final class FavoritesServiceTests: XCTestCase {

    private var defaults: UserDefaults!
    private var service: FavoritesService!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "FavoritesServiceTests")!
        defaults.removePersistentDomain(forName: "FavoritesServiceTests")

        let mockSession = TestFixtures.makeMockSession()
        let radioBrowser = RadioBrowserService(session: mockSession)
        service = FavoritesService(defaults: defaults, radioBrowserService: radioBrowser)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "FavoritesServiceTests")
        MockURLProtocol.requestHandler = nil
    }

    // MARK: - Add

    func testAddFavorite() async {
        // Mock vote endpoint
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = """
            {"ok": true, "message": "voted"}
            """.data(using: .utf8)!
            return (response, data)
        }

        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await service.addFavorite(station: station)

        let favs = await service.allFavorites()
        XCTAssertEqual(favs.count, 1)
        XCTAssertEqual(favs[0].stationuuid, "uuid-1")
    }

    func testAddMultipleFavorites() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = "{\"ok\": true, \"message\": \"voted\"}".data(using: .utf8)!
            return (response, data)
        }

        let station1 = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        let station2 = TestFixtures.makeStation(uuid: "uuid-2", name: "Station 2")

        await service.addFavorite(station: station1)
        await service.addFavorite(station: station2)

        let favs = await service.allFavorites()
        XCTAssertEqual(favs.count, 2)
        // Most recently added should be first (sortOrder 0)
        XCTAssertEqual(favs[0].stationuuid, "uuid-2")
        XCTAssertEqual(favs[1].stationuuid, "uuid-1")
    }

    func testAddDuplicateIsIgnored() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = "{\"ok\": true, \"message\": \"voted\"}".data(using: .utf8)!
            return (response, data)
        }

        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await service.addFavorite(station: station)
        await service.addFavorite(station: station)

        let favs = await service.allFavorites()
        XCTAssertEqual(favs.count, 1)
    }

    // MARK: - Remove

    func testRemoveFavorite() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = "{\"ok\": true, \"message\": \"voted\"}".data(using: .utf8)!
            return (response, data)
        }

        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await service.addFavorite(station: station)
        await service.removeFavorite(stationuuid: "uuid-1")

        let favs = await service.allFavorites()
        XCTAssertTrue(favs.isEmpty)
    }

    func testRemoveNonExistentIsNoOp() async {
        await service.removeFavorite(stationuuid: "nonexistent")
        let favs = await service.allFavorites()
        XCTAssertTrue(favs.isEmpty)
    }

    // MARK: - isFavorite

    func testIsFavorite() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = "{\"ok\": true, \"message\": \"voted\"}".data(using: .utf8)!
            return (response, data)
        }

        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await service.addFavorite(station: station)

        let isFav = await service.isFavorite(stationuuid: "uuid-1")
        XCTAssertTrue(isFav)

        let isNotFav = await service.isFavorite(stationuuid: "uuid-2")
        XCTAssertFalse(isNotFav)
    }

    // MARK: - Reorder

    func testMoveFavorites() async {
        let fav1 = FavoriteStation(stationuuid: "uuid-1", name: "Station 1", urlResolved: "http://test/1", sortOrder: 0)
        let fav2 = FavoriteStation(stationuuid: "uuid-2", name: "Station 2", urlResolved: "http://test/2", sortOrder: 1)
        let fav3 = FavoriteStation(stationuuid: "uuid-3", name: "Station 3", urlResolved: "http://test/3", sortOrder: 2)
        await service.setFavorites([fav1, fav2, fav3])

        // Move last to first
        await service.moveFavorites(from: IndexSet(integer: 2), to: 0)

        let favs = await service.allFavorites()
        XCTAssertEqual(favs[0].stationuuid, "uuid-3")
        XCTAssertEqual(favs[1].stationuuid, "uuid-1")
        XCTAssertEqual(favs[2].stationuuid, "uuid-2")
    }

    // MARK: - Persistence

    func testPersistenceAcrossInstances() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = "{\"ok\": true, \"message\": \"voted\"}".data(using: .utf8)!
            return (response, data)
        }

        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await service.addFavorite(station: station)

        let mockSession = TestFixtures.makeMockSession()
        let radioBrowser = RadioBrowserService(session: mockSession)
        let service2 = FavoritesService(defaults: defaults, radioBrowserService: radioBrowser)
        let favs = await service2.allFavorites()
        XCTAssertEqual(favs.count, 1)
        XCTAssertEqual(favs[0].stationuuid, "uuid-1")
    }

    func testEmptyFavoritesOnFreshDefaults() async {
        let favs = await service.allFavorites()
        XCTAssertTrue(favs.isEmpty)
    }

    // MARK: - Auto-Vote

    func testAddFavoriteFiresVote() async {
        var voteRequestURL: String?

        MockURLProtocol.requestHandler = { request in
            let url = request.url!.absoluteString
            if url.contains("/json/vote/") {
                voteRequestURL = url
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = "{\"ok\": true, \"message\": \"voted\"}".data(using: .utf8)!
            return (response, data)
        }

        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await service.addFavorite(station: station)

        // Give fire-and-forget task a moment to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(voteRequestURL)
        XCTAssertTrue(voteRequestURL?.contains("uuid-1") ?? false)
    }

    // MARK: - Sync

    func testSyncUpdatesMetadata() async {
        let fav = FavoriteStation(
            stationuuid: "uuid-1",
            name: "Old Name",
            urlResolved: "http://old.test/stream",
            codec: "MP3",
            bitrate: 128,
            sortOrder: 0
        )
        await service.setFavorites([fav])

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = """
            [{"stationuuid": "uuid-1", "name": "New Name", "url": "http://new.test/stream", "url_resolved": "http://new.test/stream", "codec": "AAC", "bitrate": 256, "tags": "jazz"}]
            """.data(using: .utf8)!
            return (response, data)
        }

        await service.syncWithServer()

        let favs = await service.allFavorites()
        XCTAssertEqual(favs.count, 1)
        XCTAssertEqual(favs[0].name, "New Name")
        XCTAssertEqual(favs[0].codec, "AAC")
        XCTAssertEqual(favs[0].bitrate, 256)
    }

    func testSyncRemovesStaleFavorites() async {
        let fav1 = FavoriteStation(stationuuid: "uuid-1", name: "Station 1", urlResolved: "http://test/1", sortOrder: 0)
        let fav2 = FavoriteStation(stationuuid: "uuid-2", name: "Station 2", urlResolved: "http://test/2", sortOrder: 1)
        await service.setFavorites([fav1, fav2])

        // Server only returns uuid-1
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = """
            [{"stationuuid": "uuid-1", "name": "Station 1", "url": "http://test/1", "url_resolved": "http://test/1"}]
            """.data(using: .utf8)!
            return (response, data)
        }

        await service.syncWithServer()

        let favs = await service.allFavorites()
        XCTAssertEqual(favs.count, 1)
        XCTAssertEqual(favs[0].stationuuid, "uuid-1")
    }

    func testSyncPreservesDataOnNetworkError() async {
        let fav = FavoriteStation(stationuuid: "uuid-1", name: "Station 1", urlResolved: "http://test/1", sortOrder: 0)
        await service.setFavorites([fav])

        MockURLProtocol.requestHandler = { request in
            throw URLError(.notConnectedToInternet)
        }

        await service.syncWithServer()

        let favs = await service.allFavorites()
        XCTAssertEqual(favs.count, 1, "Should preserve favorites on sync failure")
    }
}
