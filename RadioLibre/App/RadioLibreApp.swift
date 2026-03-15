import SwiftUI

@main
struct RadioLibreApp: App {
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
                    LiveActivityService.shared.endOrphanedActivities()
                    await ServerDiscoveryService.shared.resolveIfNeeded()
                    await favoritesVM.load()
                }
        }
    }
}
