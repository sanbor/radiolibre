import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var playerVM: PlayerViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSearching && viewModel.results.isEmpty && !viewModel.hasSearched {
                    LoadingView(message: "Searching...")
                } else if let error = viewModel.error, viewModel.results.isEmpty {
                    ErrorView(error: error) {
                        await viewModel.performSearch()
                    }
                } else if viewModel.hasSearched && viewModel.results.isEmpty {
                    noResultsView
                } else if viewModel.results.isEmpty {
                    placeholderView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: "Search for radio stations")
            .onChange(of: viewModel.query) { _ in
                viewModel.onQueryChanged()
            }
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Search for radio stations")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No stations found for '\(viewModel.query)'")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        List {
            if viewModel.hasActiveFilters {
                SearchFiltersView(viewModel: viewModel)
            }

            ForEach(viewModel.results) { station in
                let isConnecting = playerVM.isLoading && playerVM.currentStation?.stationuuid == station.stationuuid
                StationRowView(station: station, isConnecting: isConnecting) {
                    let context = PlaybackContext(
                        source: .search,
                        stations: viewModel.results
                    )
                    playerVM.play(station: station, context: context)
                }
                .onAppear {
                    if station.id == viewModel.results.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }

            if viewModel.isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }

            Color.clear
                .frame(height: LayoutConstants.listBottomPadding)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
