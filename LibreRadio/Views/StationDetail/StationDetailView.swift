import SwiftUI

struct StationDetailView: View {
    let station: StationDTO

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                FaviconImageView(url: station.faviconURL, size: 80)

                Text(station.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if !station.tagList.isEmpty {
                    tagChips
                }

                metadataGrid

                if let homepageURL = station.homepageURL {
                    Link(destination: homepageURL) {
                        Label("Homepage", systemImage: "globe")
                            .font(.subheadline)
                    }
                }

                if let streamURL = station.streamURL {
                    HStack {
                        Text("Stream")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(streamURL.absoluteString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(station.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tagChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(station.tagList, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
    }

    private var metadataGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            if let country = station.countryDisplayName, !country.isEmpty {
                metadataItem(title: "Country", value: "\(station.flagEmoji ?? "") \(country)")
            }
            if let language = station.language, !language.isEmpty {
                metadataItem(title: "Language", value: language.capitalized)
            }
            if let codec = station.codec, !codec.isEmpty {
                metadataItem(title: "Codec", value: codec)
            }
            if let bitrate = station.bitrate, bitrate > 0 {
                metadataItem(title: "Bitrate", value: "\(bitrate) kbps")
            }
            if let votes = station.votes {
                metadataItem(title: "Votes", value: "\(votes)")
            }
            if let clicks = station.clickcount {
                metadataItem(title: "Clicks", value: "\(clicks)")
            }
            metadataItem(title: "Status", value: station.isOnline ? "Online" : "Offline")
            if let lastCheck = station.lastcheckoktime {
                metadataItem(title: "Last Check", value: lastCheck)
            }
        }
        .padding(.horizontal)
    }

    private func metadataItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

