import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var networkMonitor: NetworkMonitorService

    @State private var showFullPlayer = false

    var body: some View {
        TabView {
            HomeView()
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayerSpacer }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
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
                    Label("Favorites", systemImage: "star.fill")
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
        MiniPlayerView(station: playerVM.currentStation, onTapInfo: {
                showFullPlayer = true
            })
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.miniPlayerCornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    // Specular highlight — frosted glass top edge
                    RoundedRectangle(cornerRadius: LayoutConstants.miniPlayerCornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.18), .white.opacity(0.05), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.miniPlayerCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.miniPlayerCornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
            .shadow(color: .black.opacity(0.15), radius: LayoutConstants.miniPlayerShadowRadius, y: LayoutConstants.miniPlayerShadowY)
            .padding(.horizontal, LayoutConstants.miniPlayerHorizontalMargin)
            .padding(.bottom, LayoutConstants.tabBarHeight + LayoutConstants.miniPlayerBottomGap)
    }

    private var miniPlayerSpacer: some View {
        Color.clear.frame(height: LayoutConstants.miniPlayerHeight)
    }
}
