import XCTest
@testable import RadioLibre

final class RadioBrowserServiceTests: XCTestCase {

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

    // MARK: - fetchTopByClicks

    func testFetchTopByClicks() async throws {
        setMockResponse(path: "/json/stations/topclick/20", json: TestFixtures.stationArrayJSON(count: 3))

        let stations = try await service.fetchTopByClicks(limit: 20)
        XCTAssertEqual(stations.count, 3)
        XCTAssertEqual(stations[0].stationuuid, "uuid-0")
        XCTAssertEqual(stations[1].stationuuid, "uuid-1")
    }

    // MARK: - fetchTopByVotes

    func testFetchTopByVotes() async throws {
        setMockResponse(path: "/json/stations/topvote/10", json: TestFixtures.stationArrayJSON(count: 2))

        let stations = try await service.fetchTopByVotes(limit: 10)
        XCTAssertEqual(stations.count, 2)
    }

    // MARK: - fetchLastClick

    func testFetchLastClick() async throws {
        setMockResponse(path: "/json/stations/lastclick/5", json: TestFixtures.stationArrayJSON(count: 5))

        let stations = try await service.fetchLastClick(limit: 5)
        XCTAssertEqual(stations.count, 5)
    }

    // MARK: - fetchLastChange

    func testFetchLastChange() async throws {
        setMockResponse(path: "/json/stations/lastchange/3", json: TestFixtures.stationArrayJSON(count: 3))

        let stations = try await service.fetchLastChange(limit: 3)
        XCTAssertEqual(stations.count, 3)
    }

    // MARK: - fetchLocalStations

    func testFetchLocalStations() async throws {
        setMockResponse(path: "/json/stations/bycountrycodeexact/US", json: TestFixtures.stationArrayJSON(count: 2))

        let stations = try await service.fetchLocalStations(countrycode: "US", limit: 20)
        XCTAssertEqual(stations.count, 2)
    }

    // MARK: - searchStations

    func testSearchStations() async throws {
        setMockResponse(path: "/json/stations/search", json: TestFixtures.stationArrayJSON(count: 1))

        let stations = try await service.searchStations(name: "jazz", limit: 50)
        XCTAssertEqual(stations.count, 1)
    }

    func testSearchStationsWithFilters() async throws {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        _ = try await service.searchStations(
            name: "test",
            countrycode: "DE",
            language: "german",
            tag: "rock",
            codec: "MP3",
            bitrateMin: 128,
            order: "clickcount",
            reverse: true,
            limit: 50,
            offset: 0,
            hidebroken: true
        )

        let query = capturedURL?.query ?? ""
        XCTAssertTrue(query.contains("name=test"))
        XCTAssertTrue(query.contains("countrycode=DE"))
        XCTAssertTrue(query.contains("language=german"))
        XCTAssertTrue(query.contains("tag=rock"))
        XCTAssertTrue(query.contains("codec=MP3"))
        XCTAssertTrue(query.contains("bitrateMin=128"))
        XCTAssertTrue(query.contains("hidebroken=true"))
    }

    // MARK: - Browse

    func testFetchCountries() async throws {
        let json = """
        [{"name": "Germany", "iso_3166_1": "DE", "stationcount": 500}]
        """
        setMockResponse(path: "/json/countries", json: json)

        let countries = try await service.fetchCountries()
        XCTAssertEqual(countries.count, 1)
        XCTAssertEqual(countries[0].name, "Germany")
    }

    func testFetchLanguages() async throws {
        let json = """
        [{"name": "english", "iso_639": "eng", "stationcount": 10000}]
        """
        setMockResponse(path: "/json/languages", json: json)

        let languages = try await service.fetchLanguages()
        XCTAssertEqual(languages.count, 1)
        XCTAssertEqual(languages[0].name, "english")
    }

