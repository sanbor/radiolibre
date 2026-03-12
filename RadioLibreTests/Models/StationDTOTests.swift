import XCTest
@testable import RadioLibre

final class StationDTOTests: XCTestCase {

    // MARK: - JSON Decoding

    func testDecodesFullStation() throws {
        let json = """
        {
            "stationuuid": "abc-123",
            "name": "Test Radio",
            "url": "http://stream.example.com/live",
            "url_resolved": "http://stream.example.com/live.mp3",
            "homepage": "https://example.com",
            "favicon": "https://example.com/icon.png",
            "tags": "rock,jazz, blues",
            "country": "Germany",
            "countrycode": "DE",
            "state": "Berlin",
            "language": "german",
            "languagecodes": "deu",
            "codec": "MP3",
            "bitrate": 128,
            "hls": 0,
            "votes": 42,
            "clickcount": 100,
            "clicktrend": 5,
            "lastcheckok": 1,
            "lastcheckoktime": "2024-01-01 00:00:00",
            "lastcheckoktime_iso8601": "2024-01-01T00:00:00Z",
            "geo_lat": 52.52,
            "geo_long": 13.405,
            "has_extended_info": true
        }
        """.data(using: .utf8)!

        let station = try JSONDecoder().decode(StationDTO.self, from: json)

        XCTAssertEqual(station.stationuuid, "abc-123")
        XCTAssertEqual(station.name, "Test Radio")
        XCTAssertEqual(station.url, "http://stream.example.com/live")
        XCTAssertEqual(station.urlResolved, "http://stream.example.com/live.mp3")
        XCTAssertEqual(station.homepage, "https://example.com")
        XCTAssertEqual(station.favicon, "https://example.com/icon.png")
        XCTAssertEqual(station.tags, "rock,jazz, blues")
        XCTAssertEqual(station.country, "Germany")
        XCTAssertEqual(station.countrycode, "DE")
        XCTAssertEqual(station.state, "Berlin")
        XCTAssertEqual(station.language, "german")
        XCTAssertEqual(station.languagecodes, "deu")
        XCTAssertEqual(station.codec, "MP3")
        XCTAssertEqual(station.bitrate, 128)
        XCTAssertEqual(station.hls, 0)
        XCTAssertEqual(station.votes, 42)
        XCTAssertEqual(station.clickcount, 100)
        XCTAssertEqual(station.clicktrend, 5)
        XCTAssertEqual(station.lastcheckok, 1)
        XCTAssertEqual(station.geoLat, 52.52)
        XCTAssertEqual(station.geoLong, 13.405)
        XCTAssertEqual(station.hasExtendedInfo, true)
    }

    func testDecodesMinimalStation() throws {
        let json = """
        {
            "stationuuid": "min-1",
            "name": "Minimal",
            "url": "http://stream.test/live"
        }
        """.data(using: .utf8)!

        let station = try JSONDecoder().decode(StationDTO.self, from: json)

        XCTAssertEqual(station.stationuuid, "min-1")
        XCTAssertEqual(station.name, "Minimal")
        XCTAssertEqual(station.url, "http://stream.test/live")
        XCTAssertNil(station.urlResolved)
        XCTAssertNil(station.homepage)
        XCTAssertNil(station.favicon)
        XCTAssertNil(station.tags)
        XCTAssertNil(station.codec)
        XCTAssertNil(station.bitrate)
        XCTAssertNil(station.geoLat)
        XCTAssertNil(station.hasExtendedInfo)
    }

    // MARK: - Identifiable

    func testIdUsesStationUUID() {
        let station = StationDTOTests.makeStation(uuid: "test-uuid")
        XCTAssertEqual(station.id, "test-uuid")
    }

    // MARK: - Computed Properties

    func testTagListSplitsAndTrims() {
        let station = StationDTOTests.makeStation(tags: "rock, jazz , blues")
        XCTAssertEqual(station.tagList, ["rock", "jazz", "blues"])
    }

    func testTagListEmptyWhenNil() {
        let station = StationDTOTests.makeStation(tags: nil)
        XCTAssertEqual(station.tagList, [])
    }

    func testTagListEmptyWhenEmpty() {
        let station = StationDTOTests.makeStation(tags: "")
        XCTAssertEqual(station.tagList, [])
    }

    func testTagListFiltersEmptyStrings() {
        let station = StationDTOTests.makeStation(tags: "rock,,jazz,")
        XCTAssertEqual(station.tagList, ["rock", "jazz"])
    }

    func testIsHLS() {
        XCTAssertTrue(StationDTOTests.makeStation(hls: 1).isHLS)
        XCTAssertFalse(StationDTOTests.makeStation(hls: 0).isHLS)
        XCTAssertFalse(StationDTOTests.makeStation(hls: nil).isHLS)
    }

    func testIsOnline() {
        XCTAssertTrue(StationDTOTests.makeStation(lastcheckok: 1).isOnline)
        XCTAssertFalse(StationDTOTests.makeStation(lastcheckok: 0).isOnline)
        XCTAssertFalse(StationDTOTests.makeStation(lastcheckok: nil).isOnline)
    }

