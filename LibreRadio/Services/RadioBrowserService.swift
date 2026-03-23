import Foundation

actor RadioBrowserService {
    static let shared = RadioBrowserService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let discovery: ServerDiscoveryService

    init(discovery: ServerDiscoveryService = .shared, session: URLSession? = nil) {
        self.discovery = discovery

        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = ["User-Agent": "LibreRadio/1.0 (iOS; Swift)"]
            self.session = URLSession(configuration: config)
        }

        self.decoder = JSONDecoder()
    }

    // MARK: - Discovery Endpoints

    func fetchTopByClicks(limit: Int = 100) async throws -> [StationDTO] {
        try await fetch("/json/stations/topclick/\(limit)")
    }

    func fetchTopByVotes(limit: Int = 100) async throws -> [StationDTO] {
        try await fetch("/json/stations/topvote/\(limit)")
    }

    func fetchLastClick(limit: Int = 100) async throws -> [StationDTO] {
        try await fetch("/json/stations/lastclick/\(limit)")
    }

    func fetchLastChange(limit: Int = 100) async throws -> [StationDTO] {
        try await fetch("/json/stations/lastchange/\(limit)")
    }

    func fetchLocalStations(countrycode: String, limit: Int = 100) async throws -> [StationDTO] {
        try await fetch(
            "/json/stations/bycountrycodeexact/\(countrycode)",
            queryItems: [
                URLQueryItem(name: "order", value: "clickcount"),
                URLQueryItem(name: "reverse", value: "true"),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "hidebroken", value: "true"),
            ]
        )
    }

    // MARK: - Search

    func searchStations(
        name: String? = nil,
        countrycode: String? = nil,
        country: String? = nil,
        language: String? = nil,
        tag: String? = nil,
        tagList: String? = nil,
        codec: String? = nil,
        bitrateMin: Int? = nil,
        bitrateMax: Int? = nil,
        isHttps: Bool? = nil,
        order: String = "clickcount",
        reverse: Bool = true,
        limit: Int = 50,
        offset: Int = 0,
        hidebroken: Bool = true
    ) async throws -> [StationDTO] {
        var items = [URLQueryItem]()
        if let name, !name.isEmpty { items.append(URLQueryItem(name: "name", value: name)) }
        if let countrycode { items.append(URLQueryItem(name: "countrycode", value: countrycode)) }
        if let country { items.append(URLQueryItem(name: "country", value: country)) }
        if let language { items.append(URLQueryItem(name: "language", value: language)) }
        if let tag { items.append(URLQueryItem(name: "tag", value: tag)) }
        if let tagList { items.append(URLQueryItem(name: "tagList", value: tagList)) }
        if let codec { items.append(URLQueryItem(name: "codec", value: codec)) }
        if let bitrateMin { items.append(URLQueryItem(name: "bitrateMin", value: String(bitrateMin))) }
        if let bitrateMax { items.append(URLQueryItem(name: "bitrateMax", value: String(bitrateMax))) }
        if let isHttps { items.append(URLQueryItem(name: "is_https", value: isHttps ? "true" : "false")) }
        items.append(URLQueryItem(name: "order", value: order))
        items.append(URLQueryItem(name: "reverse", value: reverse ? "true" : "false"))
        items.append(URLQueryItem(name: "limit", value: String(limit)))
        items.append(URLQueryItem(name: "offset", value: String(offset)))
        items.append(URLQueryItem(name: "hidebroken", value: hidebroken ? "true" : "false"))

        return try await fetch("/json/stations/search", queryItems: items)
    }

    // MARK: - Browse

    func fetchCountries(hidebroken: Bool = true) async throws -> [Country] {
        try await fetch(
            "/json/countries",
            queryItems: [URLQueryItem(name: "hidebroken", value: hidebroken ? "true" : "false")]
        )
    }

    func fetchLanguages(hidebroken: Bool = true) async throws -> [Language] {
        try await fetch(
            "/json/languages",
            queryItems: [URLQueryItem(name: "hidebroken", value: hidebroken ? "true" : "false")]
        )
    }

    func fetchTags(
        limit: Int = 200,
        hidebroken: Bool = true,
        order: String = "stationcount",
        reverse: Bool = true
    ) async throws -> [Tag] {
        try await fetch(
            "/json/tags",
            queryItems: [
                URLQueryItem(name: "order", value: order),
                URLQueryItem(name: "reverse", value: reverse ? "true" : "false"),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "hidebroken", value: hidebroken ? "true" : "false"),
            ]
        )
    }

    // MARK: - Filtered Station Lists

    func fetchStationsByCountry(
        _ countrycode: String,
        order: String = "clickcount",
        reverse: Bool = true,
        limit: Int = 100,
        offset: Int = 0
    ) async throws -> [StationDTO] {
        try await fetch(
            "/json/stations/bycountrycodeexact/\(countrycode)",
            queryItems: [
                URLQueryItem(name: "order", value: order),
                URLQueryItem(name: "reverse", value: reverse ? "true" : "false"),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "hidebroken", value: "true"),
            ]
        )
    }

    func fetchStationsByLanguage(
        _ language: String,
        order: String = "clickcount",
        reverse: Bool = true,
        limit: Int = 100,
        offset: Int = 0
    ) async throws -> [StationDTO] {
        try await fetch(
            "/json/stations/bylanguageexact/\(language)",
            queryItems: [
                URLQueryItem(name: "order", value: order),
                URLQueryItem(name: "reverse", value: reverse ? "true" : "false"),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "hidebroken", value: "true"),
            ]
        )
    }

    func fetchStationsByTag(
        _ tag: String,
        order: String = "clickcount",
        reverse: Bool = true,
        limit: Int = 100,
        offset: Int = 0
    ) async throws -> [StationDTO] {
        try await fetch(
            "/json/stations/bytagexact/\(tag)",
            queryItems: [
                URLQueryItem(name: "order", value: order),
                URLQueryItem(name: "reverse", value: reverse ? "true" : "false"),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "hidebroken", value: "true"),
            ]
        )
    }

    // MARK: - Station Lookup

    func fetchStation(uuid: String) async throws -> StationDTO {
        let stations: [StationDTO] = try await fetch(
            "/json/stations/byuuid",
            queryItems: [URLQueryItem(name: "uuids", value: uuid)]
        )
        guard let station = stations.first else {
            throw AppError.decodingFailed(message: "Station not found: \(uuid)")
        }
        return station
    }

    func fetchStations(uuids: [String]) async throws -> [StationDTO] {
        try await fetch(
            "/json/stations/byuuid",
            queryItems: [URLQueryItem(name: "uuids", value: uuids.joined(separator: ","))]
        )
    }

    // MARK: - Analytics

    func trackClick(stationuuid: String) async {
        do {
            let _: ClickResponse = try await fetch("/json/url/\(stationuuid)")
        } catch {
            // Fire-and-forget — ignore errors
        }
    }

    func vote(stationuuid: String) async throws -> VoteResponse {
        try await fetch("/json/vote/\(stationuuid)")
    }

    // MARK: - Server Info

    func fetchStats() async throws -> ServerStats {
        try await fetch("/json/stats")
    }

    // MARK: - Internal

    private func fetch<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        await discovery.resolveIfNeeded()

        do {
            return try await performRequest(path: path, queryItems: queryItems)
        } catch {
            // Rotate server and retry once
            await discovery.rotateServer()
            return try await performRequest(path: path, queryItems: queryItems)
        }
    }

    private func performRequest<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        let baseURL = await discovery.currentBaseURL
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw AppError.networkUnavailable
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw AppError.networkUnavailable
        }

        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw AppError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decodingFailed(message: error.localizedDescription)
        }
    }
}
