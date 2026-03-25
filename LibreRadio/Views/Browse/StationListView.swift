import SwiftUI

struct StationListView: View {
    @StateObject private var viewModel: StationListViewModel
    @EnvironmentObject private var playerVM: PlayerViewModel

    init(filter: StationListViewModel.Filter, title: String) {
        _viewModel = StateObject(wrappedValue: StationListViewModel(filter: filter, title: title))
    }

    var body: some View {
        AsyncContentView(
            isLoading: viewModel.isLoading,
            error: viewModel.error,
            isEmpty: viewModel.stations.isEmpty,
            loadingMessage: "Loading stations...",
            onRetry: { await viewModel.load() },
            emptyContent: { emptyView },
            content: { stationList }
        )
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Sort", selection: $viewModel.sortOrder) {
                    ForEach(StationSortOrder.allCases, id: \.self) { order in
                        Text(order.label).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
        }
        .onChange(of: viewModel.sortOrder) { _ in
            Task { await viewModel.reloadForCurrentSort() }
        }
        .task { await viewModel.load() }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No stations found")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stationList: some View {
        Group {
            if viewModel.sortOrder == .byName {
                alphabeticalList
            } else {
                flatList
            }
        }
    }

    private var alphabeticalList: some View {
        let sections = viewModel.sectionedStations
        let letters = sections.map(\.letter)

        return ScrollViewReader { proxy in
            List {
                ForEach(sections, id: \.letter) { section in
                    Section {
                        ForEach(section.stations) { station in
                            stationRow(station)
                        }
                    } header: {
                        Text(section.letter)
                    }
                    .id(section.letter)
                }

                if viewModel.isLoadingMore {
                    loadingMoreRow
                }

                Color.clear
                    .frame(height: LayoutConstants.listBottomPadding)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .trailing, spacing: 0) {
                AlphabetIndexView(letters: letters) { letter in
                    withAnimation {
                        proxy.scrollTo(letter, anchor: .top)
                    }
                }
            }
        }
    }

    private var flatList: some View {
        List {
            ForEach(viewModel.stations) { station in
                stationRow(station)
            }

            if viewModel.isLoadingMore {
                loadingMoreRow
            }

            Color.clear
                .frame(height: LayoutConstants.listBottomPadding)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private func stationRow(_ station: StationDTO) -> some View {
        let isConnecting = playerVM.isLoading && playerVM.currentStation?.stationuuid == station.stationuuid
        return StationRowView(station: station, isConnecting: isConnecting) {
            let context = PlaybackContext(
                source: .browse(title: viewModel.title),
                stations: viewModel.stations
            )
            playerVM.play(station: station, context: context)
        }
        .onAppear {
            if station.id == viewModel.stations.last?.id {
                Task { await viewModel.loadMore() }
            }
        }
    }

    private var loadingMoreRow: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowSeparator(.hidden)
    }
}
