import XCTest
@testable import LibreRadio

final class TrackHistoryItemTests: XCTestCase {

    func testDefaultIdAndTimestamp() {
        let item = TrackHistoryItem(
            title: "Yesterday",
            artist: "Beatles",
            stationName: "Classic FM",
            stationUUID: "uuid-1"
        )

        XCTAssertFalse(item.id.uuidString.isEmpty)
        XCTAssertEqual(item.title, "Yesterday")
        XCTAssertEqual(item.artist, "Beatles")
        XCTAssertEqual(item.stationName, "Classic FM")
        XCTAssertEqual(item.stationUUID, "uuid-1")
        // Timestamp should be within the last second
        XCTAssertTrue(Date().timeIntervalSince(item.timestamp) < 1.0)
    }

    func testNilArtist() {
        let item = TrackHistoryItem(
            title: "Station Jingle",
            artist: nil,
            stationName: "Radio One",
            stationUUID: "uuid-2"
        )
        XCTAssertNil(item.artist)
    }

    func testIdentifiable() {
        let item1 = TrackHistoryItem(title: "A", artist: nil, stationName: "S", stationUUID: "u")
        let item2 = TrackHistoryItem(title: "A", artist: nil, stationName: "S", stationUUID: "u")
        // Different IDs even with same content
        XCTAssertNotEqual(item1.id, item2.id)
    }

    func testHashable() {
        let id = UUID()
        let timestamp = Date()
        let item1 = TrackHistoryItem(id: id, title: "A", artist: "B", stationName: "S", stationUUID: "u", timestamp: timestamp)
        let item2 = TrackHistoryItem(id: id, title: "A", artist: "B", stationName: "S", stationUUID: "u", timestamp: timestamp)
        XCTAssertEqual(item1, item2)
    }
}
