import SwiftUI

struct StationCarouselView: View {
    let title: String
    let stations: [StationDTO]
    let onStationTap: (StationDTO) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2.bold())
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(stations) { station in
                        StationCardView(station: station) {
                            onStationTap(station)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}
