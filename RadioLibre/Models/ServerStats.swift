import Foundation

struct ServerStats: Codable, Sendable {
    let stations: Int
    let stationsBroken: Int
    let tags: Int
    let clicksLastHour: Int
    let clicksLastDay: Int
    let languages: Int
    let countries: Int

    enum CodingKeys: String, CodingKey {
        case stations
        case stationsBroken = "stations_broken"
        case tags
        case clicksLastHour = "clicks_last_hour"
        case clicksLastDay = "clicks_last_day"
        case languages, countries
    }
}
