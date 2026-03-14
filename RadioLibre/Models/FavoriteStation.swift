import Foundation

struct FavoriteStation: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let stationuuid: String
    let name: String
    let urlResolved: String
    let faviconURL: String?
    let tags: String?
    let countrycode: String?
    let language: String?
    let codec: String?
    let bitrate: Int
    var addedAt: Date
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        stationuuid: String,
        name: String,
        urlResolved: String,
        faviconURL: String? = nil,
        tags: String? = nil,
        countrycode: String? = nil,
        language: String? = nil,
        codec: String? = nil,
        bitrate: Int = 0,
        addedAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.stationuuid = stationuuid
        self.name = name
        self.urlResolved = urlResolved
        self.faviconURL = faviconURL
        self.tags = tags
        self.countrycode = countrycode
        self.language = language
        self.codec = codec
        self.bitrate = bitrate
        self.addedAt = addedAt
        self.sortOrder = sortOrder
    }

    init(from station: StationDTO, sortOrder: Int = 0) {
        self.id = UUID()
        self.stationuuid = station.stationuuid
        self.name = station.name
        self.urlResolved = station.urlResolved ?? station.url
        self.faviconURL = station.favicon
        self.tags = station.tags
        self.countrycode = station.countrycode
        self.language = station.language
        self.codec = station.codec
        self.bitrate = station.bitrate ?? 0
        self.addedAt = Date()
        self.sortOrder = sortOrder
    }

    var bitrateLabel: String {
        guard bitrate > 0 else { return "—" }
        return "\(bitrate)k"
    }

    var tagList: [String] {
        guard let tags, !tags.isEmpty else { return [] }
        return tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    func toStationDTO() -> StationDTO {
        StationDTO(
            stationuuid: stationuuid,
            name: name,
            url: urlResolved,
            urlResolved: urlResolved,
            homepage: nil,
            favicon: faviconURL,
            tags: tags,
            country: nil,
            countrycode: countrycode,
            state: nil,
            language: language,
            languagecodes: nil,
            codec: codec,
            bitrate: bitrate,
            hls: nil,
            votes: nil,
            clickcount: nil,
            clicktrend: nil,
            lastcheckok: nil,
            lastcheckoktime: nil,
            lastcheckoktime_iso8601: nil,
            geoLat: nil,
            geoLong: nil,
            hasExtendedInfo: nil
        )
    }
}
