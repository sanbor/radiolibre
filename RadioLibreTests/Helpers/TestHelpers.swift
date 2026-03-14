import Foundation
@testable import RadioLibre

enum TestFixtures {
    static func stationJSON(
        uuid: String = "test-uuid",
        name: String = "Test Radio",
        url: String = "http://stream.test/live",
        urlResolved: String = "http://stream.test/resolved",
        tags: String = "rock,pop",
        country: String = "Germany",
        countrycode: String = "DE",
        state: String = "Berlin",
        codec: String = "MP3",
        bitrate: Int = 128
    ) -> String {
        """
        {
            "stationuuid": "\(uuid)",
            "name": "\(name)",
            "url": "\(url)",
            "url_resolved": "\(urlResolved)",
            "tags": "\(tags)",
            "country": "\(country)",
            "countrycode": "\(countrycode)",
            "state": "\(state)",
            "codec": "\(codec)",
            "bitrate": \(bitrate),
            "lastcheckok": 1,
            "hls": 0,
            "votes": 10,
            "clickcount": 50,
            "clicktrend": 3
        }
        """
    }

    static func stationArrayJSON(count: Int = 3) -> String {
        let stations = (0..<count).map { i in
            stationJSON(uuid: "uuid-\(i)", name: "Station \(i)")
        }
        return "[\(stations.joined(separator: ","))]"
    }

    static func makeStation(
        uuid: String = "test-uuid",
        name: String = "Test Radio",
        country: String? = nil,
        countrycode: String? = nil,
        state: String? = nil
    ) -> StationDTO {
        StationDTOTests.makeStation(uuid: uuid, name: name, tags: "rock,pop", country: country, countrycode: countrycode, state: state, codec: "MP3", bitrate: 128)
    }

    static func makeFavoriteStation(
        uuid: String = "test-uuid",
        name: String = "Test Radio",
        urlResolved: String = "http://stream.test/resolved",
        tags: String? = "rock,pop",
        codec: String? = "MP3",
        bitrate: Int = 128,
        sortOrder: Int = 0
    ) -> FavoriteStation {
        FavoriteStation(
            stationuuid: uuid,
            name: name,
            urlResolved: urlResolved,
            tags: tags,
            codec: codec,
            bitrate: bitrate,
            sortOrder: sortOrder
        )
    }

    static func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.httpAdditionalHeaders = ["User-Agent": "RadioLibre/1.0 (iOS; Swift)"]
        return URLSession(configuration: config)
    }
}
