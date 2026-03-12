import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.topByClicks.isEmpty {
                    LoadingView(message: "Discovering stations...")
                } else if let error = viewModel.error, viewModel.topByClicks.isEmpty {
                    ErrorView(error: error) {
                        await viewModel.refresh()
                    }
                } else {
                    stationsList
                }
            }
            .navigationTitle("Discover")
            .task { await viewModel.load() }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var stationsList: some View {
        List {
            if !viewModel.localStations.isEmpty {
                stationSection(title: "Local Stations", stations: viewModel.localStations)
            }

            if !viewModel.topByClicks.isEmpty {
                stationSection(title: "Top Stations", stations: viewModel.topByClicks)
            }

            if !viewModel.topByVotes.isEmpty {
                stationSection(title: "Most Voted", stations: viewModel.topByVotes)
            }

            if !viewModel.recentlyChanged.isEmpty {
                stationSection(
                    title: "Recently Changed",
                    stations: Array(viewModel.recentlyChanged.prefix(10))
                )
            }

            if !viewModel.currentlyPlaying.isEmpty {
                stationSection(
                    title: "Now Playing",
                    stations: Array(viewModel.currentlyPlaying.prefix(10))
                )
            }
        }
        .listStyle(.insetGrouped)
    }

    private func stationSection(title: String, stations: [StationDTO]) -> some View {
        Section(title) {
            ForEach(stations) { station in
                StationRowView(station: station) {
                    // Playback wired in Phase 2
                }
            }
        }
    }
}
