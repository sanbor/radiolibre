import XCTest
import AVFoundation
@testable import LibreRadio

@MainActor
final class PlayerViewModelTests: XCTestCase {

    private var discovery: ServerDiscoveryService!
    private var radioBrowserService: RadioBrowserService!
    private var audioService: AudioPlayerService!
    private var historyService: HistoryService!
    private var historyDefaults: UserDefaults!
    private var historySuiteName: String!
    private var vm: PlayerViewModel!

    override func setUp() async throws {
        discovery = ServerDiscoveryService()
        await discovery.setServers(["mock.api.radio-browser.info"])

        let session = TestFixtures.makeMockSession()
        radioBrowserService = RadioBrowserService(discovery: discovery, session: session)

        let nowPlayingService = NowPlayingService()
        audioService = AudioPlayerService(
            player: AVPlayer(),
            service: radioBrowserService,
            nowPlayingService: nowPlayingService
        )

        historySuiteName = "PlayerViewModelTests-\(UUID().uuidString)"
        historyDefaults = UserDefaults(suiteName: historySuiteName)!
        historyDefaults.removePersistentDomain(forName: historySuiteName)
        historyService = HistoryService(defaults: historyDefaults)

        vm = PlayerViewModel(
            audioService: audioService,
            radioBrowserService: radioBrowserService,
            historyService: historyService
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

    override func tearDown() async throws {
        // Await any in-flight history writes to prevent cross-test contamination
        await vm.historyTask?.value
        MockURLProtocol.requestHandler = nil
        historyDefaults.removePersistentDomain(forName: historySuiteName)
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertNil(vm.currentStation)
        XCTAssertFalse(vm.isPlaying)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.state, .idle)
    }

    // MARK: - Play

    func testPlaySetsLoadingState() {
        let station = TestFixtures.makeStation()
        vm.play(station: station)

        XCTAssertEqual(vm.currentStation, station)
        XCTAssertTrue(vm.isLoading)
        XCTAssertFalse(vm.isPlaying)
    }

    func testPlayWithInvalidURLSetsError() {
        let station = StationDTOTests.makeStation(
            uuid: "bad",
            name: "Bad",
            url: "",
            urlResolved: nil
        )
        vm.play(station: station)

        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - Toggle

    func testToggleFromPausedReconnects() {
        let station = TestFixtures.makeStation()
        vm.play(station: station)
        audioService.pause()

        vm.togglePlayPause()
        XCTAssertTrue(vm.isLoading)
    }

    func testToggleFromIdleDoesNothing() {
        vm.togglePlayPause()
        XCTAssertEqual(vm.state, .idle)
    }

    // MARK: - Stop

    func testStopReturnsToIdle() {
        let station = TestFixtures.makeStation()
        vm.play(station: station)

        vm.stop()
        XCTAssertNil(vm.currentStation)
        XCTAssertEqual(vm.state, .idle)
    }

    // MARK: - Vote

    func testVoteReturnsResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            let json = """
            {"ok": true, "message": "voted for station successfully"}
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json.data(using: .utf8)!)
        }

        let station = TestFixtures.makeStation()
        let result = try await vm.vote(station: station)
        XCTAssertTrue(result.ok)
    }

    func testVoteThrowsOnServerError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let station = TestFixtures.makeStation()
        do {
            _ = try await vm.vote(station: station)
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    // MARK: - Error Message

    func testErrorMessageNilForNonErrorStates() {
        XCTAssertNil(vm.errorMessage) // idle

        let station = TestFixtures.makeStation()
        vm.play(station: station)
        XCTAssertNil(vm.errorMessage) // loading
    }

    func testErrorMessagePopulatedOnError() {
        let station = StationDTOTests.makeStation(
            uuid: "bad",
            name: "Bad",
            url: "",
            urlResolved: nil
        )
        vm.play(station: station)
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - History Recording

    func testPlayRecordsHistory() async throws {
        let station = TestFixtures.makeStation(uuid: "history-test", name: "History Station")
        vm.play(station: station)

        // Await the history write task instead of sleeping — Task.sleep is flaky on CI runners
        await vm.historyTask?.value

        let entries = await historyService.allEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].stationuuid, "history-test")
    }

    // MARK: - State Forwarding

    func testStateMatchesAudioService() {
        XCTAssertEqual(vm.state, audioService.state)

        let station = TestFixtures.makeStation()
        vm.play(station: station)
        XCTAssertEqual(vm.state, audioService.state)

        vm.stop()
        XCTAssertEqual(vm.state, audioService.state)
    }

    // MARK: - Playback Context

    func testPlaySetsContext() {
        let station = TestFixtures.makeStation()
        let context = PlaybackContext(source: .search, stations: [station])
        vm.play(station: station, context: context)

        XCTAssertEqual(vm.playbackContext?.source, .search)
        XCTAssertEqual(vm.playbackContext?.stations.count, 1)
    }

    func testPlayWithoutContextSetsStandalone() {
        let station = TestFixtures.makeStation()
        vm.play(station: station)

        XCTAssertEqual(vm.playbackContext?.source, .standalone)
        XCTAssertEqual(vm.playbackContext?.stations.count, 1)
    }

    func testPlayNextNavigatesWithinContext() async {
        let s1 = TestFixtures.makeStation(uuid: "s1", name: "Station 1")
        let s2 = TestFixtures.makeStation(uuid: "s2", name: "Station 2")
        let s3 = TestFixtures.makeStation(uuid: "s3", name: "Station 3")
        let context = PlaybackContext(source: .search, stations: [s1, s2, s3])
        vm.play(station: s1, context: context)

        await vm.playNext()

        XCTAssertEqual(vm.currentStation?.stationuuid, "s2")
    }

    func testPlayNextWrapsAround() async {
        let s1 = TestFixtures.makeStation(uuid: "s1", name: "Station 1")
        let s2 = TestFixtures.makeStation(uuid: "s2", name: "Station 2")
        let context = PlaybackContext(source: .search, stations: [s1, s2])
        vm.play(station: s2, context: context)

        await vm.playNext()

        XCTAssertEqual(vm.currentStation?.stationuuid, "s1")
    }

    func testPlayPreviousWrapsAround() async {
        let s1 = TestFixtures.makeStation(uuid: "s1", name: "Station 1")
        let s2 = TestFixtures.makeStation(uuid: "s2", name: "Station 2")
        let context = PlaybackContext(source: .search, stations: [s1, s2])
        vm.play(station: s1, context: context)

        await vm.playPrevious()

        XCTAssertEqual(vm.currentStation?.stationuuid, "s2")
    }

    func testCanSkipTrackFalseForStandalone() {
        let station = TestFixtures.makeStation()
        vm.play(station: station)

        XCTAssertFalse(vm.canSkipTrack)
    }

    func testCanSkipTrackFalseForSingleStation() {
        let station = TestFixtures.makeStation()
        let context = PlaybackContext(source: .search, stations: [station])
        vm.play(station: station, context: context)

        XCTAssertFalse(vm.canSkipTrack)
    }

    func testCanSkipTrackTrueForMultipleStations() {
        let s1 = TestFixtures.makeStation(uuid: "s1", name: "Station 1")
        let s2 = TestFixtures.makeStation(uuid: "s2", name: "Station 2")
        let context = PlaybackContext(source: .search, stations: [s1, s2])
        vm.play(station: s1, context: context)

        XCTAssertTrue(vm.canSkipTrack)
    }

    func testPlayNextWhenStationNotInList() async {
        let s1 = TestFixtures.makeStation(uuid: "s1", name: "Station 1")
        let s2 = TestFixtures.makeStation(uuid: "s2", name: "Station 2")
        let other = TestFixtures.makeStation(uuid: "other", name: "Other")
        let context = PlaybackContext(source: .search, stations: [s1, s2])
        vm.play(station: other, context: context)

        await vm.playNext()

        XCTAssertEqual(vm.currentStation?.stationuuid, "s1")
    }

    func testNewPlayOverridesContext() {
        let s1 = TestFixtures.makeStation(uuid: "s1", name: "Station 1")
        let s2 = TestFixtures.makeStation(uuid: "s2", name: "Station 2")
        let favContext = PlaybackContext(source: .favorites, stations: [s1])
        vm.play(station: s1, context: favContext)

        let searchContext = PlaybackContext(source: .search, stations: [s2])
        vm.play(station: s2, context: searchContext)

        XCTAssertEqual(vm.playbackContext?.source, .search)
        XCTAssertEqual(vm.playbackContext?.stations.count, 1)
    }
}
