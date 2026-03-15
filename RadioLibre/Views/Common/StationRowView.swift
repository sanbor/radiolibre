import SwiftUI

struct StationRowView: View {
    @EnvironmentObject private var favoritesVM: FavoritesViewModel
    @EnvironmentObject private var playerVM: PlayerViewModel
    @Environment(\.openURL) private var openURL

    let station: StationDTO
    var isConnecting: Bool = false
    var onTap: (() -> Void)?

    private var stationAccessibilityLabel: String {
        var parts = [station.name]
        if let codec = station.codec, !codec.isEmpty { parts.append(codec) }
        if let bitrate = station.bitrate, bitrate > 0 { parts.append("\(bitrate) kbps") }
        if let country = station.country, !country.isEmpty { parts.append(country) }
        if isConnecting { parts.append("Connecting") }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                FaviconImageView(url: station.faviconURL, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
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
                    } else if !station.tagList.isEmpty {
                        Text(station.tagList.prefix(3).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if !isConnecting, let locationLabel = station.locationLabel {
                        HStack(spacing: 4) {
                            if let flag = station.flagEmoji {
                                Text(flag).font(.caption2)
                            }
                            Text(locationLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let codec = station.codec, !codec.isEmpty {
                        Text(codec)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }

                    if let country = station.country, !country.isEmpty {
                        HStack(spacing: 2) {
                            if let flag = station.flagEmoji {
                                Text(flag).font(.caption2)
                            }
                            Text(country)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
            .opacity(isConnecting ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stationAccessibilityLabel)
        .accessibilityHint(favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "Favorite station" : "")
        .contextMenu {
            Button {
                onTap?()
            } label: {
                Label("Play", systemImage: "play.fill")
            }

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
                    favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "Remove Favorite" : "Add to Favorites",
                    systemImage: favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "heart.slash" : "heart"
                )
            }

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
        }
        .accessibilityAction(named: favoritesVM.isFavorite(stationuuid: station.stationuuid) ? "Remove Favorite" : "Add to Favorites") {
            Task {
                if favoritesVM.isFavorite(stationuuid: station.stationuuid) {
                    await favoritesVM.removeFavorite(stationuuid: station.stationuuid)
                } else {
                    await favoritesVM.addFavorite(station: station)
                }
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                Task {
                    if favoritesVM.isFavorite(stationuuid: station.stationuuid) {
                        await favoritesVM.removeFavorite(stationuuid: station.stationuuid)
                    } else {
                        await favoritesVM.addFavorite(station: station)
                    }
                }
            } label: {
                Image(systemName: favoritesVM.isFavorite(stationuuid: station.stationuuid)
                    ? "heart.slash.fill" : "heart.fill")
            }
            .tint(.pink)
        }
    }
}
