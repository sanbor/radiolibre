import XCTest
@testable import RadioLibre

final class ModelDecodingTests: XCTestCase {

    // MARK: - Country

    func testDecodeCountry() throws {
        let json = """
        {"name": "Germany", "iso_3166_1": "DE", "stationcount": 500}
        """.data(using: .utf8)!

        let country = try JSONDecoder().decode(Country.self, from: json)
        XCTAssertEqual(country.name, "Germany")
        XCTAssertEqual(country.iso_3166_1, "DE")
        XCTAssertEqual(country.stationcount, 500)
        XCTAssertEqual(country.id, "Germany")
    }

    func testDecodeCountryArray() throws {
        let json = """
        [
            {"name": "Germany", "iso_3166_1": "DE", "stationcount": 500},
            {"name": "United States", "iso_3166_1": "US", "stationcount": 3000}
        ]
        """.data(using: .utf8)!

        let countries = try JSONDecoder().decode([Country].self, from: json)
        XCTAssertEqual(countries.count, 2)
        XCTAssertEqual(countries[0].iso_3166_1, "DE")
        XCTAssertEqual(countries[1].iso_3166_1, "US")
    }

    // MARK: - Language

    func testDecodeLanguage() throws {
        let json = """
        {"name": "english", "iso_639": "eng", "stationcount": 10000}
        """.data(using: .utf8)!

        let language = try JSONDecoder().decode(Language.self, from: json)
        XCTAssertEqual(language.name, "english")
        XCTAssertEqual(language.iso_639, "eng")
        XCTAssertEqual(language.stationcount, 10000)
        XCTAssertEqual(language.id, "english")
    }

    func testDecodeLanguageNilIso() throws {
        let json = """
        {"name": "unknown", "stationcount": 5}
        """.data(using: .utf8)!

        let language = try JSONDecoder().decode(Language.self, from: json)
        XCTAssertNil(language.iso_639)
    }

    // MARK: - Tag

    func testDecodeTag() throws {
        let json = """
        {"name": "rock", "stationcount": 5000}
        """.data(using: .utf8)!

        let tag = try JSONDecoder().decode(Tag.self, from: json)
        XCTAssertEqual(tag.name, "rock")
        XCTAssertEqual(tag.stationcount, 5000)
        XCTAssertEqual(tag.id, "rock")
    }

    // MARK: - ClickResponse

    func testDecodeClickResponse() throws {
        let json = """
        {
            "ok": "true",
            "message": "retrieved station url",
            "stationuuid": "abc-123",
            "name": "Test Radio",
            "url": "http://stream.test/live"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ClickResponse.self, from: json)
        XCTAssertEqual(response.ok, "true")
        XCTAssertEqual(response.message, "retrieved station url")
        XCTAssertEqual(response.stationuuid, "abc-123")
        XCTAssertEqual(response.name, "Test Radio")
        XCTAssertEqual(response.url, "http://stream.test/live")
    }

    // MARK: - VoteResponse

    func testDecodeVoteResponse() throws {
        let json = """
        {"ok": true, "message": "voted for station successfully"}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VoteResponse.self, from: json)
        XCTAssertTrue(response.ok)
        XCTAssertEqual(response.message, "voted for station successfully")
    }

    func testDecodeVoteResponseFailed() throws {
        let json = """
        {"ok": false, "message": "too many votes"}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VoteResponse.self, from: json)
        XCTAssertFalse(response.ok)
    }

    // MARK: - ServerStats

    func testDecodeServerStats() throws {
        let json = """
        {
            "stations": 30000,
            "stations_broken": 5000,
            "tags": 8000,
            "clicks_last_hour": 1500,
            "clicks_last_day": 25000,
            "languages": 400,
            "countries": 200
        }
        """.data(using: .utf8)!

        let stats = try JSONDecoder().decode(ServerStats.self, from: json)
        XCTAssertEqual(stats.stations, 30000)
        XCTAssertEqual(stats.stationsBroken, 5000)
        XCTAssertEqual(stats.tags, 8000)
        XCTAssertEqual(stats.clicksLastHour, 1500)
        XCTAssertEqual(stats.clicksLastDay, 25000)
        XCTAssertEqual(stats.languages, 400)
        XCTAssertEqual(stats.countries, 200)
    }
}
