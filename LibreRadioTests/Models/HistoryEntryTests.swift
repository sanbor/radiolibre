import XCTest
@testable import LibreRadio

final class HistoryEntryTests: XCTestCase {

    // MARK: - Init

    func testInitWithDefaults() {
        let entry = HistoryEntry(
            stationuuid: "uuid-1",
            name: "Test Radio",
            urlResolved: "http://stream.test/live"
        )

        XCTAssertEqual(entry.stationuuid, "uuid-1")
        XCTAssertEqual(entry.name, "Test Radio")
        XCTAssertEqual(entry.urlResolved, "http://stream.test/live")
        XCTAssertNil(entry.faviconURL)
        XCTAssertNil(entry.codec)
        XCTAssertEqual(entry.bitrate, 0)
        XCTAssertNil(entry.countrycode)
        XCTAssertNil(entry.state)
    }

    func testInitFromStationDTO() {
        let station = StationDTOTests.makeStation(
            uuid: "uuid-1",
            name: "Test Radio",
            url: "http://stream.test/live",
            urlResolved: "http://stream.test/resolved",
            countrycode: "AR",
            state: "Buenos Aires",
            codec: "MP3",
            bitrate: 128
        )

        let entry = HistoryEntry(from: station)

        XCTAssertEqual(entry.stationuuid, "uuid-1")
        XCTAssertEqual(entry.name, "Test Radio")
        XCTAssertEqual(entry.urlResolved, "http://stream.test/resolved")
        XCTAssertEqual(entry.countrycode, "AR")
        XCTAssertEqual(entry.state, "Buenos Aires")
        XCTAssertEqual(entry.codec, "MP3")
        XCTAssertEqual(entry.bitrate, 128)
    }

    func testInitFromStationDTOFallsBackToRawURL() {
        let station = StationDTOTests.makeStation(
            uuid: "uuid-1",
            name: "Test Radio",
            url: "http://stream.test/live",
            urlResolved: nil
        )

        let entry = HistoryEntry(from: station)
        XCTAssertEqual(entry.urlResolved, "http://stream.test/live")
    }

    // MARK: - Identifiable

    func testIdentifiable() {
        let entry = HistoryEntry(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test")
        XCTAssertEqual(entry.id, entry.id) // UUID is stable
    }

    func testDifferentEntriesHaveDifferentIDs() {
        let entry1 = HistoryEntry(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test")
        let entry2 = HistoryEntry(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test")
        XCTAssertNotEqual(entry1.id, entry2.id)
    }

    // MARK: - Codable

    func testEncodeDecode() throws {
        let entry = HistoryEntry(
            stationuuid: "uuid-1",
            name: "Test Radio",
            urlResolved: "http://stream.test/live",
            faviconURL: "http://img.test/icon.png",
            codec: "AAC",
            bitrate: 256,
            countrycode: "US",
            state: "California",
            playedAt: Date(timeIntervalSince1970: 1000)
        )

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(HistoryEntry.self, from: data)

        XCTAssertEqual(decoded.stationuuid, entry.stationuuid)
        XCTAssertEqual(decoded.name, entry.name)
        XCTAssertEqual(decoded.urlResolved, entry.urlResolved)
        XCTAssertEqual(decoded.faviconURL, entry.faviconURL)
        XCTAssertEqual(decoded.codec, entry.codec)
        XCTAssertEqual(decoded.bitrate, entry.bitrate)
        XCTAssertEqual(decoded.countrycode, entry.countrycode)
        XCTAssertEqual(decoded.state, entry.state)
        XCTAssertEqual(decoded.playedAt, entry.playedAt)
    }

    // MARK: - Bitrate Label

    func testBitrateLabelWithValue() {
        let entry = HistoryEntry(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test", bitrate: 128)
        XCTAssertEqual(entry.bitrateLabel, "128k")
    }

    func testBitrateLabelWithZero() {
        let entry = HistoryEntry(stationuuid: "uuid-1", name: "Test", urlResolved: "http://test", bitrate: 0)
        XCTAssertEqual(entry.bitrateLabel, "—")
    }

    // MARK: - toStationDTO

    func testToStationDTO() {
        let entry = HistoryEntry(
            stationuuid: "uuid-1",
            name: "Test Radio",
            urlResolved: "http://stream.test/live",
            faviconURL: "http://img.test/icon.png",
            codec: "MP3",
            bitrate: 128,
            countrycode: "US",
            state: "California"
        )

        let dto = entry.toStationDTO()

        XCTAssertEqual(dto.stationuuid, "uuid-1")
        XCTAssertEqual(dto.name, "Test Radio")
        XCTAssertEqual(dto.url, "http://stream.test/live")
        XCTAssertEqual(dto.urlResolved, "http://stream.test/live")
        XCTAssertEqual(dto.favicon, "http://img.test/icon.png")
        XCTAssertEqual(dto.codec, "MP3")
        XCTAssertEqual(dto.bitrate, 128)
        XCTAssertEqual(dto.countrycode, "US")
        XCTAssertEqual(dto.state, "California")
    }

    // MARK: - Date Relative Description

    func testRelativeDescriptionReturnsNonEmptyString() {
        let date = Date().addingTimeInterval(-3600)
        XCTAssertFalse(date.relativeDescription.isEmpty)
    }
}
