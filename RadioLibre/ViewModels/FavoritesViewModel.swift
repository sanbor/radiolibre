import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteStation] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var error: String?

    private let favoritesService: FavoritesService

    init(favoritesService: FavoritesService = .shared) {
        self.favoritesService = favoritesService
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        favorites = await favoritesService.allFavorites()
        isLoading = false
    }

    func refresh() async {
        guard !isSyncing else { return }
        isSyncing = true
        await favoritesService.syncWithServer()
        favorites = await favoritesService.allFavorites()
        isSyncing = false
    }

    func addFavorite(station: StationDTO) async {
        await favoritesService.addFavorite(station: station)
        favorites = await favoritesService.allFavorites()
    }

    func removeFavorite(stationuuid: String) async {
        await favoritesService.removeFavorite(stationuuid: stationuuid)
        favorites = await favoritesService.allFavorites()
    }

    func isFavorite(stationuuid: String) -> Bool {
        favorites.contains { $0.stationuuid == stationuuid }
    }

    func moveFavorites(from source: IndexSet, to destination: Int) async {
        await favoritesService.moveFavorites(from: source, to: destination)
        favorites = await favoritesService.allFavorites()
    }
}
