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
            if hasActiveFilters {
                filterChipsSection
            }

            ForEach(viewModel.results) { station in
                let isConnecting = playerVM.isLoading && playerVM.currentStation?.stationuuid == station.stationuuid
                StationRowView(station: station, isConnecting: isConnecting) {
                    playerVM.play(station: station)
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
        }
        .listStyle(.plain)
    }

    private var filterChipsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let code = viewModel.filterCountrycode {
                        filterChip(label: "Country: \(code)") {
                            viewModel.filterCountrycode = nil
                            Task { await viewModel.performSearch() }
                        }
                    }
                    if let lang = viewModel.filterLanguage {
                        filterChip(label: "Language: \(lang)") {
                            viewModel.filterLanguage = nil
                            Task { await viewModel.performSearch() }
                        }
                    }
                    if let codec = viewModel.filterCodec {
                        filterChip(label: "Codec: \(codec)") {
                            viewModel.filterCodec = nil
                            Task { await viewModel.performSearch() }
                        }
                    }
                    if let bitrate = viewModel.filterBitrateMin {
                        filterChip(label: "Min: \(bitrate)k") {
                            viewModel.filterBitrateMin = nil
                            Task { await viewModel.performSearch() }
                        }
                    }

                    Button("Clear All") {
                        viewModel.clearFilters()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func filterChip(label: String, onRemove: @escaping () -> Void) -> some View {
        Button(action: onRemove) {
            HStack(spacing: 4) {
                Text(label)
                Image(systemName: "xmark.circle.fill")
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var hasActiveFilters: Bool {
        viewModel.filterCountrycode != nil ||
        viewModel.filterLanguage != nil ||
        viewModel.filterCodec != nil ||
        viewModel.filterBitrateMin != nil
    }
}
