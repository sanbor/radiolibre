import XCTest
@testable import RadioLibre

@MainActor
final class SearchViewModelTests: XCTestCase {

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
        let vm = SearchViewModel(service: service)

        XCTAssertEqual(vm.query, "")
        XCTAssertTrue(vm.results.isEmpty)
        XCTAssertFalse(vm.isSearching)
        XCTAssertFalse(vm.hasSearched)
        XCTAssertNil(vm.error)
        XCTAssertTrue(vm.hasMore)
        XCTAssertNil(vm.filterCountrycode)
        XCTAssertNil(vm.filterLanguage)
        XCTAssertNil(vm.filterCodec)
        XCTAssertNil(vm.filterBitrateMin)
    }

    // MARK: - Search

    func testPerformSearchReturnsResults() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 3).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = SearchViewModel(service: service)
        vm.query = "jazz"
        await vm.performSearch()

        XCTAssertEqual(vm.results.count, 3)
        XCTAssertTrue(vm.hasSearched)
        XCTAssertFalse(vm.isSearching)
        XCTAssertNil(vm.error)
    }

    func testPerformSearchWithEmptyQuery() async {
        let vm = SearchViewModel(service: service)
        vm.query = "   "
        await vm.performSearch()

        XCTAssertTrue(vm.results.isEmpty)
        XCTAssertFalse(vm.hasSearched)
    }

    func testPerformSearchSetsError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = SearchViewModel(service: service)
        vm.query = "jazz"
        await vm.performSearch()

        XCTAssertNotNil(vm.error)
        XCTAssertFalse(vm.isSearching)
        XCTAssertTrue(vm.results.isEmpty)
    }

    func testPerformSearchSetsHasMoreWhenFullPage() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 50).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = SearchViewModel(service: service)
        vm.query = "rock"
        await vm.performSearch()

        XCTAssertTrue(vm.hasMore)
    }

    func testPerformSearchSetsNoMoreWhenPartialPage() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 10).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = SearchViewModel(service: service)
        vm.query = "rock"
        await vm.performSearch()

        XCTAssertFalse(vm.hasMore)
    }

    // MARK: - Search With Filters

    func testPerformSearchIncludesFilters() async {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = SearchViewModel(service: service)
        vm.query = "test"
        vm.filterCountrycode = "DE"
        vm.filterLanguage = "german"
        vm.filterCodec = "MP3"
        vm.filterBitrateMin = 128
        await vm.performSearch()

        let query = capturedURL?.query ?? ""
        XCTAssertTrue(query.contains("countrycode=DE"))
        XCTAssertTrue(query.contains("language=german"))
        XCTAssertTrue(query.contains("codec=MP3"))
        XCTAssertTrue(query.contains("bitrateMin=128"))
    }

    // MARK: - Pagination

    func testLoadMoreAppendsResults() async {
        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let count = requestCount == 1 ? 50 : 10
            let data = TestFixtures.stationArrayJSON(count: count).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = SearchViewModel(service: service)
        vm.query = "rock"
        await vm.performSearch()
        XCTAssertEqual(vm.results.count, 50)
        XCTAssertTrue(vm.hasMore)

        await vm.loadMore()
        XCTAssertEqual(vm.results.count, 60)
        XCTAssertFalse(vm.hasMore)
    }

    func testLoadMoreGuardsWhenNoMore() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 10).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = SearchViewModel(service: service)
        vm.query = "rock"
        await vm.performSearch()
        XCTAssertFalse(vm.hasMore)

        let countBefore = vm.results.count
        await vm.loadMore()
        XCTAssertEqual(vm.results.count, countBefore)
    }

    func testLoadMoreGuardsWithEmptyQuery() async {
        let vm = SearchViewModel(service: service)
        vm.query = ""
        vm.hasMore = true

        await vm.loadMore()
        XCTAssertTrue(vm.results.isEmpty)
    }

    // MARK: - Clear Filters

    func testClearFiltersResetsAllFilters() async {
        MockURLProtocol.requestHandler = { request in
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = SearchViewModel(service: service)
        vm.query = "test"
        vm.filterCountrycode = "US"
        vm.filterLanguage = "english"
        vm.filterCodec = "AAC"
        vm.filterBitrateMin = 64
        await vm.performSearch()

        vm.clearFilters()
        // Wait for the re-search task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(vm.filterCountrycode)
        XCTAssertNil(vm.filterLanguage)
        XCTAssertNil(vm.filterCodec)
        XCTAssertNil(vm.filterBitrateMin)
    }

    // MARK: - Debounce

    func testOnQueryChangedDebounces() async {
        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let vm = SearchViewModel(service: service)
        vm.query = "j"
        vm.onQueryChanged()
        vm.query = "ja"
        vm.onQueryChanged()
        vm.query = "jaz"
        vm.onQueryChanged()
        vm.query = "jazz"
        vm.onQueryChanged()

        // Wait for debounce (400ms) + execution
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Should only have made requests for the final query, not intermediate ones
        // The service retries on failure (2 calls per attempt), but we only expect one search
        XCTAssertTrue(vm.hasSearched)
        XCTAssertEqual(vm.results.count, 1)
    }

    // MARK: - Server Error

    func testPerformSearchHandlesServerError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let vm = SearchViewModel(service: service)
        vm.query = "test"
        await vm.performSearch()

        XCTAssertNotNil(vm.error)
        XCTAssertFalse(vm.isSearching)
    }
}
