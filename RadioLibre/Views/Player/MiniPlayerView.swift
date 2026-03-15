import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var favoritesVM: FavoritesViewModel
    @State private var showFullPlayer = false

    var body: some View {
        Group {
            if let station = playerVM.currentStation {
                Button {
                    showFullPlayer = true
                } label: {
                    activeContent(station: station)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showFullPlayer) {
                    FullPlayerView()
                }
            } else {
                idleContent
            }
        }
        .background(.ultraThinMaterial)
    }

    private func activeContent(station: StationDTO) -> some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    if favoritesVM.isFavorite(stationuuid: station.stationuuid) {
                        await favoritesVM.removeFavorite(stationuuid: station.stationuuid)
                    } else {
                        await favoritesVM.addFavorite(station: station)
                    }
                }
            } label: {
                Image(systemName: favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "heart.fill" : "heart")
                    .font(.body)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .tint(.pink)
            .foregroundStyle(.pink)
            .accessibilityLabel(favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "Remove from Favorites" : "Add to Favorites")

            FaviconImageView(url: station.faviconURL, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                if playerVM.isLoading {
                    Text("Connecting...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if playerVM.isBuffering {
                    Text("Buffering...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let errorMessage = playerVM.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else if let codec = station.codec, !codec.isEmpty {
                    Text("\(codec) \u{00B7} \(station.bitrateLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Play/Pause button
            Button {
                playerVM.togglePlayPause()
            } label: {
                Group {
                    if playerVM.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playerVM.isPlaying ? "Pause" : "Play")

            // Stop button
            Button {
                playerVM.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Stop")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var idleContent: some View {
        HStack(spacing: 12) {
            FaviconImageView(url: nil, size: 40)

            Text("Not Playing")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
