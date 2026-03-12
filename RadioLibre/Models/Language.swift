import Foundation

struct Language: Codable, Identifiable, Sendable {
    var id: String { name }

    let name: String
    let iso_639: String?
    let stationcount: Int
}
