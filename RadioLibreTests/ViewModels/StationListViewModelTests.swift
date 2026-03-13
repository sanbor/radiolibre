import XCTest
@testable import RadioLibre

@MainActor
final class StationListViewModelTests: XCTestCase {

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

    // MARK: - Initial State

    func testInitialState() {
        let vm = StationListViewModel(filter: .country("DE"), service: service)

        XCTAssertTrue(vm.stations.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isLoadingMore)
        XCTAssertNil(vm.error)
        XCTAssertTrue(vm.hasMore)
        XCTAssertEqual(vm.title, "DE")
    }

    func testExplicitTitleOverridesDefault() {
        let vm = StationListViewModel(filter: .country("DE"), title: "Germany", service: service)
        XCTAssertEqual(vm.title, "Germany")
    }

    func testTitleForLanguage() {
        let vm = StationListViewModel(filter: .language("english"), service: service)
        XCTAssertEqual(vm.title, "English")
    }

    func testTitleForTag() {
        let vm = StationListViewModel(filter: .tag("rock"), service: service)
        XCTAssertEqual(vm.title, "Rock")
    }

    // MARK: - Load

    func testLoadByCountry() async {
        setMockResponse(json: TestFixtures.stationArrayJSON(count: 5))

        let vm = StationListViewModel(filter: .country("DE"), service: service)
        await vm.load()

        XCTAssertEqual(vm.stations.count, 5)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
        XCTAssertFalse(vm.hasMore) // 5 < 100
    }

    func testLoadByLanguage() async {
        setMockResponse(json: TestFixtures.stationArrayJSON(count: 3))

        let vm = StationListViewModel(filter: .language("english"), service: service)
        await vm.load()

        XCTAssertEqual(vm.stations.count, 3)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadByTag() async {
        setMockResponse(json: TestFixtures.stationArrayJSON(count: 2))

        let vm = StationListViewModel(filter: .tag("rock"), service: service)
        await vm.load()

        XCTAssertEqual(vm.stations.count, 2)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadSetsHasMoreWhenFullPage() async {
        setMockResponse(json: TestFixtures.stationArrayJSON(count: 100))

        let vm = StationListViewModel(filter: .country("US"), service: service)
        await vm.load()

        XCTAssertTrue(vm.hasMore)
    }

    func testLoadSetsError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = StationListViewModel(filter: .country("DE"), service: service)
        await vm.load()

        XCTAssertNotNil(vm.error)
        XCTAssertTrue(vm.stations.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadGuardsConcurrency() async {
        setMockResponse(json: TestFixtures.stationArrayJSON(count: 1))

        let vm = StationListViewModel(filter: .country("DE"), service: service)
        vm.isLoading = true

        await vm.load()
        // Should return early due to guard
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.stations.isEmpty)
    }

    // MARK: - Load More

    func testLoadMoreAppendsResults() async {
        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let count = requestCount == 1 ? 100 : 20
            let startIndex = requestCount == 1 ? 0 : 100
            let stations = (startIndex..<(startIndex + count)).map { i in
                TestFixtures.stationJSON(uuid: "uuid-\(i)", name: "Station \(i)")
            }
            let json = "[\(stations.joined(separator: ","))]"
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = StationListViewModel(filter: .country("US"), service: service)
        await vm.load()
        XCTAssertEqual(vm.stations.count, 100)
        XCTAssertTrue(vm.hasMore)

        await vm.loadMore()
        XCTAssertEqual(vm.stations.count, 120)
        XCTAssertFalse(vm.hasMore)
        XCTAssertFalse(vm.isLoadingMore)
    }

    func testLoadMoreGuardsWhenNoMore() async {
        setMockResponse(json: TestFixtures.stationArrayJSON(count: 10))

        let vm = StationListViewModel(filter: .country("DE"), service: service)
        await vm.load()
        XCTAssertFalse(vm.hasMore)

        let countBefore = vm.stations.count
        await vm.loadMore()
        XCTAssertEqual(vm.stations.count, countBefore)
    }

    func testLoadMoreGuardsWhenAlreadyLoading() async {
        setMockResponse(json: TestFixtures.stationArrayJSON(count: 100))

        let vm = StationListViewModel(filter: .country("DE"), service: service)
        await vm.load()
        vm.isLoadingMore = true

        let countBefore = vm.stations.count
        await vm.loadMore()
        XCTAssertEqual(vm.stations.count, countBefore)
    }

    func testLoadMoreSetsErrorAndRollsBackOffset() async {
        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            if requestCount <= 1 {
                let data = TestFixtures.stationArrayJSON(count: 100).data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }
            throw URLError(.notConnectedToInternet)
        }

        let vm = StationListViewModel(filter: .country("US"), service: service)
        await vm.load()
        XCTAssertEqual(vm.stations.count, 100)

        await vm.loadMore()
        XCTAssertNotNil(vm.error)
        XCTAssertEqual(vm.stations.count, 100) // No new stations appended
        XCTAssertFalse(vm.isLoadingMore)
    }

    // MARK: - Server Error

    func testLoadHandlesServerError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let vm = StationListViewModel(filter: .tag("jazz"), service: service)
        await vm.load()

        XCTAssertNotNil(vm.error)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Helpers

    private func setMockResponse(json: String) {
        MockURLProtocol.requestHandler = { request in
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
    }
}
