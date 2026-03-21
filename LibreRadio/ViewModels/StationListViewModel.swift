import Foundation

@MainActor
final class StationListViewModel: ObservableObject {
    enum Filter {
        case country(String)
        case language(String)
        case tag(String)
    }

    let filter: Filter
    let title: String

    @Published var stations: [StationDTO] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: AppError?
    @Published var hasMore = true
    @Published var sortOrder: StationSortOrder = .byClicks

    private var currentOffset = 0
    private let pageSize = 100
    private let service: RadioBrowserService

    init(filter: Filter, title: String? = nil, service: RadioBrowserService = .shared) {
        self.filter = filter
        self.service = service

        if let title {
            self.title = title
        } else {
            switch filter {
            case .country(let code):
                self.title = code
            case .language(let name):
                self.title = name.capitalized
            case .tag(let name):
                self.title = name.capitalized
            }
        }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        currentOffset = 0

        do {
            let result = try await fetchStations(offset: 0)
            stations = result
            hasMore = result.count == pageSize
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .networkUnavailable
        }

        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        currentOffset += pageSize

        do {
            let result = try await fetchStations(offset: currentOffset)
            stations.append(contentsOf: result)
            hasMore = result.count == pageSize
        } catch let appError as AppError {
            error = appError
            currentOffset -= pageSize
        } catch {
            self.error = .networkUnavailable
            currentOffset -= pageSize
        }

        isLoadingMore = false
    }

    func reloadForCurrentSort() async {
        isLoading = false
        stations = []
        hasMore = true
        currentOffset = 0
        error = nil
        await load()
    }

    var sectionedStations: [(letter: String, stations: [StationDTO])] {
        let grouped = Dictionary(grouping: stations) { station in
            let first = station.name.trimmingCharacters(in: .whitespaces).prefix(1)
            return first.isEmpty ? "#" : String(first).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (letter: $0.key, stations: $0.value) }
    }

    private func fetchStations(offset: Int) async throws -> [StationDTO] {
        let order = sortOrder.apiOrderParam
        let reverse = sortOrder.apiReverse
        switch filter {
        case .country(let code):
            return try await service.fetchStationsByCountry(code, order: order, reverse: reverse, limit: pageSize, offset: offset)
        case .language(let name):
            return try await service.fetchStationsByLanguage(name, order: order, reverse: reverse, limit: pageSize, offset: offset)
        case .tag(let name):
            return try await service.fetchStationsByTag(name, order: order, reverse: reverse, limit: pageSize, offset: offset)
        }
    }
}
