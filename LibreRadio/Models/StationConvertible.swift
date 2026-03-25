import Foundation

/// Shared interface for types that can be converted to a StationDTO.
/// Provides a default `toStationDTO()` implementation, eliminating duplicate
/// 25-field initializer boilerplate in FavoriteStation and HistoryEntry.
protocol StationConvertible {
    var stationuuid: String { get }
    var name: String { get }
    var urlResolved: String { get }
    var faviconURL: String? { get }
    var countrycode: String? { get }
    var state: String? { get }
    var codec: String? { get }
    var bitrate: Int { get }
    // Optional — types that have these provide them; others get nil via defaults.
    var tags: String? { get }
    var language: String? { get }
}

extension StationConvertible {
    var tags: String? { nil }
    var language: String? { nil }

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
            state: state,
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
