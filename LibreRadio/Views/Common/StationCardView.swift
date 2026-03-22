import SwiftUI

struct StationCardView: View {
    let station: StationDTO
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                FaviconImageView(url: station.faviconURL, size: 80)

                Text(station.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                if let locationLabel = station.locationLabel {
                    HStack(spacing: 2) {
                        if let flag = station.flagEmoji {
                            Text(flag).font(.caption)
                        }
                        Text(locationLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(" ")
                        .font(.caption)
                        .hidden()
                }
            }
            .frame(width: 160)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(station.name)
        .accessibilityHint("Double tap to play")
    }
}
