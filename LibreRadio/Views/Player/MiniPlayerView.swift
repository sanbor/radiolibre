import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var favoritesVM: FavoritesViewModel

    @Environment(\.openURL) private var openURL

    @State private var barWidth: CGFloat = 0

    let station: StationDTO?
    var onTapInfo: (() -> Void)?

    private var showAllControls: Bool { barWidth > 500 }

    var body: some View {
        Group {
            if let station {
                activeContent(station: station)
            } else {
                idleContent
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { barWidth = geo.size.width }
                    .onChange(of: geo.size.width) { barWidth = $0 }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: station != nil)
    }

    // MARK: - Idle State

    private var idleContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)

            Text("No station playing")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Active State

    private func activeContent(station: StationDTO) -> some View {
        HStack(spacing: 8) {
            // Leading: favorite
            favoriteButton(station: station)

            // Center: station identity (tappable to open full player)
            HStack(spacing: 10) {
                FaviconImageView(url: station.faviconURL, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    subtitleView(station: station)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onTapInfo?() }

            // Trailing: transport + extras
            HStack(spacing: 0) {
                if showAllControls {
                    previousButton
                }

                playPauseButton

                if showAllControls {
                    nextButton
                    moreMenu(station: station)
                    volumeButton
                    if playerVM.audioService.hasExternalRoutes {
                        airPlayButton
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Buttons

    private func favoriteButton(station: StationDTO) -> some View {
        Button {
            Task {
                if favoritesVM.isFavorite(stationuuid: station.stationuuid) {
                    await favoritesVM.removeFavorite(stationuuid: station.stationuuid)
                } else {
                    await favoritesVM.addFavorite(station: station)
                }
            }
        } label: {
            Image(systemName: favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "star.fill" : "star")
                .font(.callout)
                .frame(width: 28, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.orange)
        .accessibilityLabel(favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "Remove from Favorites" : "Add to Favorites")
    }

    private var previousButton: some View {
        Button {
            Task { await playerVM.playPrevious() }
        } label: {
            Image(systemName: "backward.fill")
                .font(.body)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!playerVM.canSkipTrack)
        .opacity(playerVM.canSkipTrack ? 1 : 0.3)
        .accessibilityLabel("Previous Station")
    }

    private var playPauseButton: some View {
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playerVM.isPlaying ? "Pause" : "Play")
    }

    private var nextButton: some View {
        Button {
            Task { await playerVM.playNext() }
        } label: {
            Image(systemName: "forward.fill")
                .font(.body)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!playerVM.canSkipTrack)
        .opacity(playerVM.canSkipTrack ? 1 : 0.3)
        .accessibilityLabel("Next Station")
    }

    private func moreMenu(station: StationDTO) -> some View {
        Menu {
            Button {
                Task {
                    _ = try? await playerVM.vote(station: station)
                }
            } label: {
                Label("Vote", systemImage: "hand.thumbsup")
            }

            if let streamURL = station.streamURL {
                Button {
                    UIPasteboard.general.string = streamURL.absoluteString
                } label: {
                    Label("Copy Stream URL", systemImage: "doc.on.doc")
                }

                ShareLink(item: streamURL) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }

            if let homepageURL = station.homepageURL {
                Button {
                    openURL(homepageURL)
                } label: {
                    Label("Visit Website", systemImage: "globe")
                }
            }

            Divider()

            Button(role: .destructive) {
                playerVM.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More Options")
    }

    private var volumeButton: some View {
        Menu {
            // Menu doesn't support sliders, so provide preset levels
            Button {
                playerVM.audioService.volume = 0
            } label: {
                Label("Mute", systemImage: "speaker.slash.fill")
            }

            Button {
                playerVM.audioService.volume = 0.25
            } label: {
                Label("25%", systemImage: "speaker.wave.1.fill")
            }

            Button {
                playerVM.audioService.volume = 0.5
            } label: {
                Label("50%", systemImage: "speaker.wave.2.fill")
            }

            Button {
                playerVM.audioService.volume = 0.75
            } label: {
                Label("75%", systemImage: "speaker.wave.2.fill")
            }

            Button {
                playerVM.audioService.volume = 1.0
            } label: {
                Label("100%", systemImage: "speaker.wave.3.fill")
            }
        } label: {
            Image(systemName: volumeIconName)
                .font(.body)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Volume")
    }

    private var volumeIconName: String {
        let vol = playerVM.audioService.volume
        if vol == 0 { return "speaker.slash.fill" }
        if vol < 0.33 { return "speaker.wave.1.fill" }
        if vol < 0.66 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    private var airPlayButton: some View {
        AirPlayButton()
            .frame(width: 44, height: 44)
            .accessibilityLabel("AirPlay")
    }

    // MARK: - Subtitle

    @ViewBuilder
    private func subtitleView(station: StationDTO) -> some View {
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
        } else if let title = playerVM.currentTrackTitle {
            Text(playerVM.currentArtist.map { "\($0) — \(title)" } ?? title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        } else if let codec = station.codec, !codec.isEmpty {
            Text("\(codec) \u{00B7} \(station.bitrateLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
