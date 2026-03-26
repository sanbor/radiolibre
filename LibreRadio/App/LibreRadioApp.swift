import SwiftUI

@main
struct LibreRadioApp: App {
    @StateObject private var playerVM = PlayerViewModel.shared
    @StateObject private var favoritesVM = FavoritesViewModel()
    @StateObject private var networkMonitor = NetworkMonitorService()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(playerVM)
                .environmentObject(favoritesVM)
                .environmentObject(networkMonitor)
                .task {
                    NowPlayingService.shared.setAudioService(playerVM.audioService)
                    NowPlayingService.shared.setPlayerViewModel(playerVM)
                    NowPlayingService.shared.setFavoritesViewModel(favoritesVM)
                    await ServerDiscoveryService.shared.resolveIfNeeded()
                    await favoritesVM.load()
                }
        }
    }
}
