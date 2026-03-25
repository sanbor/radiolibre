import XCTest
@testable import LibreRadio

final class StationConvertibleTests: XCTestCase {

    // MARK: - FavoriteStation conformance

    func testFavoriteStationConformsToStationConvertible() {
        let fav = FavoriteStation(
            stationuuid: "uuid-1",
            name: "Test Station",
            urlResolved: "https://stream.example.com",
            faviconURL: "https://img.example.com/icon.png",
            tags: "rock,pop",
            countrycode: "US",
            state: "California",
            language: "english",
            codec: "MP3",
            bitrate: 128
        )
        let dto = fav.toStationDTO()

        XCTAssertEqual(dto.stationuuid, "uuid-1")
        XCTAssertEqual(dto.name, "Test Station")
        XCTAssertEqual(dto.url, "https://stream.example.com")
        XCTAssertEqual(dto.urlResolved, "https://stream.example.com")
        XCTAssertEqual(dto.favicon, "https://img.example.com/icon.png")
        XCTAssertEqual(dto.tags, "rock,pop")
        XCTAssertEqual(dto.countrycode, "US")
        XCTAssertEqual(dto.state, "California")
        XCTAssertEqual(dto.language, "english")
        XCTAssertEqual(dto.codec, "MP3")
        XCTAssertEqual(dto.bitrate, 128)
    }

    func testFavoriteStationDTOHasNilForServerOnlyFields() {
        let fav = TestFixtures.makeFavoriteStation()
        let dto = fav.toStationDTO()

        XCTAssertNil(dto.homepage)
        XCTAssertNil(dto.country)
        XCTAssertNil(dto.languagecodes)
        XCTAssertNil(dto.hls)
        XCTAssertNil(dto.votes)
        XCTAssertNil(dto.clickcount)
        XCTAssertNil(dto.clicktrend)
        XCTAssertNil(dto.lastcheckok)
        XCTAssertNil(dto.lastcheckoktime)
        XCTAssertNil(dto.lastcheckoktime_iso8601)
        XCTAssertNil(dto.geoLat)
        XCTAssertNil(dto.geoLong)
        XCTAssertNil(dto.hasExtendedInfo)
    }

    // MARK: - HistoryEntry conformance

    func testHistoryEntryConformsToStationConvertible() {
        let entry = HistoryEntry(
            stationuuid: "uuid-2",
            name: "History Station",
            urlResolved: "https://stream2.example.com",
            faviconURL: "https://img2.example.com/icon.png",
            codec: "AAC",
            bitrate: 256,
            countrycode: "DE",
            state: "Berlin"
        )
        let dto = entry.toStationDTO()

        XCTAssertEqual(dto.stationuuid, "uuid-2")
        XCTAssertEqual(dto.name, "History Station")
        XCTAssertEqual(dto.url, "https://stream2.example.com")
        XCTAssertEqual(dto.urlResolved, "https://stream2.example.com")
        XCTAssertEqual(dto.favicon, "https://img2.example.com/icon.png")
        XCTAssertEqual(dto.countrycode, "DE")
        XCTAssertEqual(dto.state, "Berlin")
        XCTAssertEqual(dto.codec, "AAC")
        XCTAssertEqual(dto.bitrate, 256)
    }

    func testHistoryEntryDTOHasNilTagsAndLanguage() {
        let entry = HistoryEntry(
            stationuuid: "uuid-3",
            name: "No Tags Station",
            urlResolved: "https://stream.example.com"
        )
        let dto = entry.toStationDTO()

        // HistoryEntry has no tags or language fields;
        // protocol defaults provide nil.
        XCTAssertNil(dto.tags)
        XCTAssertNil(dto.language)
    }

    // MARK: - Protocol default behavior

    func testProtocolDefaultTagsIsNil() {
        // A minimal conforming type without tags or language
        struct MinimalStation: StationConvertible {
            var stationuuid: String = "min-1"
            var name: String = "Minimal"
            var urlResolved: String = "https://example.com"
            var faviconURL: String? = nil
            var countrycode: String? = nil
            var state: String? = nil
            var codec: String? = nil
            var bitrate: Int = 0
        }

        let station = MinimalStation()
        let dto = station.toStationDTO()

        XCTAssertNil(dto.tags)
        XCTAssertNil(dto.language)
        XCTAssertEqual(dto.stationuuid, "min-1")
        XCTAssertEqual(dto.name, "Minimal")
        XCTAssertEqual(dto.url, "https://example.com")
    }
}