    func testStreamURLPrefersResolved() {
        let station = StationDTOTests.makeStation(
            url: "http://fallback.test/stream",
            urlResolved: "http://resolved.test/stream"
        )
        XCTAssertEqual(station.streamURL?.absoluteString, "http://resolved.test/stream")
    }

    func testStreamURLFallsBackToUrl() {
        let station = StationDTOTests.makeStation(
            url: "http://fallback.test/stream",
            urlResolved: nil
        )
        XCTAssertEqual(station.streamURL?.absoluteString, "http://fallback.test/stream")
    }

    func testFaviconURLNilWhenEmpty() {
        XCTAssertNil(StationDTOTests.makeStation(favicon: nil).faviconURL)
        XCTAssertNil(StationDTOTests.makeStation(favicon: "").faviconURL)
    }

    func testFaviconURLValid() {
        let station = StationDTOTests.makeStation(favicon: "https://example.com/icon.png")
        XCTAssertEqual(station.faviconURL?.absoluteString, "https://example.com/icon.png")
    }

    func testHomepageURLNilWhenEmpty() {
        XCTAssertNil(StationDTOTests.makeStation(homepage: nil).homepageURL)
        XCTAssertNil(StationDTOTests.makeStation(homepage: "").homepageURL)
    }

    func testHomepageURLValid() {
        let station = StationDTOTests.makeStation(homepage: "https://example.com")
        XCTAssertEqual(station.homepageURL?.absoluteString, "https://example.com")
    }

    func testBitrateLabelFormatted() {
        XCTAssertEqual(StationDTOTests.makeStation(bitrate: 128).bitrateLabel, "128k")
        XCTAssertEqual(StationDTOTests.makeStation(bitrate: 320).bitrateLabel, "320k")
    }

    func testBitrateLabelDashWhenNilOrZero() {
        XCTAssertEqual(StationDTOTests.makeStation(bitrate: nil).bitrateLabel, "—")
        XCTAssertEqual(StationDTOTests.makeStation(bitrate: 0).bitrateLabel, "—")
    }

    // MARK: - Hashable

    func testEqualWhenAllFieldsMatch() {
        let a = StationDTOTests.makeStation(uuid: "same-uuid", name: "Same Name")
        let b = StationDTOTests.makeStation(uuid: "same-uuid", name: "Same Name")
        XCTAssertEqual(a, b)
    }

    func testNotEqualWhenFieldsDiffer() {
        let a = StationDTOTests.makeStation(uuid: "same-uuid", name: "Name A")
        let b = StationDTOTests.makeStation(uuid: "same-uuid", name: "Name B")
        XCTAssertNotEqual(a, b)
    }

    func testDifferentUUIDNotEqual() {
        let a = StationDTOTests.makeStation(uuid: "uuid-1")
        let b = StationDTOTests.makeStation(uuid: "uuid-2")
        XCTAssertNotEqual(a, b)
    }

    func testCanBeUsedInSet() {
        let a = StationDTOTests.makeStation(uuid: "uuid-1", name: "Radio 1")
        let b = StationDTOTests.makeStation(uuid: "uuid-2", name: "Radio 2")
        let set: Set<StationDTO> = [a, b, a]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Encoding

    func testEncodeDecodeRoundtrip() throws {
        let original = StationDTOTests.makeStation(
            uuid: "round-trip",
            name: "Round Trip Radio",
            url: "http://stream.test/live",
            urlResolved: "http://stream.test/resolved",
            tags: "rock,pop",
            codec: "AAC",
            bitrate: 256
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StationDTO.self, from: data)

        XCTAssertEqual(decoded.stationuuid, original.stationuuid)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.urlResolved, original.urlResolved)
        XCTAssertEqual(decoded.tags, original.tags)
        XCTAssertEqual(decoded.codec, original.codec)
        XCTAssertEqual(decoded.bitrate, original.bitrate)
    }

    // MARK: - Helpers

    static func makeStation(
        uuid: String = "test-uuid",
        name: String = "Test Radio",
        url: String = "http://stream.test/live",
        urlResolved: String? = "http://stream.test/resolved",
        homepage: String? = nil,
        favicon: String? = nil,
        tags: String? = nil,
        countrycode: String? = nil,
        codec: String? = nil,
        bitrate: Int? = nil,
        hls: Int? = nil,
        lastcheckok: Int? = nil
    ) -> StationDTO {
        StationDTO(
            stationuuid: uuid,
            name: name,
            url: url,
            urlResolved: urlResolved,
            homepage: homepage,
            favicon: favicon,
            tags: tags,
            country: nil,
            countrycode: countrycode,
            state: nil,
            language: nil,
            languagecodes: nil,
            codec: codec,
            bitrate: bitrate,
            hls: hls,
            votes: nil,
            clickcount: nil,
            clicktrend: nil,
            lastcheckok: lastcheckok,
            lastcheckoktime: nil,
            lastcheckoktime_iso8601: nil,
            geoLat: nil,
            geoLong: nil,
            hasExtendedInfo: nil
        )
    }
}
