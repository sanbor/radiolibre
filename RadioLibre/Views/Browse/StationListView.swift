import SwiftUI

struct StationListView: View {
    @StateObject private var viewModel: StationListViewModel
    @EnvironmentObject private var playerVM: PlayerViewModel

    init(filter: StationListViewModel.Filter, title: String) {
        _viewModel = StateObject(wrappedValue: StationListViewModel(filter: filter, title: title))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.stations.isEmpty {
                LoadingView(message: "Loading stations...")
            } else if let error = viewModel.error, viewModel.stations.isEmpty {
                ErrorView(error: error) {
                    await viewModel.load()
                }
            } else if viewModel.stations.isEmpty {
                emptyView
            } else {
                stationList
            }
        }
        .navigationTitle(viewModel.title)
        .task { await viewModel.load() }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "radio")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No stations found")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stationList: some View {
        List {
            ForEach(viewModel.stations) { station in
                let isConnecting = playerVM.isLoading && playerVM.currentStation?.stationuuid == station.stationuuid
                StationRowView(station: station, isConnecting: isConnecting) {
                    playerVM.play(station: station)
                }
                .onAppear {
                    if station.id == viewModel.stations.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }

            Color.clear
                .frame(height: 20)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
