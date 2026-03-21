import SwiftUI

struct FaviconImageView: View {
    let url: URL?
    let size: CGFloat

    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
                    .padding(size * 0.15)
            }
        }
        .frame(width: size, height: size)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
        .accessibilityHidden(true)
        .task(id: url) {
            guard let url else {
                loadedImage = nil
                return
            }
            loadedImage = ImageCacheService.shared.cachedImage(for: url)
            if loadedImage == nil {
                loadedImage = await ImageCacheService.shared.image(for: url)
            }
        }
    }
}
