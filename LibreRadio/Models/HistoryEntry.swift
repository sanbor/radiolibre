import Foundation

struct HistoryEntry: Codable, Identifiable, Hashable, Sendable, StationConvertible {
    let id: UUID
    let stationuuid: String
    let name: String
    let urlResolved: String
    let faviconURL: String?
    let codec: String?
    let bitrate: Int
    let countrycode: String?
    let state: String?
    var playedAt: Date

    init(
        id: UUID = UUID(),
        stationuuid: String,
        name: String,
        urlResolved: String,
        faviconURL: String? = nil,
        codec: String? = nil,
        bitrate: Int = 0,
        countrycode: String? = nil,
        state: String? = nil,
        playedAt: Date = Date()
    ) {
        self.id = id
        self.stationuuid = stationuuid
        self.name = name
        self.urlResolved = urlResolved
        self.faviconURL = faviconURL
        self.codec = codec
        self.bitrate = bitrate
        self.countrycode = countrycode
        self.state = state
        self.playedAt = playedAt
    }

    init(from station: StationDTO) {
        self.id = UUID()
        self.stationuuid = station.stationuuid
        self.name = station.name
        self.urlResolved = station.urlResolved ?? station.url
        self.faviconURL = station.favicon
        self.codec = station.codec
        self.bitrate = station.bitrate ?? 0
        self.countrycode = station.countrycode
        self.state = station.state
        self.playedAt = Date()
    }

    var bitrateLabel: String {
        guard bitrate > 0 else { return "—" }
        return "\(bitrate)k"
    }

    // toStationDTO() provided by StationConvertible protocol default implementation.
}

extension Array where Element == HistoryEntry {
    /// Deduplicates entries by stationuuid, keeping the most recent entry per station,
    /// sorted by play count descending (tiebreak: most recent first).
    func deduplicatedByFrequency() -> [HistoryEntry] {
        var bestEntry: [String: HistoryEntry] = [:]
        var playCounts: [String: Int] = [:]

        for entry in self {
            playCounts[entry.stationuuid, default: 0] += 1
            if let existing = bestEntry[entry.stationuuid] {
                if entry.playedAt > existing.playedAt {
                    bestEntry[entry.stationuuid] = entry
                }
            } else {
                bestEntry[entry.stationuuid] = entry
            }
        }

        return bestEntry.values.sorted {
            let count0 = playCounts[$0.stationuuid, default: 0]
            let count1 = playCounts[$1.stationuuid, default: 0]
            if count0 != count1 { return count0 > count1 }
            return $0.playedAt > $1.playedAt
        }
    }

    /// Deduplicates entries by stationuuid, keeping the first (most recent) entry per station,
    /// preserving the original recency order.
    func deduplicatedByRecency() -> [HistoryEntry] {
        var seen = Set<String>()
        return filter { entry in
            guard !seen.contains(entry.stationuuid) else { return false }
            seen.insert(entry.stationuuid)
            return true
        }
    }
}

extension Date {
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    var relativeDescription: String {
        Self.relativeFormatter.localizedString(for: self, relativeTo: Date())
    }
}
