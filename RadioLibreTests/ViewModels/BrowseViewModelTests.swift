import XCTest
@testable import RadioLibre

@MainActor
final class BrowseViewModelTests: XCTestCase {

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

    // MARK: - Countries

    func testLoadCountriesSuccess() async {
        let json = """
        [
            {"name": "Germany", "iso_3166_1": "DE", "stationcount": 500},
            {"name": "France", "iso_3166_1": "FR", "stationcount": 300},
            {"name": "United States", "iso_3166_1": "US", "stationcount": 1000}
        ]
        """
        setMockResponse(json: json)

        let vm = BrowseViewModel(service: service)
        await vm.loadCountries()

        XCTAssertEqual(vm.countries.count, 3)
        // Should be sorted by stationcount descending
        XCTAssertEqual(vm.countries[0].name, "United States")
        XCTAssertEqual(vm.countries[1].name, "Germany")
        XCTAssertEqual(vm.countries[2].name, "France")
        XCTAssertFalse(vm.isLoadingCountries)
        XCTAssertNil(vm.countriesError)
    }

    func testLoadCountriesError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = BrowseViewModel(service: service)
        await vm.loadCountries()

        XCTAssertTrue(vm.countries.isEmpty)
        XCTAssertNotNil(vm.countriesError)
        XCTAssertFalse(vm.isLoadingCountries)
    }

    func testLoadCountriesGuardsConcurrency() async {
        setMockResponse(json: "[]")

        let vm = BrowseViewModel(service: service)
        vm.isLoadingCountries = true

        await vm.loadCountries()
        // Should return immediately due to guard
        XCTAssertTrue(vm.isLoadingCountries)
    }

    // MARK: - Languages

    func testLoadLanguagesSuccess() async {
        let json = """
        [
            {"name": "english", "iso_639": "eng", "stationcount": 10000},
            {"name": "german", "iso_639": "deu", "stationcount": 5000}
        ]
        """
        setMockResponse(json: json)

        let vm = BrowseViewModel(service: service)
        await vm.loadLanguages()

        XCTAssertEqual(vm.languages.count, 2)
        XCTAssertEqual(vm.languages[0].name, "english")
        XCTAssertEqual(vm.languages[1].name, "german")
        XCTAssertFalse(vm.isLoadingLanguages)
        XCTAssertNil(vm.languagesError)
    }

    func testLoadLanguagesError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = BrowseViewModel(service: service)
        await vm.loadLanguages()

        XCTAssertTrue(vm.languages.isEmpty)
        XCTAssertNotNil(vm.languagesError)
        XCTAssertFalse(vm.isLoadingLanguages)
    }

    func testLoadLanguagesGuardsConcurrency() async {
        setMockResponse(json: "[]")

        let vm = BrowseViewModel(service: service)
        vm.isLoadingLanguages = true

        await vm.loadLanguages()
        XCTAssertTrue(vm.isLoadingLanguages)
    }

    // MARK: - Tags

    func testLoadTagsSuccess() async {
        let json = """
        [
            {"name": "rock", "stationcount": 5000},
            {"name": "pop", "stationcount": 3000},
            {"name": "jazz", "stationcount": 2000}
        ]
        """
        setMockResponse(json: json)

        let vm = BrowseViewModel(service: service)
        await vm.loadTags()

        XCTAssertEqual(vm.tags.count, 3)
        XCTAssertEqual(vm.tags[0].name, "rock")
        XCTAssertEqual(vm.tags[1].name, "pop")
        XCTAssertEqual(vm.tags[2].name, "jazz")
        XCTAssertFalse(vm.isLoadingTags)
        XCTAssertNil(vm.tagsError)
    }

    func testLoadTagsError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = BrowseViewModel(service: service)
        await vm.loadTags()

        XCTAssertTrue(vm.tags.isEmpty)
        XCTAssertNotNil(vm.tagsError)
        XCTAssertFalse(vm.isLoadingTags)
    }

    func testLoadTagsGuardsConcurrency() async {
        setMockResponse(json: "[]")

        let vm = BrowseViewModel(service: service)
        vm.isLoadingTags = true

        await vm.loadTags()
        XCTAssertTrue(vm.isLoadingTags)
    }

    // MARK: - Initial State

    func testInitialState() {
        let vm = BrowseViewModel(service: service)

        XCTAssertTrue(vm.countries.isEmpty)
        XCTAssertTrue(vm.languages.isEmpty)
        XCTAssertTrue(vm.tags.isEmpty)
        XCTAssertFalse(vm.isLoadingCountries)
        XCTAssertFalse(vm.isLoadingLanguages)
        XCTAssertFalse(vm.isLoadingTags)
        XCTAssertNil(vm.countriesError)
        XCTAssertNil(vm.languagesError)
        XCTAssertNil(vm.tagsError)
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
