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

        // Forward audioService state changes to trigger objectWillChange
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

    func play(station: StationDTO) {
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

    func playNextFavorite() async {
        let favorites = await favoritesService.allFavorites()
        guard !favorites.isEmpty else { return }

        if let current = currentStation,
           let idx = favorites.firstIndex(where: { $0.stationuuid == current.stationuuid }) {
            let next = favorites[(idx + 1) % favorites.count]
            play(station: next.toStationDTO())
        } else {
            play(station: favorites[0].toStationDTO())
        }
    }

    func playPreviousFavorite() async {
        let favorites = await favoritesService.allFavorites()
        guard !favorites.isEmpty else { return }

        if let current = currentStation,
           let idx = favorites.firstIndex(where: { $0.stationuuid == current.stationuuid }) {
            let prev = favorites[(idx - 1 + favorites.count) % favorites.count]
            play(station: prev.toStationDTO())
        } else {
            play(station: favorites[0].toStationDTO())
        }
    }
}
