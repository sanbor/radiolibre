import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [StationDTO] = []
    @Published var isSearching = false
    @Published var hasSearched = false
    @Published var error: AppError?
    @Published var hasMore = true

    // Filters
    @Published var filterCountrycode: String?
    @Published var filterLanguage: String?
    @Published var filterCodec: String?
    @Published var filterBitrateMin: Int?

    private var currentOffset = 0
    private let pageSize = 50
    private var searchTask: Task<Void, Never>?
    private let service: RadioBrowserService

    init(service: RadioBrowserService = .shared) {
        self.service = service
    }

    func onQueryChanged() {
        searchTask?.cancel()
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 400_000_000)
            } catch {
                return // cancelled
            }
            await performSearch()
        }
    }

    func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            hasSearched = false
            error = nil
            return
        }

        isSearching = true
        error = nil
        currentOffset = 0

        do {
            let stations = try await service.searchStations(
                name: trimmed,
                countrycode: filterCountrycode,
                language: filterLanguage,
                codec: filterCodec,
                bitrateMin: filterBitrateMin,
                order: "clickcount",
                reverse: true,
                limit: pageSize,
                offset: 0
            )
            guard !Task.isCancelled else { return }
            results = stations
            hasMore = stations.count == pageSize
            hasSearched = true
        } catch is CancellationError {
            return
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .networkUnavailable
        }

        isSearching = false
    }

    func loadMore() async {
        guard hasMore, !isSearching else { return }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSearching = true
        currentOffset += pageSize

        do {
            let stations = try await service.searchStations(
                name: trimmed,
                countrycode: filterCountrycode,
                language: filterLanguage,
                codec: filterCodec,
                bitrateMin: filterBitrateMin,
                order: "clickcount",
                reverse: true,
                limit: pageSize,
                offset: currentOffset
            )
            guard !Task.isCancelled else {
                currentOffset -= pageSize
                return
            }
            results.append(contentsOf: stations)
            hasMore = stations.count == pageSize
        } catch is CancellationError {
            currentOffset -= pageSize
            return
        } catch let appError as AppError {
            error = appError
            currentOffset -= pageSize
        } catch {
            self.error = .networkUnavailable
            currentOffset -= pageSize
        }

        isSearching = false
    }

    func clearFilters() {
        filterCountrycode = nil
        filterLanguage = nil
        filterCodec = nil
        filterBitrateMin = nil
        if hasSearched {
            searchTask?.cancel()
            searchTask = Task {
                await performSearch()
            }
        }
    }
}
