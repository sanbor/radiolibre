import XCTest
@testable import RadioLibre

@MainActor
final class DiscoverViewModelTests: XCTestCase {

    private var discovery: ServerDiscoveryService!
    private var service: RadioBrowserService!

    override func setUp() async throws {
        discovery = ServerDiscoveryService()
        await discovery.setServers(["mock.api.radio-browser.info"])

        let session = TestFixtures.makeMockSession()
        service = RadioBrowserService(discovery: discovery, session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
    }

    func testLoadPopulatesAllSections() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 2).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = DiscoverViewModel(service: service)
        await vm.load()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
        XCTAssertEqual(vm.topByClicks.count, 2)
        XCTAssertEqual(vm.topByVotes.count, 2)
        XCTAssertEqual(vm.localStations.count, 2)
        XCTAssertEqual(vm.recentlyChanged.count, 2)
        XCTAssertEqual(vm.currentlyPlaying.count, 2)
    }

    func testLoadSetsErrorOnFailure() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = DiscoverViewModel(service: service)
        await vm.load()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.error)
    }

    func testLoadSetsErrorForServerError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let vm = DiscoverViewModel(service: service)
        await vm.load()

        XCTAssertNotNil(vm.error)
    }

    func testRefreshReloadsData() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = DiscoverViewModel(service: service)
        await vm.load()
        let firstCallCount = callCount
        XCTAssertGreaterThan(firstCallCount, 0)

        await vm.refresh()
        XCTAssertGreaterThan(callCount, firstCallCount)
    }

    func testLoadGuardsAgainstConcurrency() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = DiscoverViewModel(service: service)
        vm.isLoading = true // simulate already loading

        // Should return immediately due to guard
        await vm.load()

        // isLoading still true because guard returned early
        XCTAssertTrue(vm.isLoading)
    }

    func testInitialState() {
        let vm = DiscoverViewModel(service: service)

        XCTAssertTrue(vm.localStations.isEmpty)
        XCTAssertTrue(vm.topByClicks.isEmpty)
        XCTAssertTrue(vm.topByVotes.isEmpty)
        XCTAssertTrue(vm.recentlyChanged.isEmpty)
        XCTAssertTrue(vm.currentlyPlaying.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }
}
