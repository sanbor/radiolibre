import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
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
                    // Full player wired in Phase 5
                    Text("Full Player — Coming Soon")
                }
            } else {
                idleContent
            }
        }
        .background(.ultraThinMaterial)
    }

    private func activeContent(station: StationDTO) -> some View {
        HStack(spacing: 12) {
            // Favicon placeholder (Phase 5 adds FaviconImageView)
            Image(systemName: "radio")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundStyle(.secondary)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

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

            // Stop button
            Button {
                playerVM.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var idleContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "radio")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundStyle(.secondary)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

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
