import UIKit
import CarPlay

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPTabBarTemplateDelegate {

    private var interfaceController: CPInterfaceController?

    private let favoritesTemplate = CPListTemplate(title: "Favorites", sections: [])
    private let recentsTemplate = CPListTemplate(title: "Recent", sections: [])
    private let popularTemplate = CPListTemplate(title: "Popular", sections: [])

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        favoritesTemplate.tabImage = UIImage(systemName: "star.fill")
        recentsTemplate.tabImage = UIImage(systemName: "clock.fill")
        popularTemplate.tabImage = UIImage(systemName: "chart.line.uptrend.xyaxis")

        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        nowPlayingTemplate.tabImage = UIImage(systemName: "play.fill")

        let tabBar = CPTabBarTemplate(templates: [
            favoritesTemplate,
            recentsTemplate,
            popularTemplate,
            nowPlayingTemplate
        ])
        tabBar.delegate = self

        interfaceController.setRootTemplate(tabBar, animated: false, completion: nil)
        reloadAll()
    }

    // MARK: - Scene lifecycle

    func sceneDidBecomeActive(_ scene: UIScene) {
        reloadAll()
    }

    // MARK: - CPTabBarTemplateDelegate

    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
        switch selectedTemplate {
        case favoritesTemplate: reloadFavorites()
        case recentsTemplate: reloadRecents()
        case popularTemplate: reloadPopular()
        default: break
        }
    }

    // MARK: - Data loading

    private func reloadAll() {
        reloadFavorites()
        reloadRecents()
        reloadPopular()
    }

    private func reloadFavorites() {
        Task { @MainActor in
            let stations = await FavoritesService.shared.allFavorites()
            let items = stations.map { fav in
                makeListItem(
                    name: fav.name,
                    codec: fav.codec,
                    bitrate: fav.bitrate,
                    faviconURLString: fav.faviconURL,
                    station: fav.toStationDTO()
                )
            }
            favoritesTemplate.updateSections([CPListSection(items: items)])
        }
    }

    private func reloadRecents() {
        Task { @MainActor in
            let entries = await HistoryService.shared.recentEntries(limit: 20)
            let items = entries.map { entry in
                makeListItem(
                    name: entry.name,
                    codec: entry.codec,
                    bitrate: entry.bitrate,
                    faviconURLString: entry.faviconURL,
                    station: entry.toStationDTO()
                )
            }
            recentsTemplate.updateSections([CPListSection(items: items)])
        }
    }

    private func reloadPopular() {
        Task { @MainActor in
            guard let stations = try? await RadioBrowserService.shared.fetchTopByClicks(limit: 30) else { return }
            let items = stations.map { dto in
                makeListItem(
                    name: dto.name,
                    codec: dto.codec,
                    bitrate: dto.bitrate.flatMap { $0 > 0 ? $0 : nil },
                    faviconURLString: dto.favicon,
                    station: dto
                )
            }
            popularTemplate.updateSections([CPListSection(items: items)])
        }
    }

    // MARK: - List item helpers
}

extension CarPlaySceneDelegate {
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }
}

extension CarPlaySceneDelegate {

    static func detailText(codec: String?, bitrate: Int?) -> String {
        let codecStr = codec?.uppercased() ?? ""
        let bitrateStr: String
        if let bitrate, bitrate > 0 {
            bitrateStr = "\(bitrate)k"
        } else {
            bitrateStr = ""
        }
        if !codecStr.isEmpty && !bitrateStr.isEmpty {
            return "\(codecStr) \(bitrateStr)"
        }
        return codecStr.isEmpty ? bitrateStr : codecStr
    }

    private func makeListItem(
        name: String,
        codec: String?,
        bitrate: Int?,
        faviconURLString: String?,
        station: StationDTO
    ) -> CPListItem {
        let placeholder = UIImage(systemName: "radio") ?? UIImage()

        var syncImage: UIImage?
        if let urlString = faviconURLString, let url = URL(string: urlString) {
            syncImage = ImageCacheService.shared.cachedImage(for: url)
        }

        let detail = Self.detailText(codec: codec, bitrate: bitrate)
        let item = CPListItem(
            text: name,
            detailText: detail.isEmpty ? nil : detail,
            image: syncImage ?? placeholder
        )

        // Async-load image if not in memory cache
        if syncImage == nil, let urlString = faviconURLString, let url = URL(string: urlString) {
            Task {
                if let image = await ImageCacheService.shared.image(for: url) {
                    item.setImage(image)
                }
            }
        }

        item.handler = { [weak self] _, completion in
            _ = self // retain reference for clarity
            Task { @MainActor in
                PlayerViewModel.shared.play(station: station)
            }
            completion()
        }

        return item
    }
}
