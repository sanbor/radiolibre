import Foundation

struct ClickResponse: Codable, Sendable {
    let ok: String
    let message: String
    let stationuuid: String
    let name: String
    let url: String
}
