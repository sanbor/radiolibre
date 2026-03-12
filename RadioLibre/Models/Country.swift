import Foundation

struct Country: Codable, Identifiable, Sendable {
    var id: String { name }

    let name: String
    let iso_3166_1: String
    let stationcount: Int
}
