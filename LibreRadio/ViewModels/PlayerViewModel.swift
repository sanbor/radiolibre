import Foundation
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    static let shared = PlayerViewModel(audioService: .shared)

    let audioService: AudioPlayerService
    private let radioBrowserService: RadioBrowserService
    private let historyService: HistoryService
    private let favoritesService: FavoritesService
    private var cancellable: AnyCancellable?
    /// Exposed for testing – lets callers await the fire-and-forget history write.
    private(set) var historyTask: Task<Void, Never>?
    @Published private(set) var playbackContext: PlaybackContext?

    @MainActor
    init(
        audioService: AudioPlayerService,
        radioBrowserService: RadioBrowserService = .shared,
        historyService: HistoryService = .shared,
        favoritesService: FavoritesService = .shared
    ) {
        self.audioService = audioService
        self.radioBrowserService = radioBrowserService
        self.historyService = historyService
        self.favoritesService = favoritesService

        // Forward audioService state changes to trigger objectWillChange.
        // Uses Combine because ObservableObject.objectWillChange is a Combine publisher
        // and there's no pure-Swift-concurrency alternative on iOS 16 (pre-@Observable).
        cancellable = audioService.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    // MARK: - Computed Properties

    var currentStation: StationDTO? {
        audioService.currentStation
    }

    var isPlaying: Bool {
        audioService.isPlaying
    }

    var isLoading: Bool {
        audioService.isLoading
    }

    var isBuffering: Bool {
        audioService.isBuffering
    }

    var currentTrackTitle: String? {
        audioService.currentTrackTitle
    }

    var currentArtist: String? {
        audioService.currentArtist
    }

    var errorMessage: String? {
        if case .error(_, let message) = audioService.state {
            return message
        }
        return nil
    }

    var state: AudioPlayerService.PlaybackState {
        audioService.state
    }

    // MARK: - Actions

    var canSkipTrack: Bool {
        guard let context = playbackContext,
              context.source != .standalone,
              context.stations.count > 1,
              currentStation != nil else {
            return false
        }
        return true
    }

    func play(station: StationDTO, context: PlaybackContext? = nil) {
        playbackContext = context ?? PlaybackContext(source: .standalone, stations: [station])
        audioService.play(station: station)
        historyTask = Task {
            await historyService.recordPlay(station: station)
        }
    }

    func togglePlayPause() {
        audioService.togglePlayPause()
    }

    func stop() {
        audioService.stop()
    }

    func vote(station: StationDTO) async throws -> VoteResponse {
        try await radioBrowserService.vote(stationuuid: station.stationuuid)
    }

    func voteForCurrentStation() async -> String? {
        guard let station = currentStation else { return nil }
        do {
            let response = try await radioBrowserService.vote(stationuuid: station.stationuuid)
            return response.message
        } catch {
            return nil
        }
    }

    func playNext() async {
        guard let context = playbackContext, context.source != .standalone else { return }
        let stations = await resolveStations(for: context)
        guard stations.count > 1 else { return }

        let nextStation: StationDTO
        if let current = currentStation,
           let idx = stations.firstIndex(where: { $0.stationuuid == current.stationuuid }) {
            nextStation = stations[(idx + 1) % stations.count]
        } else {
            nextStation = stations[0]
        }
        playbackContext = PlaybackContext(source: context.source, stations: stations)
        play(station: nextStation, context: playbackContext)
    }

    func playPrevious() async {
        guard let context = playbackContext, context.source != .standalone else { return }
        let stations = await resolveStations(for: context)
        guard stations.count > 1 else { return }

        let prevStation: StationDTO
        if let current = currentStation,
           let idx = stations.firstIndex(where: { $0.stationuuid == current.stationuuid }) {
            prevStation = stations[(idx - 1 + stations.count) % stations.count]
        } else {
            prevStation = stations[0]
        }
        playbackContext = PlaybackContext(source: context.source, stations: stations)
        play(station: prevStation, context: playbackContext)
    }

    private func resolveStations(for context: PlaybackContext) async -> [StationDTO] {
        switch context.source {
        case .favorites, .discoverFavorites:
            let favorites = await favoritesService.allFavorites()
            return favorites.map { $0.toStationDTO() }
        case .recent, .discoverRecent:
            let entries = await historyService.recentEntries(limit: 50)
            return entries.map { $0.toStationDTO() }
        default:
            return context.stations
        }
    }
}
