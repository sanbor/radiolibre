import SwiftUI

struct StationRowView: View {
    @EnvironmentObject private var favoritesVM: FavoritesViewModel

    let station: StationDTO
    var isConnecting: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Favicon placeholder (Phase 5 adds ImageCacheService)
                Image(systemName: "radio")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.secondary)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

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

                    Text(station.bitrateLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
            .opacity(isConnecting ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
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
