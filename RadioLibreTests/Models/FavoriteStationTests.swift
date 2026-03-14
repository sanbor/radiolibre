import XCTest
@testable import RadioLibre

final class FavoriteStationTests: XCTestCase {

    // MARK: - Init

    func testInitWithDefaults() {
        let fav = FavoriteStation(
            stationuuid: "uuid-1",
            name: "Test Radio",
            urlResolved: "http://stream.test/live"
        )

        XCTAssertEqual(fav.stationuuid, "uuid-1")
        XCTAssertEqual(fav.name, "Test Radio")
        XCTAssertEqual(fav.urlResolved, "http://stream.test/live")
        XCTAssertNil(fav.faviconURL)
        XCTAssertNil(fav.tags)
        XCTAssertNil(fav.countrycode)
        XCTAssertNil(fav.language)
        XCTAssertNil(fav.codec)
        XCTAssertEqual(fav.bitrate, 0)
        XCTAssertEqual(fav.sortOrder, 0)
    }

    func testInitFromStationDTO() {
        let station = StationDTOTests.makeStation(
            uuid: "uuid-1",
            name: "Test Radio",
            url: "http://stream.test/live",
            urlResolved: "http://stream.test/resolved",
            tags: "rock,pop",
            codec: "MP3",
            bitrate: 128
        )

        let fav = FavoriteStation(from: station, sortOrder: 3)

        XCTAssertEqual(fav.stationuuid, "uuid-1")
        XCTAssertEqual(fav.name, "Test Radio")
        XCTAssertEqual(fav.urlResolved, "http://stream.test/resolved")
        XCTAssertEqual(fav.tags, "rock,pop")
        XCTAssertEqual(fav.codec, "MP3")
        XCTAssertEqual(fav.bitrate, 128)
        XCTAssertEqual(fav.sortOrder, 3)
    }

    func testInitFromStationDTOFallsBackToRawURL() {
        let station = StationDTOTests.makeStation(
            uuid: "uuid-1",
            name: "Test Radio",
            url: "http://stream.test/live",
            urlResolved: nil
        )

        let fav = FavoriteStation(from: station)
        XCTAssertEqual(fav.urlResolved, "http://stream.test/live")
    }

    // MARK: - Identifiable

    func testDifferentEntriesHaveDifferentIDs() {
        let a = FavoriteStation(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test")
        let b = FavoriteStation(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test")
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - Codable

    func testEncodeDecode() throws {
        let fav = FavoriteStation(
            stationuuid: "uuid-1",
            name: "Test Radio",
            urlResolved: "http://stream.test/live",
            faviconURL: "http://img.test/icon.png",
            tags: "rock,jazz",
            countrycode: "US",
            language: "english",
            codec: "AAC",
            bitrate: 256,
            addedAt: Date(timeIntervalSince1970: 1000),
            sortOrder: 5
        )

        let data = try JSONEncoder().encode(fav)
        let decoded = try JSONDecoder().decode(FavoriteStation.self, from: data)

        XCTAssertEqual(decoded.stationuuid, fav.stationuuid)
        XCTAssertEqual(decoded.name, fav.name)
        XCTAssertEqual(decoded.urlResolved, fav.urlResolved)
        XCTAssertEqual(decoded.faviconURL, fav.faviconURL)
        XCTAssertEqual(decoded.tags, fav.tags)
        XCTAssertEqual(decoded.countrycode, fav.countrycode)
        XCTAssertEqual(decoded.language, fav.language)
        XCTAssertEqual(decoded.codec, fav.codec)
        XCTAssertEqual(decoded.bitrate, fav.bitrate)
        XCTAssertEqual(decoded.addedAt, fav.addedAt)
        XCTAssertEqual(decoded.sortOrder, fav.sortOrder)
    }

    // MARK: - Computed Properties

    func testBitrateLabelWithValue() {
        let fav = FavoriteStation(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test", bitrate: 128)
        XCTAssertEqual(fav.bitrateLabel, "128k")
    }

    func testBitrateLabelWithZero() {
        let fav = FavoriteStation(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test", bitrate: 0)
        XCTAssertEqual(fav.bitrateLabel, "—")
    }

    func testTagListSplitsAndTrims() {
        let fav = FavoriteStation(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test", tags: "rock, jazz , blues")
        XCTAssertEqual(fav.tagList, ["rock", "jazz", "blues"])
    }

    func testTagListEmptyWhenNil() {
        let fav = FavoriteStation(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test", tags: nil)
        XCTAssertEqual(fav.tagList, [])
    }

    func testTagListFiltersEmptyStrings() {
        let fav = FavoriteStation(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test", tags: "rock,,jazz,")
        XCTAssertEqual(fav.tagList, ["rock", "jazz"])
    }

    // MARK: - toStationDTO

    func testToStationDTO() {
        let fav = FavoriteStation(
            stationuuid: "uuid-1",
            name: "Test Radio",
            urlResolved: "http://stream.test/live",
            faviconURL: "http://img.test/icon.png",
            tags: "rock,pop",
            countrycode: "US",
            language: "english",
            codec: "MP3",
            bitrate: 128
        )

        let dto = fav.toStationDTO()

        XCTAssertEqual(dto.stationuuid, "uuid-1")
        XCTAssertEqual(dto.name, "Test Radio")
        XCTAssertEqual(dto.url, "http://stream.test/live")
        XCTAssertEqual(dto.urlResolved, "http://stream.test/live")
        XCTAssertEqual(dto.favicon, "http://img.test/icon.png")
        XCTAssertEqual(dto.tags, "rock,pop")
        XCTAssertEqual(dto.countrycode, "US")
        XCTAssertEqual(dto.language, "english")
        XCTAssertEqual(dto.codec, "MP3")
        XCTAssertEqual(dto.bitrate, 128)
    }
}
