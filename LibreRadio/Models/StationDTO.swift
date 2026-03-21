import Foundation

struct StationDTO: Codable, Identifiable, Hashable, Sendable {
    var id: String { stationuuid }

    let stationuuid: String
    let name: String
    let url: String
    let urlResolved: String?
    let homepage: String?
    let favicon: String?
    let tags: String?
    let country: String?
    let countrycode: String?
    let state: String?
    let language: String?
    let languagecodes: String?
    let codec: String?
    let bitrate: Int?
    let hls: Int?
    let votes: Int?
    let clickcount: Int?
    let clicktrend: Int?
    let lastcheckok: Int?
    let lastcheckoktime: String?
    let lastcheckoktime_iso8601: String?
    let geoLat: Double?
    let geoLong: Double?
    let hasExtendedInfo: Bool?

    var tagList: [String] {
        guard let tags, !tags.isEmpty else { return [] }
        return tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var isHLS: Bool { hls == 1 }
    var isOnline: Bool { lastcheckok == 1 }

    var streamURL: URL? {
        if let urlResolved, let url = URL(string: urlResolved) { return url }
        return URL(string: url)
    }

    var faviconURL: URL? {
        guard let favicon, !favicon.isEmpty else { return nil }
        let secured = favicon.hasPrefix("http://")
            ? "https://" + favicon.dropFirst(7)
            : favicon
        return URL(string: secured)
    }

    var homepageURL: URL? {
        guard let homepage, !homepage.isEmpty else { return nil }
        if let url = URL(string: homepage) { return url }
        return URL(string: homepage.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? homepage)
    }

    var bitrateLabel: String {
        guard let bitrate, bitrate > 0 else { return "—" }
        return "\(bitrate)k"
    }

    var countryDisplayName: String? {
        guard let countrycode, countrycode.count == 2,
              let localized = Locale(identifier: "en").localizedString(forRegionCode: countrycode)
        else { return country }
        return localized
    }

    var flagEmoji: String? {
        guard let countrycode, countrycode.count == 2 else { return nil }
        return getFlag(from: countrycode)
    }

    var locationLabel: String? {
        guard let countrycode, countrycode.count == 2 else { return nil }
        return countryDisplayName ?? countrycode.uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case stationuuid, name, url
        case urlResolved = "url_resolved"
        case homepage, favicon, tags, country, countrycode, state
        case language, languagecodes, codec, bitrate, hls
        case votes, clickcount, clicktrend, lastcheckok, lastcheckoktime
        case lastcheckoktime_iso8601
        case geoLat = "geo_lat"
        case geoLong = "geo_long"
        case hasExtendedInfo = "has_extended_info"
    }
}
