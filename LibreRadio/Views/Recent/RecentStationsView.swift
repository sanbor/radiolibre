import SwiftUI

struct RecentStationsView: View {
    @StateObject private var viewModel = RecentStationsViewModel()
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var favoritesVM: FavoritesViewModel

    var body: some View {
        NavigationStack {
            AsyncContentView(
                isLoading: viewModel.isLoading,
                error: nil,
                isEmpty: viewModel.entries.isEmpty,
                loadingMessage: "Loading history...",
                emptyContent: { emptyState },
                content: { stationList }
            )
            .navigationTitle("Recent")
            .task { await viewModel.load() }
            .refreshable { await viewModel.refresh() }
            .toolbar {
                if !viewModel.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            viewModel.showClearConfirmation = true
                        }
                    }
                }
            }
            .alert("Clear History", isPresented: $viewModel.showClearConfirmation) {
                Button("Clear All", role: .destructive) {
                    Task { await viewModel.clearAll() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all listening history.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No listening history")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stationList: some View {
        List {
            ForEach(viewModel.entries) { entry in
                let station = entry.toStationDTO()
                let isConnecting = playerVM.isLoading
                    && playerVM.currentStation?.stationuuid == entry.stationuuid
                StationRowView(
                    station: station,
                    subtitle: entry.playedAt.relativeDescription,
                    isConnecting: isConnecting
                ) {
                    let context = PlaybackContext(
                        source: .recent,
                        stations: viewModel.entries.map { $0.toStationDTO() }
                    )
                    playerVM.play(station: station, context: context)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

