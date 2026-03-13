import SwiftUI

struct RecentStationsView: View {
    @StateObject private var viewModel = RecentStationsViewModel()
    @EnvironmentObject private var playerVM: PlayerViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.entries.isEmpty {
                    LoadingView(message: "Loading history...")
                } else if viewModel.entries.isEmpty {
                    emptyState
                } else {
                    stationList
                }
            }
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
                let isConnecting = playerVM.isLoading
                    && playerVM.currentStation?.stationuuid == entry.stationuuid
                RecentStationRow(entry: entry, isConnecting: isConnecting) {
                    playerVM.play(station: entry.toStationDTO())
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Row

private struct RecentStationRow: View {
    let entry: HistoryEntry
    var isConnecting: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "radio")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.secondary)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.body)
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    if isConnecting {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Connecting...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(entry.playedAt.relativeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let codec = entry.codec, !codec.isEmpty {
                        Text(codec)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }

                    Text(entry.bitrateLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
            .opacity(isConnecting ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
