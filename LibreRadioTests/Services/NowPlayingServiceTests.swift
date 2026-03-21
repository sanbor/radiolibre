import XCTest
import MediaPlayer
@testable import LibreRadio

@MainActor
final class NowPlayingServiceTests: XCTestCase {

    private var service: NowPlayingService!

    override func setUp() {
        service = NowPlayingService()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    override func tearDown() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - updateNowPlaying

    func testUpdateNowPlayingSetsInfo() {
        let station = StationDTOTests.makeStation(name: "Jazz FM")
        service.updateNowPlaying(station: station, isPlaying: true)

        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        XCTAssertNotNil(info)
        XCTAssertEqual(info?[MPMediaItemPropertyTitle] as? String, "Jazz FM")
        XCTAssertEqual(info?[MPNowPlayingInfoPropertyIsLiveStream] as? Bool, true)
    }

    func testUpdateNowPlayingSetsPlaybackRate() {
        let station = StationDTOTests.makeStation(name: "Jazz FM")

        service.updateNowPlaying(station: station, isPlaying: true)
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        XCTAssertEqual(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 1.0)

        service.updateNowPlaying(station: station, isPlaying: false)
        info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        XCTAssertEqual(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 0.0)
    }

    func testUpdateNowPlayingMetadataFormat() {
        let station = StationDTOTests.makeStation(
            name: "Test Radio",
            countrycode: "NL",
            codec: "AAC+",
            bitrate: 95
        )
        service.updateNowPlaying(station: station, isPlaying: true)

        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        let artist = info?[MPMediaItemPropertyArtist] as? String
        XCTAssertNotNil(artist)
        // Should contain country, codec, and bitrate but no flag emoji
        // (flag emojis render as gray rectangles in MPNowPlayingInfoCenter)
        XCTAssertEqual(artist, "Netherlands · AAC+ 95k")
        XCTAssertFalse(artist?.contains("🇳🇱") == true)
    }

    func testUpdateNowPlayingMetadataFormatNoCountry() {
        let station = StationDTOTests.makeStation(
            name: "Test Radio",
            codec: "MP3",
            bitrate: 128
        )
        service.updateNowPlaying(station: station, isPlaying: true)

        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        let artist = info?[MPMediaItemPropertyArtist] as? String
        XCTAssertNotNil(artist)
        XCTAssertTrue(artist?.contains("MP3") == true)
        XCTAssertTrue(artist?.contains("128k") == true)
    }

    // MARK: - updateStreamMetadata

    func testUpdateStreamMetadata() {
        let station = StationDTOTests.makeStation(name: "Jazz FM")
        service.updateNowPlaying(station: station, isPlaying: true)

        service.updateStreamMetadata(title: "Maybe Angels", artist: "Sheryl Crow", station: station)

        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        XCTAssertEqual(info?[MPMediaItemPropertyTitle] as? String, "Maybe Angels")
        XCTAssertEqual(info?[MPMediaItemPropertyArtist] as? String, "Sheryl Crow")
    }

    func testUpdateStreamMetadataIgnoresStaleStation() {
        let station1 = StationDTOTests.makeStation(uuid: "station-1", name: "Station 1")
        let station2 = StationDTOTests.makeStation(uuid: "station-2", name: "Station 2")

        service.updateNowPlaying(station: station2, isPlaying: true)
        service.updateStreamMetadata(title: "Old Track", artist: "Old Artist", station: station1)

        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        // Should not have updated because station1 is stale
        XCTAssertEqual(info?[MPMediaItemPropertyTitle] as? String, "Station 2")
    }

    func testUpdateStreamMetadataFallsBackToStationName() {
        let station = StationDTOTests.makeStation(name: "Jazz FM")
        service.updateNowPlaying(station: station, isPlaying: true)

        service.updateStreamMetadata(title: nil, artist: nil, station: station)

        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        XCTAssertEqual(info?[MPMediaItemPropertyTitle] as? String, "Jazz FM")
    }

    // MARK: - clearNowPlaying

    func testClearNowPlayingSetsInfoToNil() {
        // Manually set info to verify clearNowPlaying clears it
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: "Test"]
        XCTAssertNotNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)

        service.clearNowPlaying()
        XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
    }

    // MARK: - Remote Commands

    func testRemoteCommandsEnabled() {
        let center = MPRemoteCommandCenter.shared()
        XCTAssertTrue(center.playCommand.isEnabled)
        XCTAssertTrue(center.pauseCommand.isEnabled)
        XCTAssertTrue(center.stopCommand.isEnabled)
        XCTAssertTrue(center.togglePlayPauseCommand.isEnabled)
    }

    func testNextPreviousCommandsEnabled() {
        let center = MPRemoteCommandCenter.shared()
        XCTAssertTrue(center.nextTrackCommand.isEnabled)
        XCTAssertTrue(center.previousTrackCommand.isEnabled)
    }

    func testLikeCommandEnabled() {
        let center = MPRemoteCommandCenter.shared()
        XCTAssertTrue(center.likeCommand.isEnabled)
    }

    // MARK: - Player ViewModel Wiring

    func testSetPlayerViewModelStoresReference() {
        let audioService = AudioPlayerService()
        let playerVM = PlayerViewModel(audioService: audioService)
        service.setPlayerViewModel(playerVM)
        XCTAssertNotNil(service.playerViewModel)
    }

    func testPlayerViewModelIsWeak() {
        let audioService = AudioPlayerService()
        var playerVM: PlayerViewModel? = PlayerViewModel(audioService: audioService)
        service.setPlayerViewModel(playerVM!)
        playerVM = nil
        XCTAssertNil(service.playerViewModel)
    }

    // MARK: - Favorites ViewModel Wiring

    func testFavoritesViewModelIsWeak() {
        var favoritesVM: FavoritesViewModel? = FavoritesViewModel()
        service.setFavoritesViewModel(favoritesVM!)
        favoritesVM = nil
        // favoritesViewModel is private, so verify indirectly:
        // updateLikeCommandState should not crash and like should be inactive
        let station = StationDTOTests.makeStation(uuid: "test-station", name: "Test")
        service.updateNowPlaying(station: station, isPlaying: true)
        service.updateLikeCommandState(stationuuid: "test-station")
        XCTAssertFalse(MPRemoteCommandCenter.shared().likeCommand.isActive)
    }
}
