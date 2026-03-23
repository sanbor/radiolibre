import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var favoritesVM: FavoritesViewModel

    @State private var voteMessage: String?
    @State private var showTrackHistory = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundStyle(.blue)
                }

                if let station = playerVM.currentStation {
                    stationContent(station: station)
                } else {
                    Text("No station selected")
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: playerVM.currentStation == nil) { isNil in
            if isNil { dismiss() }
        }
    }

    private func stationContent(station: StationDTO) -> some View {
        VStack(spacing: 20) {
            // Large favicon
            FaviconImageView(url: station.faviconURL, size: 120)

            // Station name
            Text(station.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Country / Subdivision
            if let country = station.countryDisplayName, !country.isEmpty {
                HStack(spacing: 8) {
                    if let flag = station.flagEmoji {
                        Text(flag)
                    }
                    if let state = station.state, !state.isEmpty {
                        Text("\(country), \(state)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(country)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Now playing track info with browse controls
            trackInfoSection(station: station)

            // Player controls
            PlayerControlsView()

            // Favorite + Vote
            HStack(spacing: 24) {
                Button {
                    Task {
                        if favoritesVM.isFavorite(stationuuid: station.stationuuid) {
                            await favoritesVM.removeFavorite(stationuuid: station.stationuuid)
                        } else {
                            await favoritesVM.addFavorite(station: station)
                        }
                    }
                } label: {
                    Label(
                        favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "Unfavorite" : "Favorite",
                        systemImage: favoritesVM.isFavorite(stationuuid: station.stationuuid)
                            ? "star.fill" : "star"
                    )
                    .font(.subheadline)
                }
                .tint(.orange)
                .accessibilityLabel(
                    favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "Remove from Favorites" : "Add to Favorites"
                )

                Button {
                    Task {
                        if let message = await playerVM.voteForCurrentStation() {
                            voteMessage = message
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            voteMessage = nil
                        }
                    }
                } label: {
                    Label("Vote", systemImage: "hand.thumbsup")
                        .font(.subheadline)
                }
            }

            if let voteMessage {
                Text(voteMessage)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }

            // Tags
            if !station.tagList.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(station.tagList, id: \.self) { tag in
                        TagChipView(tag: tag)
                    }
                }
            }

            // Metadata
            VStack(spacing: 8) {
                if let codec = station.codec, !codec.isEmpty {
                    metadataRow(label: "Codec", value: codec)
                }
                if let bitrate = station.bitrate, bitrate > 0 {
                    metadataRow(label: "Bitrate", value: "\(bitrate) kbps")
                }
                if let lastCheck = station.lastcheckoktime {
                    metadataRow(label: "Last Check", value: lastCheck)
                }
                metadataRow(label: "Status", value: station.isOnline ? "Online" : "Offline")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Homepage link
            if let homepageURL = station.homepageURL {
                Link(destination: homepageURL) {
                    Label("Visit Station", systemImage: "globe")
                        .font(.subheadline)
                }
            }

            // Radio Browser link
            if let radioBrowserURL = URL(string: "https://www.radio-browser.info/history/\(station.stationuuid)") {
                Link(destination: radioBrowserURL) {
                    Label("Radio Browser", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.subheadline)
                }
            }

            Spacer(minLength: 20)
        }
        .sheet(isPresented: $showTrackHistory) {
            TrackHistorySheet()
                .environmentObject(playerVM)
        }
    }

    @ViewBuilder
    private func trackInfoSection(station: StationDTO) -> some View {
        let hasHistory = !playerVM.trackHistory.isEmpty

        HStack(spacing: 12) {
            if hasHistory {
                Button { playerVM.browseTrackBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(!playerVM.canBrowseBack)
                .opacity(playerVM.canBrowseBack ? 1 : 0.3)
                .accessibilityLabel("Previous Track")
            }

            VStack(spacing: 4) {
                if let title = playerVM.browsedTrackTitle {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    if let artist = playerVM.browsedArtist {
                        Text(artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                } else {
                    Text(station.name)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                if playerVM.isBrowsingHistory {
                    Text("Browsing history")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { showTrackHistory = true }
            .animation(.easeInOut, value: playerVM.browsedTrackTitle)
            .animation(.easeInOut, value: playerVM.browsedArtist)

            if hasHistory {
                Button { playerVM.browseTrackForward() } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(!playerVM.canBrowseForward)
                .opacity(playerVM.canBrowseForward ? 1 : 0)
                .accessibilityLabel("Next Track")
            }
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}
