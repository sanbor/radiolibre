import XCTest
@testable import RadioLibre

final class CarPlaySceneDelegateTests: XCTestCase {

    // MARK: - Detail text formatting

    func testDetailTextWithCodecAndBitrate() {
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: "MP3", bitrate: 128), "MP3 128k")
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: "AAC", bitrate: 256), "AAC 256k")
    }

    func testDetailTextCodecOnly() {
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: "MP3", bitrate: nil), "MP3")
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: "AAC", bitrate: 0), "AAC")
    }

    func testDetailTextBitrateOnly() {
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: nil, bitrate: 128), "128k")
    }

    func testDetailTextEmpty() {
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: nil, bitrate: nil), "")
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: nil, bitrate: 0), "")
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: "", bitrate: nil), "")
    }

    func testDetailTextLowercaseCodecIsUppercased() {
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: "mp3", bitrate: 128), "MP3 128k")
    }

    // MARK: - Station mapping produces correct detail values

    func testFavoriteStationMapsCorrectly() {
        let fav = TestFixtures.makeFavoriteStation(
            name: "Jazz FM",
            codec: "AAC",
            bitrate: 192
        )
        let dto = fav.toStationDTO()
        XCTAssertEqual(dto.name, "Jazz FM")
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: fav.codec, bitrate: fav.bitrate), "AAC 192k")
    }

    func testHistoryEntryMapsCorrectly() {
        let entry = HistoryEntry(
            stationuuid: "h-1",
            name: "Classic Rock",
            urlResolved: "http://stream.test/rock",
            codec: "MP3",
            bitrate: 320
        )
        let dto = entry.toStationDTO()
        XCTAssertEqual(dto.name, "Classic Rock")
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: entry.codec, bitrate: entry.bitrate), "MP3 320k")
    }

    func testStationDTOMapsCorrectly() {
        let station = StationDTOTests.makeStation(
            name: "Pop Hits",
            codec: "AAC",
            bitrate: 128
        )
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: station.codec, bitrate: station.bitrate), "AAC 128k")
    }

    func testHistoryEntryWithZeroBitrate() {
        let entry = HistoryEntry(
            stationuuid: "h-2",
            name: "Unknown Stream",
            urlResolved: "http://stream.test/unknown",
            bitrate: 0
        )
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: entry.codec, bitrate: entry.bitrate), "")
    }

    func testStationDTOWithNilCodecAndBitrate() {
        let station = StationDTOTests.makeStation(name: "Minimal")
        XCTAssertEqual(CarPlaySceneDelegate.detailText(codec: station.codec, bitrate: station.bitrate), "")
    }
}
