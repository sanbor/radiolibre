import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favoritesVM: FavoritesViewModel
    @EnvironmentObject private var playerVM: PlayerViewModel

    var body: some View {
        NavigationStack {
            Group {
                if favoritesVM.isLoading && favoritesVM.favorites.isEmpty {
                    LoadingView(message: "Loading favorites...")
                } else if favoritesVM.favorites.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .task { await favoritesVM.load() }
            .refreshable { await favoritesVM.refresh() }
            .toolbar {
                if !favoritesVM.favorites.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No favorites yet")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var favoritesList: some View {
        List {
            ForEach(favoritesVM.favorites) { favorite in
                let station = favorite.toStationDTO()
                let isConnecting = playerVM.isLoading
                    && playerVM.currentStation?.stationuuid == favorite.stationuuid
                StationRowView(station: station, isConnecting: isConnecting) {
                    playerVM.play(station: station)
                }
            }
            .onDelete { offsets in
                let sorted = favoritesVM.favorites
                for offset in offsets {
                    let fav = sorted[offset]
                    Task { await favoritesVM.removeFavorite(stationuuid: fav.stationuuid) }
                }
            }
            .onMove { source, destination in
                Task { await favoritesVM.moveFavorites(from: source, to: destination) }
            }
        }
        .listStyle(.insetGrouped)
    }
}