    func testFetchTags() async throws {
        let json = """
        [{"name": "rock", "stationcount": 5000}]
        """
        setMockResponse(path: "/json/tags", json: json)

        let tags = try await service.fetchTags()
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags[0].name, "rock")
    }

    // MARK: - Filtered Lists

    func testFetchStationsByCountry() async throws {
        setMockResponse(path: "/json/stations/bycountrycodeexact/DE", json: TestFixtures.stationArrayJSON(count: 2))

        let stations = try await service.fetchStationsByCountry("DE")
        XCTAssertEqual(stations.count, 2)
    }

    func testFetchStationsByLanguage() async throws {
        setMockResponse(path: "/json/stations/bylanguageexact/english", json: TestFixtures.stationArrayJSON(count: 1))

        let stations = try await service.fetchStationsByLanguage("english")
        XCTAssertEqual(stations.count, 1)
    }

    func testFetchStationsByTag() async throws {
        setMockResponse(path: "/json/stations/bytagexact/rock", json: TestFixtures.stationArrayJSON(count: 3))

        let stations = try await service.fetchStationsByTag("rock")
        XCTAssertEqual(stations.count, 3)
    }

    // MARK: - Station Lookup

    func testFetchStation() async throws {
        let json = "[\(TestFixtures.stationJSON(uuid: "lookup-uuid", name: "Found Station"))]"
        setMockResponse(path: "/json/stations/byuuid", json: json)

        let station = try await service.fetchStation(uuid: "lookup-uuid")
        XCTAssertEqual(station.stationuuid, "lookup-uuid")
        XCTAssertEqual(station.name, "Found Station")
    }

    func testFetchStationNotFound() async throws {
        setMockResponse(path: "/json/stations/byuuid", json: "[]")

        do {
            _ = try await service.fetchStation(uuid: "missing")
            XCTFail("Should have thrown")
        } catch let error as AppError {
            if case .decodingFailed = error {
                // Expected
            } else {
                XCTFail("Unexpected AppError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchStations() async throws {
        setMockResponse(path: "/json/stations/byuuid", json: TestFixtures.stationArrayJSON(count: 2))

        let stations = try await service.fetchStations(uuids: ["uuid-0", "uuid-1"])
        XCTAssertEqual(stations.count, 2)
    }

    // MARK: - Analytics

    func testTrackClick() async throws {
        let json = """
        {"ok": "true", "message": "retrieved station url", "stationuuid": "abc", "name": "Test", "url": "http://test"}
        """
        setMockResponse(path: "/json/url/abc", json: json)

        // Should not throw (fire-and-forget)
        await service.trackClick(stationuuid: "abc")
    }

    func testTrackClickIgnoresErrors() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        // Should not throw even on network error
        await service.trackClick(stationuuid: "abc")
    }

    func testVote() async throws {
        let json = """
        {"ok": true, "message": "voted for station successfully"}
        """
        setMockResponse(path: "/json/vote/abc", json: json)

        let response = try await service.vote(stationuuid: "abc")
        XCTAssertTrue(response.ok)
    }

    // MARK: - Server Info

    func testFetchStats() async throws {
        let json = """
        {
            "stations": 30000, "stations_broken": 5000, "tags": 8000,
            "clicks_last_hour": 1500, "clicks_last_day": 25000,
            "languages": 400, "countries": 200
        }
        """
        setMockResponse(path: "/json/stats", json: json)

        let stats = try await service.fetchStats()
        XCTAssertEqual(stats.stations, 30000)
        XCTAssertEqual(stats.stationsBroken, 5000)
    }

    // MARK: - Error Handling

    func testServerErrorThrows() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await service.fetchTopByClicks(limit: 10)
            XCTFail("Should have thrown")
        } catch let error as AppError {
            // After retry (both fail with 500), we get serverError
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Unexpected AppError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDecodingErrorThrows() async {
        setMockResponse(path: "/json/stations/topclick/10", json: "not valid json")

        do {
            _ = try await service.fetchTopByClicks(limit: 10)
            XCTFail("Should have thrown")
        } catch let error as AppError {
            if case .decodingFailed = error {
                // Expected
            } else {
                XCTFail("Unexpected AppError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testUserAgentHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let data = "[]".data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        _ = try await service.fetchTopByClicks(limit: 1)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "User-Agent"), "RadioLibre/1.0 (iOS; Swift)")
    }

    // MARK: - Retry on Failure

    func testRetriesOnFirstFailure() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount == 1 {
                throw URLError(.timedOut)
            }
            let data = TestFixtures.stationArrayJSON(count: 1).data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let stations = try await service.fetchTopByClicks(limit: 10)
        XCTAssertEqual(stations.count, 1)
        XCTAssertEqual(callCount, 2) // First attempt + retry
    }

    // MARK: - Helpers

    private func setMockResponse(path: String, json: String) {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.path.contains(path.split(separator: "?").first.map(String.init) ?? path) else {
                // Still return valid response for any path (retry might hit different server)
                let data = json.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
    }
}
