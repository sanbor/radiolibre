import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    static let shared = PlayerViewModel(audioService: .shared)

    let audioService: AudioPlayerService
    private let radioBrowserService: RadioBrowserService
    private let historyService: HistoryService
    private let favoritesService: FavoritesService
    private var observationTask: Task<Void, Never>?
    /// Exposed for testing – lets callers await the fire-and-forget history write.
    private(set) var historyTask: Task<Void, Never>?
    @Published private(set) var playbackContext: PlaybackContext?
    @Published var trackBrowseIndex: Int?

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
        // Polls on a short interval since ObservableObject.objectWillChange is Combine-based
        // and we avoid Combine per project conventions. The 0.1s interval keeps UI responsive
        // while avoiding Combine imports entirely.
        observationTask = Task { [weak self] in
            var lastState: AudioPlayerService.PlaybackState?
            var lastTrackTitle: String?
            var lastArtist: String?
            var lastIsBuffering: Bool?
            var lastVolume: Float?
            var lastTrackHistoryCount: Int?

            while !Task.isCancelled {
                guard let self else { return }
                let currentState = self.audioService.state
                let currentTitle = self.audioService.currentTrackTitle
                let currentArtist = self.audioService.currentArtist
                let currentBuffering = self.audioService.isBuffering
                let currentVolume = self.audioService.volume
                let currentHistoryCount = self.audioService.trackHistory.count

                if currentState != lastState
                    || currentTitle != lastTrackTitle
                    || currentArtist != lastArtist
                    || currentBuffering != lastIsBuffering
                    || currentVolume != lastVolume
                    || currentHistoryCount != lastTrackHistoryCount
                {
                    self.objectWillChange.send()
                    lastState = currentState
                    lastTrackTitle = currentTitle
                    lastArtist = currentArtist
                    lastIsBuffering = currentBuffering
                    lastVolume = currentVolume
                    lastTrackHistoryCount = currentHistoryCount
                }

                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
        }
    }

    deinit {
        observationTask?.cancel()
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

    var trackHistory: [TrackHistoryItem] {
        audioService.trackHistory
    }

    var browsedTrackTitle: String? {
        if let index = trackBrowseIndex, audioService.trackHistory.indices.contains(index) {
            return audioService.trackHistory[index].title
        }
        return audioService.currentTrackTitle
    }

    var browsedArtist: String? {
        if let index = trackBrowseIndex, audioService.trackHistory.indices.contains(index) {
            return audioService.trackHistory[index].artist
        }
        return audioService.currentArtist
    }

    var isBrowsingHistory: Bool {
        trackBrowseIndex != nil
    }

    var canBrowseBack: Bool {
        guard !audioService.trackHistory.isEmpty else { return false }
        if let index = trackBrowseIndex {
            return index > 0
        }
        return true
    }

    var canBrowseForward: Bool {
        trackBrowseIndex != nil
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

    func browseTrackBack() {
        guard !audioService.trackHistory.isEmpty else { return }
        if let currentIdx = trackBrowseIndex {
            guard currentIdx > 0 else { return }
            trackBrowseIndex = currentIdx - 1
        } else {
            trackBrowseIndex = audioService.trackHistory.count - 1
        }
    }

    func browseTrackForward() {
        guard let currentIdx = trackBrowseIndex else { return }
        let nextIdx = currentIdx + 1
        if nextIdx >= audioService.trackHistory.count - 1 {
            trackBrowseIndex = nil
        } else {
            trackBrowseIndex = nextIdx
        }
    }

    func play(station: StationDTO, context: PlaybackContext? = nil) {
        trackBrowseIndex = nil
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
        case .favorites, .homeFavorites:
            let favorites = await favoritesService.allFavorites()
            return favorites.map { $0.toStationDTO() }
        case .recent, .homeRecent:
            let entries = await historyService.recentEntries(limit: 50)
            return entries.map { $0.toStationDTO() }
        default:
            return context.stations
        }
    }
}
