import Foundation

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var localStations: [StationDTO] = []
    @Published var topByClicks: [StationDTO] = []
    @Published var topByVotes: [StationDTO] = []
    @Published var recentlyChanged: [StationDTO] = []
    @Published var currentlyPlaying: [StationDTO] = []
    @Published var isLoading = false
    @Published var error: AppError?

    private let service: RadioBrowserService

    init(service: RadioBrowserService = .shared) {
        self.service = service
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        let localCountry = Locale.current.region?.identifier ?? "US"

        do {
            async let local = service.fetchLocalStations(countrycode: localCountry, limit: 20)
            async let clicks = service.fetchTopByClicks(limit: 20)
            async let votes = service.fetchTopByVotes(limit: 20)
            async let changed = service.fetchLastChange(limit: 20)
            async let playing = service.fetchLastClick(limit: 20)

            localStations = try await local
            topByClicks = try await clicks
            topByVotes = try await votes
            recentlyChanged = try await changed
            currentlyPlaying = try await playing
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .networkUnavailable
        }

        isLoading = false
    }

    func refresh() async {
        isLoading = false // allow re-entry
        await load()
    }
}
