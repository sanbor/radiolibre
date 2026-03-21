import SwiftUI

struct StationCarouselView: View {
    let title: String
    let stations: [StationDTO]
    let onStationTap: (StationDTO) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(stations) { station in
                        StationCardView(station: station) {
                            onStationTap(station)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
    }
}
