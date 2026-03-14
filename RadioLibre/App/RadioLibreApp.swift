import SwiftUI

@main
struct RadioLibreApp: App {
    @StateObject private var playerVM = PlayerViewModel(audioService: .shared)
    @StateObject private var favoritesVM = FavoritesViewModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(playerVM)
                .environmentObject(favoritesVM)
                .task {
                    NowPlayingService.shared.setAudioService(playerVM.audioService)
                    await ServerDiscoveryService.shared.resolveIfNeeded()
                    await favoritesVM.load()
                }
        }
    }
}
