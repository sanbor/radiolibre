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
        List {
            if !viewModel.favoriteStations.isEmpty {
                Section {
                    StationCarouselView(title: "Favorites", stations: viewModel.favoriteStations) { station in
                        let context = PlaybackContext(source: .homeFavorites, stations: viewModel.favoriteStations)
                        playerVM.play(station: station, context: context)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            if !viewModel.recentStations.isEmpty {
                Section {
                    StationCarouselView(title: "Recently Played", stations: viewModel.recentStations) { station in
                        let context = PlaybackContext(source: .homeRecent, stations: viewModel.recentStations)
                        playerVM.play(station: station, context: context)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            if !viewModel.localStations.isEmpty {
                Section {
                    StationCarouselView(title: "Local Stations", stations: viewModel.localStations) { station in
                        let context = PlaybackContext(source: .homeLocal, stations: viewModel.localStations)
                        playerVM.play(station: station, context: context)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            if !viewModel.topByClicks.isEmpty {
                Section {
                    StationCarouselView(title: "Top Stations", stations: viewModel.topByClicks) { station in
                        let context = PlaybackContext(source: .homeTopClicks, stations: viewModel.topByClicks)
                        playerVM.play(station: station, context: context)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            if !viewModel.topByVotes.isEmpty {
                Section {
                    StationCarouselView(title: "Most Voted", stations: viewModel.topByVotes) { station in
                        let context = PlaybackContext(source: .homeTopVotes, stations: viewModel.topByVotes)
                        playerVM.play(station: station, context: context)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
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
        .listStyle(.insetGrouped)
    }

    private func verticalSection(title: String, stations: [StationDTO], source: PlaybackContextSource) -> some View {
        Section(title) {
            ForEach(stations) { station in
                let isConnecting = playerVM.isLoading && playerVM.currentStation?.stationuuid == station.stationuuid
                StationRowView(station: station, isConnecting: isConnecting) {
                    let context = PlaybackContext(source: source, stations: stations)
                    playerVM.play(station: station, context: context)
                }
            }
        }
    }
}
