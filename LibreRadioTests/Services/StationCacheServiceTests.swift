import XCTest
@testable import LibreRadio

final class StationCacheServiceTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var cache: StationCacheService!

    override func setUp() {
        suiteName = "test.cache.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        cache = StationCacheService(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Round-trip

    func testSaveAndLoadStations() async {
        let stations = [TestFixtures.makeStation(uuid: "1"), TestFixtures.makeStation(uuid: "2")]
        await cache.save(key: "test.stations", value: stations)

        let loaded: [StationDTO]? = await cache.load(key: "test.stations")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].stationuuid, "1")
        XCTAssertEqual(loaded?[1].stationuuid, "2")
    }

    func testSaveAndLoadCountries() async {
        let countries = [TestFixtures.makeCountry(name: "Argentina"), TestFixtures.makeCountry(name: "France"), TestFixtures.makeCountry(name: "Netherlands")]
        await cache.save(key: "test.countries", value: countries)

        let loaded: [Country]? = await cache.load(key: "test.countries")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 3)
        XCTAssertEqual(loaded?[0].name, "Argentina")
    }

    func testSaveAndLoadLanguages() async {
        let languages = [TestFixtures.makeLanguage(name: "english")]
        await cache.save(key: "test.languages", value: languages)

        let loaded: [Language]? = await cache.load(key: "test.languages")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?[0].name, "english")
    }

    func testSaveAndLoadTags() async {
        let tags = [TestFixtures.makeTag(name: "rock"), TestFixtures.makeTag(name: "pop")]
        await cache.save(key: "test.tags", value: tags)

        let loaded: [Tag]? = await cache.load(key: "test.tags")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].name, "rock")
    }

    // MARK: - Empty cache

    func testLoadReturnsNilForEmptyCache() async {
        let loaded: [StationDTO]? = await cache.load(key: "nonexistent")
        XCTAssertNil(loaded)
    }

    // MARK: - TTL expiry

    func testExpiredTTLReturnsNil() async {
        let expiredCache = StationCacheService(defaults: defaults, ttlSeconds: 0)
        let stations = [TestFixtures.makeStation()]
        await expiredCache.save(key: "test.expired", value: stations)

        let loaded: [StationDTO]? = await expiredCache.load(key: "test.expired")
        XCTAssertNil(loaded)
    }

    // MARK: - Clear

    func testClearRemovesSingleKey() async {
        await cache.save(key: "keep", value: [TestFixtures.makeStation(uuid: "keep")])
        await cache.save(key: "remove", value: [TestFixtures.makeStation(uuid: "remove")])

        await cache.clear(key: "remove")

        let kept: [StationDTO]? = await cache.load(key: "keep")
        let removed: [StationDTO]? = await cache.load(key: "remove")
        XCTAssertNotNil(kept)
        XCTAssertNil(removed)
    }

    func testClearAllRemovesAllKeys() async {
        await cache.save(key: "a", value: [TestFixtures.makeStation(uuid: "a")])
        await cache.save(key: "b", value: [TestFixtures.makeStation(uuid: "b")])

        await cache.clearAll()

        let a: [StationDTO]? = await cache.load(key: "a")
        let b: [StationDTO]? = await cache.load(key: "b")
        XCTAssertNil(a)
        XCTAssertNil(b)
    }

    // MARK: - Overwrite

    func testOverwriteReplacesData() async {
        await cache.save(key: "test", value: [TestFixtures.makeStation(uuid: "old")])
        await cache.save(key: "test", value: [TestFixtures.makeStation(uuid: "new")])

        let loaded: [StationDTO]? = await cache.load(key: "test")
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?[0].stationuuid, "new")
    }

    // MARK: - Key independence

    func testKeyIndependence() async {
        await cache.save(key: "key1", value: [TestFixtures.makeStation(uuid: "1")])
        await cache.save(key: "key2", value: [TestFixtures.makeStation(uuid: "2")])

        let loaded1: [StationDTO]? = await cache.load(key: "key1")
        let loaded2: [StationDTO]? = await cache.load(key: "key2")
        XCTAssertEqual(loaded1?[0].stationuuid, "1")
        XCTAssertEqual(loaded2?[0].stationuuid, "2")
    }

    // MARK: - Cross-instance persistence

    func testCrossInstancePersistence() async {
        await cache.save(key: "test", value: [TestFixtures.makeStation(uuid: "persisted")])

        let newCache = StationCacheService(defaults: defaults)
        let loaded: [StationDTO]? = await newCache.load(key: "test")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?[0].stationuuid, "persisted")
    }

    // MARK: - Corrupted data

    func testCorruptedDataReturnsNil() async {
        let dataKey = "libreradio.cache.corrupted"
        let timestampKey = dataKey + ".ts"
        defaults.set("not valid json".data(using: .utf8), forKey: dataKey)
        defaults.set(Date().timeIntervalSince1970, forKey: timestampKey)

        let loaded: [StationDTO]? = await cache.load(key: "corrupted")
        XCTAssertNil(loaded)
    }

    // MARK: - Batch Home Data Loading

    func testLoadHomeDataReturnsAllPopulatedKeys() async {
        let stations = [TestFixtures.makeStation(uuid: "home-1")]
        await cache.save(key: StationCacheService.localKey(countryCode: "US"), value: stations)
        await cache.save(key: StationCacheService.homeTopClicks, value: stations)
        await cache.save(key: StationCacheService.homeTopVotes, value: stations)
        await cache.save(key: StationCacheService.homeRecentlyChanged, value: stations)
        await cache.save(key: StationCacheService.homeCurrentlyPlaying, value: stations)

        let data = await cache.loadHomeData(localCountryCode: "US")

        XCTAssertTrue(data.hasData)
        XCTAssertEqual(data.local?.count, 1)
        XCTAssertEqual(data.topClicks?.count, 1)
        XCTAssertEqual(data.topVotes?.count, 1)
        XCTAssertEqual(data.recentlyChanged?.count, 1)
        XCTAssertEqual(data.currentlyPlaying?.count, 1)
        XCTAssertEqual(data.local?[0].stationuuid, "home-1")
    }

    func testLoadHomeDataReturnsAllNilsForEmptyCache() async {
        let data = await cache.loadHomeData(localCountryCode: "US")

        XCTAssertFalse(data.hasData)
        XCTAssertNil(data.local)
        XCTAssertNil(data.topClicks)
        XCTAssertNil(data.topVotes)
        XCTAssertNil(data.recentlyChanged)
        XCTAssertNil(data.currentlyPlaying)
    }

    func testLoadHomeDataWithPartialCache() async {
        let stations = [TestFixtures.makeStation(uuid: "partial")]
        await cache.save(key: StationCacheService.homeTopClicks, value: stations)
        await cache.save(key: StationCacheService.homeTopVotes, value: stations)

        let data = await cache.loadHomeData(localCountryCode: "US")

        XCTAssertTrue(data.hasData)
        XCTAssertNil(data.local)
        XCTAssertEqual(data.topClicks?.count, 1)
        XCTAssertEqual(data.topVotes?.count, 1)
        XCTAssertNil(data.recentlyChanged)
        XCTAssertNil(data.currentlyPlaying)
    }

    func testLoadHomeDataUsesCorrectCountryCode() async {
        let usStations = [TestFixtures.makeStation(uuid: "us")]
        let arStations = [TestFixtures.makeStation(uuid: "ar")]
        await cache.save(key: StationCacheService.localKey(countryCode: "US"), value: usStations)
        await cache.save(key: StationCacheService.localKey(countryCode: "AR"), value: arStations)

        let usData = await cache.loadHomeData(localCountryCode: "US")
        let arData = await cache.loadHomeData(localCountryCode: "AR")

        XCTAssertEqual(usData.local?[0].stationuuid, "us")
        XCTAssertEqual(arData.local?[0].stationuuid, "ar")
    }
}
