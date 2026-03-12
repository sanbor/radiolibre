import Foundation

struct Tag: Codable, Identifiable, Sendable {
    var id: String { name }

    let name: String
    let stationcount: Int
}
