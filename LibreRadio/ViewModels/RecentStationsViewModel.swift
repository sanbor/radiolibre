import Foundation

@MainActor
final class RecentStationsViewModel: ObservableObject {
    @Published var entries: [HistoryEntry] = []
    @Published var isLoading = false
    @Published var showClearConfirmation = false

    private let historyService: HistoryService

    init(historyService: HistoryService = .shared) {
        self.historyService = historyService
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        entries = await historyService.allEntries().deduplicatedByRecency()
        isLoading = false
    }

    func refresh() async {
        isLoading = false
        await load()
    }

    func clearAll() async {
        await historyService.clearAll()
        entries = []
    }
}
