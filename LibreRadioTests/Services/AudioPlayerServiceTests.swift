import XCTest
import AVFoundation
@testable import LibreRadio

@MainActor
final class AudioPlayerServiceTests: XCTestCase {

    private var discovery: ServerDiscoveryService!
    private var radioBrowserService: RadioBrowserService!
    private var nowPlayingService: NowPlayingService!
    private var service: AudioPlayerService!

    override func setUp() async throws {
        discovery = ServerDiscoveryService()
        await discovery.setServers(["mock.api.radio-browser.info"])

        let session = TestFixtures.makeMockSession()
        radioBrowserService = RadioBrowserService(discovery: discovery, session: session)
        nowPlayingService = NowPlayingService()
        service = AudioPlayerService(
            player: AVPlayer(),
            service: radioBrowserService,
            nowPlayingService: nowPlayingService
        )

        // Default mock handler for click tracking
        MockURLProtocol.requestHandler = { request in
            let json = """
            {"ok": true, "message": "OK", "stationuuid": "test", "name": "Test", "url": "http://test"}
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json.data(using: .utf8)!)
        }
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
    }

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        XCTAssertEqual(service.state, .idle)
        XCTAssertNil(service.currentStation)
        XCTAssertNil(service.lastPlayedStation)
        XCTAssertFalse(service.isPlaying)
        XCTAssertFalse(service.isLoading)
    }

    func testDefaultVolumeIsOne() {
        XCTAssertEqual(service.volume, 1.0)
    }

    func testInitialMetadataIsNil() {
        XCTAssertNil(service.currentTrackTitle)
        XCTAssertNil(service.currentArtist)
    }

    // MARK: - Play

    func testPlayWithValidURLSetsLoadingState() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        // After play(), state should be loading (AVPlayer hasn't connected yet)
        XCTAssertEqual(service.state, .loading(station: station))
        XCTAssertEqual(service.currentStation, station)
        XCTAssertTrue(service.isLoading)
        XCTAssertFalse(service.isPlaying)
    }

    func testPlayWithInvalidURLSetsErrorState() {
        let station = StationDTOTests.makeStation(
            uuid: "bad-uuid",
            name: "Bad Station",
            url: "",
            urlResolved: nil
        )
        service.play(station: station)

        if case .error(let errorStation, _) = service.state {
            XCTAssertEqual(errorStation.stationuuid, "bad-uuid")
        } else {
            XCTFail("Expected error state, got \(service.state)")
        }
    }

    func testPlayNewStationReplacesCurrentStation() {
        let station1 = TestFixtures.makeStation(uuid: "station-1", name: "Station 1")
        let station2 = TestFixtures.makeStation(uuid: "station-2", name: "Station 2")

        service.play(station: station1)
        XCTAssertEqual(service.currentStation?.stationuuid, "station-1")

        service.play(station: station2)
        XCTAssertEqual(service.currentStation?.stationuuid, "station-2")
    }

    func testPlayClearsMetadata() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        // Metadata should be nil after starting a new station
        XCTAssertNil(service.currentTrackTitle)
        XCTAssertNil(service.currentArtist)
    }

    // MARK: - Pause

    func testPauseFromLoadingSetsCorrectState() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        service.pause()
        XCTAssertEqual(service.state, .paused(station: station))
        XCTAssertFalse(service.isPlaying)
        XCTAssertFalse(service.isLoading)
    }

    func testPauseWhenIdleDoesNothing() {
        service.pause()
        XCTAssertEqual(service.state, .idle)
    }

    // MARK: - Stop

    func testStopReturnsToIdle() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        service.stop()
        XCTAssertEqual(service.state, .idle)
        XCTAssertNil(service.currentStation)
        XCTAssertFalse(service.isPlaying)
        XCTAssertFalse(service.isLoading)
    }

    func testStopClearsMetadata() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.stop()

        XCTAssertNil(service.currentTrackTitle)
        XCTAssertNil(service.currentArtist)
    }

    func testStopWhenIdleDoesNothing() {
        service.stop()
        XCTAssertEqual(service.state, .idle)
    }

    // MARK: - Toggle Play/Pause

    func testToggleFromPausedResumes() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.pause()
        XCTAssertEqual(service.state, .paused(station: station))

        // Toggle should resume (which re-plays for live radio)
        service.togglePlayPause()
        // After resume -> play, state becomes loading again
        XCTAssertTrue(service.isLoading)
    }

    func testToggleFromErrorResumes() {
        let station = StationDTOTests.makeStation(
            uuid: "error-uuid",
            name: "Error Station",
            url: "",
            urlResolved: nil
        )
        service.play(station: station)
        // Should be in error state due to invalid URL
        if case .error = service.state {
            // Now play a valid station and force error state
            let validStation = TestFixtures.makeStation()
            service.play(station: validStation)
            service.pause()
            service.togglePlayPause()
            XCTAssertTrue(service.isLoading)
        }
    }

    // MARK: - Volume

    func testVolumeChangePersists() {
        service.volume = 0.5
        XCTAssertEqual(service.volume, 0.5)
    }

    func testVolumeMinMax() {
        service.volume = 0.0
        XCTAssertEqual(service.volume, 0.0)

        service.volume = 1.0
        XCTAssertEqual(service.volume, 1.0)
    }

    // MARK: - Current Station Extraction

    func testCurrentStationFromLoading() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        XCTAssertEqual(service.currentStation, station)
    }

    func testCurrentStationFromPaused() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.pause()
        XCTAssertEqual(service.currentStation, station)
    }

    func testCurrentStationFromError() {
        let station = StationDTOTests.makeStation(
            uuid: "err",
            name: "ErrStation",
            url: "",
            urlResolved: nil
        )
        service.play(station: station)
        XCTAssertEqual(service.currentStation?.stationuuid, "err")
    }

    func testCurrentStationFromIdle() {
        XCTAssertNil(service.currentStation)
    }

    // MARK: - PlaybackState Equatable

    func testPlaybackStateEquality() {
        let station = TestFixtures.makeStation()
        XCTAssertEqual(AudioPlayerService.PlaybackState.idle, .idle)
        XCTAssertEqual(AudioPlayerService.PlaybackState.loading(station: station), .loading(station: station))
        XCTAssertEqual(AudioPlayerService.PlaybackState.playing(station: station), .playing(station: station))
        XCTAssertEqual(AudioPlayerService.PlaybackState.paused(station: station), .paused(station: station))
        XCTAssertEqual(
            AudioPlayerService.PlaybackState.error(station: station, message: "err"),
            .error(station: station, message: "err")
        )
    }

    func testPlaybackStateInequality() {
        let station = TestFixtures.makeStation()
        XCTAssertNotEqual(AudioPlayerService.PlaybackState.idle, .loading(station: station))
        XCTAssertNotEqual(AudioPlayerService.PlaybackState.playing(station: station), .paused(station: station))
        XCTAssertNotEqual(
            AudioPlayerService.PlaybackState.error(station: station, message: "a"),
            .error(station: station, message: "b")
        )
    }

    // MARK: - Resume from Paused

    func testResumeWhenIdleWithoutLastPlayedDoesNothing() {
        service.resume()
        XCTAssertEqual(service.state, .idle)
    }

    func testResumeAfterStopUsesLastPlayedStation() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.stop()
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.lastPlayedStation, station)

        service.resume()
        XCTAssertEqual(service.state, .loading(station: station))
    }

    // MARK: - Last Played Station

    func testLastPlayedStationSetOnPlay() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        XCTAssertEqual(service.lastPlayedStation, station)
    }

    func testLastPlayedStationSurvivesStop() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.stop()
        XCTAssertEqual(service.lastPlayedStation, station)
    }

    func testToggleFromIdleWithLastPlayedResumes() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.stop()
        XCTAssertEqual(service.state, .idle)

        service.togglePlayPause()
        XCTAssertEqual(service.state, .loading(station: station))
    }

    func testToggleFromIdleWithoutLastPlayedDoesNothing() {
        service.togglePlayPause()
        XCTAssertEqual(service.state, .idle)
    }

    // MARK: - Interruption Handling

    func testInterruptionBeganPauses() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
            ]
        )

        XCTAssertEqual(service.state, .paused(station: station))
    }

    func testInterruptionEndedWithShouldResumeResumes() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.pause()

        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )

        // resume() calls play(), which sets state to .loading
        XCTAssertEqual(service.state, .loading(station: station))
    }

    func testInterruptionEndedWithoutShouldResumeStaysPaused() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.pause()

        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: UInt(0)
            ]
        )

        XCTAssertEqual(service.state, .paused(station: station))
    }

    // MARK: - Route Change Handling

    func testRouteChangeOldDeviceUnavailablePauses() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        NotificationCenter.default.post(
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
            ]
        )

        XCTAssertEqual(service.state, .paused(station: station))
    }

    // MARK: - Buffer Configuration

    func testBufferDurationIsSetOnPlayerItem() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        XCTAssertEqual(service.player.currentItem?.preferredForwardBufferDuration, 3.0)
    }

    func testAutomaticallyWaitsToMinimizeStalling() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        XCTAssertTrue(service.player.automaticallyWaitsToMinimizeStalling)
    }

    func testIsBufferingDefaultsFalse() {
        XCTAssertFalse(service.isBuffering)
    }

    func testStopResetsBufferState() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.stop()

        XCTAssertFalse(service.isBuffering)
    }

    func testPlayNewStationResetsBufferConfig() {
        let station1 = TestFixtures.makeStation(uuid: "buffer-1", name: "Station 1")
        let station2 = TestFixtures.makeStation(uuid: "buffer-2", name: "Station 2")

        service.play(station: station1)
        service.play(station: station2)

        XCTAssertEqual(service.player.currentItem?.preferredForwardBufferDuration, 3.0)
    }

    func testResumePreservesBufferDuration() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        let initialDuration = service.player.currentItem?.preferredForwardBufferDuration
        service.pause()
        service.resume()

        XCTAssertEqual(service.player.currentItem?.preferredForwardBufferDuration, initialDuration)
    }

    func testRouteChangeNewDeviceDoesNotPause() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        NotificationCenter.default.post(
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
            ]
        )

        XCTAssertEqual(service.state, .loading(station: station))
    }

    // MARK: - ICY Metadata Parsing

    func testMetadataParsingArtistTitle() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        service.parseStreamTitle("Sheryl Crow - Maybe Angels")
        XCTAssertEqual(service.currentArtist, "Sheryl Crow")
        XCTAssertEqual(service.currentTrackTitle, "Maybe Angels")
    }

    func testMetadataParsingTitleOnly() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        service.parseStreamTitle("Station Jingle")
        XCTAssertNil(service.currentArtist)
        XCTAssertEqual(service.currentTrackTitle, "Station Jingle")
    }

    func testMetadataParsingMultipleSeparators() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        service.parseStreamTitle("AC/DC - Back In Black - Live")
        XCTAssertEqual(service.currentArtist, "AC/DC")
        XCTAssertEqual(service.currentTrackTitle, "Back In Black - Live")
    }

    func testTimedMetadataUpdatesTrackTitle() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        // Verify metadata starts nil
        XCTAssertNil(service.currentTrackTitle)
        XCTAssertNil(service.currentArtist)

        // Simulate metadata update
        service.parseStreamTitle("Beatles - Yesterday")
        XCTAssertEqual(service.currentArtist, "Beatles")
        XCTAssertEqual(service.currentTrackTitle, "Yesterday")
    }

    // MARK: - Track History

    func testTrackHistoryStartsEmpty() {
        XCTAssertTrue(service.trackHistory.isEmpty)
    }

    func testParseStreamTitleAppendsToHistory() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        service.parseStreamTitle("Roxette - Listen To Your Heart")
        XCTAssertEqual(service.trackHistory.count, 1)
        XCTAssertEqual(service.trackHistory[0].title, "Listen To Your Heart")
        XCTAssertEqual(service.trackHistory[0].artist, "Roxette")
    }

    func testParseStreamTitleDeduplicatesSameTrack() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        service.parseStreamTitle("Roxette - Listen To Your Heart")
        service.parseStreamTitle("Roxette - Listen To Your Heart")
        service.parseStreamTitle("Roxette - Listen To Your Heart")
        XCTAssertEqual(service.trackHistory.count, 1)
    }

    func testParseStreamTitleAppendsDifferentTracks() {
        let station = TestFixtures.makeStation()
        service.play(station: station)

        service.parseStreamTitle("Roxette - Listen To Your Heart")
        service.parseStreamTitle("Beatles - Yesterday")
        XCTAssertEqual(service.trackHistory.count, 2)
    }

    func testTrackHistoryNotClearedOnStop() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.parseStreamTitle("Roxette - Listen To Your Heart")

        service.stop()
        XCTAssertEqual(service.trackHistory.count, 1)
    }

    func testTrackHistoryNotClearedOnStationChange() {
        let station1 = TestFixtures.makeStation(uuid: "s1", name: "Station 1")
        let station2 = TestFixtures.makeStation(uuid: "s2", name: "Station 2")

        service.play(station: station1)
        service.parseStreamTitle("Artist1 - Song1")

        service.play(station: station2)
        service.parseStreamTitle("Artist2 - Song2")

        XCTAssertEqual(service.trackHistory.count, 2)
        XCTAssertEqual(service.trackHistory[0].stationName, "Station 1")
        XCTAssertEqual(service.trackHistory[1].stationName, "Station 2")
    }

    func testTrackHistoryRecordsStationInfo() {
        let station = TestFixtures.makeStation(uuid: "my-uuid", name: "My Radio")
        service.play(station: station)
        service.parseStreamTitle("Artist - Song")

        XCTAssertEqual(service.trackHistory[0].stationName, "My Radio")
        XCTAssertEqual(service.trackHistory[0].stationUUID, "my-uuid")
    }

    func testClearTrackHistory() {
        let station = TestFixtures.makeStation()
        service.play(station: station)
        service.parseStreamTitle("Artist - Song")
        XCTAssertEqual(service.trackHistory.count, 1)

        service.clearTrackHistory()
        XCTAssertTrue(service.trackHistory.isEmpty)
    }
}
