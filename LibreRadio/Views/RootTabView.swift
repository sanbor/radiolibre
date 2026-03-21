import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var networkMonitor: NetworkMonitorService

    @State private var showFullPlayer = false

    var body: some View {
        TabView {
            DiscoverView()
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayerSpacer }
                .tabItem {
                    Label("Discover", systemImage: "antenna.radiowaves.left.and.right")
                }

            RecentStationsView()
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayerSpacer }
                .tabItem {
                    Label("Recent", systemImage: "clock")
                }

            SearchView()
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayerSpacer }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            BrowseView()
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayerSpacer }
                .tabItem {
                    Label("Browse", systemImage: "list.bullet")
                }

            FavoritesView()
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayerSpacer }
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
        .overlay(alignment: .bottom) {
            miniPlayerBar
        }
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if !networkMonitor.isConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("No Internet Connection")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red)
            }
        }
    }

    private var miniPlayerBar: some View {
        MiniPlayerView(station: playerVM.currentStation)
            .background(.ultraThinMaterial)
            .contentShape(Rectangle())
            .onTapGesture {
                if playerVM.currentStation != nil {
                    showFullPlayer = true
                }
            }
            .padding(.bottom, LayoutConstants.tabBarHeight)
    }

    private var miniPlayerSpacer: some View {
        Color.clear.frame(height: LayoutConstants.miniPlayerHeight)
    }
}
