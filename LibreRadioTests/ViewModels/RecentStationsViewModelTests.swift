import XCTest
@testable import LibreRadio

@MainActor
final class RecentStationsViewModelTests: XCTestCase {

    private var defaults: UserDefaults!
    private var historyService: HistoryService!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "RecentStationsViewModelTests")!
        defaults.removePersistentDomain(forName: "RecentStationsViewModelTests")
        historyService = HistoryService(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "RecentStationsViewModelTests")
    }

    // MARK: - Initial State

    func testInitialState() {
        let vm = RecentStationsViewModel(historyService: historyService)
        XCTAssertTrue(vm.entries.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showClearConfirmation)
    }

    // MARK: - Load

    func testLoadPopulatesEntries() async {
        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await historyService.recordPlay(station: station)

        let vm = RecentStationsViewModel(historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.entries.count, 1)
        XCTAssertEqual(vm.entries[0].stationuuid, "uuid-1")
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadEmptyHistory() async {
        let vm = RecentStationsViewModel(historyService: historyService)
        await vm.load()

        XCTAssertTrue(vm.entries.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Deduplication & Sorting

    func testLoadDeduplicatesEntriesByStation() async {
        // Insert two entries for the same station >30 min apart
        let oldEntry = HistoryEntry(
            stationuuid: "uuid-1",
            name: "Station 1",
            urlResolved: "http://stream.test/resolved",
            codec: "MP3",
            bitrate: 128,
            playedAt: Date().addingTimeInterval(-31 * 60)
        )
        let newEntry = HistoryEntry(
            stationuuid: "uuid-1",
            name: "Station 1",
            urlResolved: "http://stream.test/resolved",
            codec: "MP3",
            bitrate: 128,
            playedAt: Date()
        )
        await historyService.setEntries([oldEntry, newEntry])

        let vm = RecentStationsViewModel(historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.entries.count, 1, "Same station should appear only once")
        XCTAssertEqual(vm.entries[0].stationuuid, "uuid-1")
    }

    func testLoadOrdersByRecency() async {
        let now = Date()
        // Entries stored most-recent-first (as HistoryService provides)
        let a = HistoryEntry(stationuuid: "A", name: "A", urlResolved: "http://a", playedAt: now)
        let b = HistoryEntry(stationuuid: "B", name: "B", urlResolved: "http://b", playedAt: now.addingTimeInterval(-60 * 60))
        let c = HistoryEntry(stationuuid: "C", name: "C", urlResolved: "http://c", playedAt: now.addingTimeInterval(-120 * 60))

        await historyService.setEntries([a, b, c])

        let vm = RecentStationsViewModel(historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.entries.count, 3)
        XCTAssertEqual(vm.entries[0].stationuuid, "A", "Most recently played should be first")
        XCTAssertEqual(vm.entries[1].stationuuid, "B", "Second most recent should be second")
        XCTAssertEqual(vm.entries[2].stationuuid, "C", "Oldest should be last")
    }

    func testLoadDeduplicatesKeepingFirstOccurrence() async {
        let now = Date()
        // Station A played twice — most recent first, then older.
        // Station B played once between them.
        // After dedup, order should be: A (first occurrence), B
        let a1 = HistoryEntry(stationuuid: "A", name: "A", urlResolved: "http://a", playedAt: now)
        let b1 = HistoryEntry(stationuuid: "B", name: "B", urlResolved: "http://b", playedAt: now.addingTimeInterval(-60 * 60))
        let a2 = HistoryEntry(stationuuid: "A", name: "A", urlResolved: "http://a", playedAt: now.addingTimeInterval(-120 * 60))

        await historyService.setEntries([a1, b1, a2])

        let vm = RecentStationsViewModel(historyService: historyService)
        await vm.load()

        XCTAssertEqual(vm.entries.count, 2)
        XCTAssertEqual(vm.entries[0].stationuuid, "A", "First occurrence (most recent) should be kept")
        XCTAssertEqual(vm.entries[1].stationuuid, "B")
    }

    // MARK: - Refresh

    func testRefreshReloadsData() async {
        let vm = RecentStationsViewModel(historyService: historyService)
        await vm.load()
        XCTAssertTrue(vm.entries.isEmpty)

        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await historyService.recordPlay(station: station)

        await vm.refresh()
        XCTAssertEqual(vm.entries.count, 1)
    }

    // MARK: - Clear All

    func testClearAllRemovesEntries() async {
        let station = TestFixtures.makeStation(uuid: "uuid-1", name: "Station 1")
        await historyService.recordPlay(station: station)

        let vm = RecentStationsViewModel(historyService: historyService)
        await vm.load()
        XCTAssertEqual(vm.entries.count, 1)

        await vm.clearAll()
        XCTAssertTrue(vm.entries.isEmpty)

        // Also cleared from service
        let serviceEntries = await historyService.allEntries()
        XCTAssertTrue(serviceEntries.isEmpty)
    }

    // MARK: - Concurrency Guard

    func testLoadGuardsAgainstConcurrency() async {
        let vm = RecentStationsViewModel(historyService: historyService)
        vm.isLoading = true

        await vm.load()

        // Guard returned early, isLoading still true
        XCTAssertTrue(vm.isLoading)
    }
}
