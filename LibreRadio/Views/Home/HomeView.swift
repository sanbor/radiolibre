import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var playerVM: PlayerViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.topByClicks.isEmpty {
                    LoadingView(message: "Loading stations...")
                } else if let error = viewModel.error, viewModel.topByClicks.isEmpty {
                    ErrorView(error: error) {
                        await viewModel.refresh()
                    }
                } else {
                    stationsList
                }
            }
            .navigationTitle("Home")
            .task { await viewModel.load() }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var stationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if !viewModel.favoriteStations.isEmpty {
                    StationCarouselView(title: "Favorites", stations: viewModel.favoriteStations) { station in
                        let context = PlaybackContext(source: .homeFavorites, stations: viewModel.favoriteStations)
                        playerVM.play(station: station, context: context)
                    }
                }

                if !viewModel.recentStations.isEmpty {
                    StationCarouselView(title: "Recently Played", stations: viewModel.recentStations) { station in
                        let context = PlaybackContext(source: .homeRecent, stations: viewModel.recentStations)
                        playerVM.play(station: station, context: context)
                    }
                }

                if !viewModel.localStations.isEmpty {
                    StationCarouselView(title: "Local Stations", stations: viewModel.localStations) { station in
                        let context = PlaybackContext(source: .homeLocal, stations: viewModel.localStations)
                        playerVM.play(station: station, context: context)
                    }
                }

                if !viewModel.topByClicks.isEmpty {
                    StationCarouselView(title: "Top Stations", stations: viewModel.topByClicks) { station in
                        let context = PlaybackContext(source: .homeTopClicks, stations: viewModel.topByClicks)
                        playerVM.play(station: station, context: context)
                    }
                }

                if !viewModel.topByVotes.isEmpty {
                    StationCarouselView(title: "Most Voted", stations: viewModel.topByVotes) { station in
                        let context = PlaybackContext(source: .homeTopVotes, stations: viewModel.topByVotes)
                        playerVM.play(station: station, context: context)
                    }
                }

                if !viewModel.recentlyChanged.isEmpty {
                    verticalSection(
                        title: "Recently Changed",
                        stations: Array(viewModel.recentlyChanged.prefix(10)),
                        source: .homeRecentlyChanged
                    )
                }

                if !viewModel.currentlyPlaying.isEmpty {
                    verticalSection(
                        title: "Now Playing",
                        stations: Array(viewModel.currentlyPlaying.prefix(10)),
                        source: .homeCurrentlyPlaying
                    )
                }
            }
            .padding(.bottom, LayoutConstants.listBottomPadding)
        }
    }

    private func verticalSection(title: String, stations: [StationDTO], source: PlaybackContextSource) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2.bold())
                .padding(.horizontal, 20)
                .padding(.top, 8)

            VStack(spacing: 0) {
                ForEach(Array(stations.enumerated()), id: \.element.id) { index, station in
                    let isConnecting = playerVM.isLoading && playerVM.currentStation?.stationuuid == station.stationuuid
                    StationRowView(station: station, isConnecting: isConnecting) {
                        let context = PlaybackContext(source: source, stations: stations)
                        playerVM.play(station: station, context: context)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)

                    if index < stations.count - 1 {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 4)
    }
}
