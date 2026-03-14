import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel

    var body: some View {
        TabView {
            DiscoverView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    MiniPlayerView()
                }
                .tabItem {
                    Label("Discover", systemImage: "antenna.radiowaves.left.and.right")
                }

            RecentStationsView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    MiniPlayerView()
                }
                .tabItem {
                    Label("Recent", systemImage: "clock")
                }

            SearchView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    MiniPlayerView()
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            BrowseView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    MiniPlayerView()
                }
                .tabItem {
                    Label("Browse", systemImage: "list.bullet")
                }

            FavoritesView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    MiniPlayerView()
                }
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
    }
}
