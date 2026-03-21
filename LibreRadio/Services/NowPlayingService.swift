import MediaPlayer
import UIKit

@MainActor
final class NowPlayingService {
    static let shared = NowPlayingService()

    private weak var audioService: AudioPlayerService?
    weak var playerViewModel: PlayerViewModel?
    private weak var favoritesViewModel: FavoritesViewModel?
    private var currentStationId: String?

    init() {
        setupRemoteCommands()
    }

    func setAudioService(_ service: AudioPlayerService) {
        self.audioService = service
    }

    func setPlayerViewModel(_ viewModel: PlayerViewModel) {
        self.playerViewModel = viewModel
    }

    func setFavoritesViewModel(_ viewModel: FavoritesViewModel) {
        self.favoritesViewModel = viewModel
    }

    // MARK: - Now Playing Info

    func updateNowPlaying(station: StationDTO, isPlaying: Bool) {
        currentStationId = station.stationuuid

        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = station.name
        info[MPMediaItemPropertyArtist] = buildArtistString(for: station)
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        fetchArtwork(for: station)
        updateLikeCommandState(stationuuid: station.stationuuid)
    }

    func updateStreamMetadata(title: String?, artist: String?, station: StationDTO) {
        guard station.stationuuid == currentStationId else { return }

        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = title ?? station.name
        if let artist {
            info[MPMediaItemPropertyArtist] = artist
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clearNowPlaying() {
        currentStationId = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func updateLikeCommandState(stationuuid: String) {
        guard stationuuid == currentStationId else { return }
        let isFavorite = favoritesViewModel?.isFavorite(stationuuid: stationuuid) ?? false
        MPRemoteCommandCenter.shared().likeCommand.isActive = isFavorite
    }

    // MARK: - Artwork

    private func fetchArtwork(for station: StationDTO) {
        guard let url = station.faviconURL else { return }
        let stationId = station.stationuuid

        Task {
            guard let image = await ImageCacheService.shared.image(for: url) else { return }
            guard currentStationId == stationId else { return }

            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            info[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    // MARK: - Artist String

    private func buildArtistString(for station: StationDTO) -> String {
        var parts: [String] = []

        if let country = station.countryDisplayName {
            parts.append(country)
        }

        var codecBitrate: [String] = []
        if let codec = station.codec, !codec.isEmpty {
            codecBitrate.append(codec)
        }
        if let bitrate = station.bitrate, bitrate > 0 {
            codecBitrate.append(station.bitrateLabel)
        }
        if !codecBitrate.isEmpty {
            parts.append(codecBitrate.joined(separator: " "))
        }

        return parts.isEmpty ? station.name : parts.joined(separator: " · ")
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            self?.audioService?.resume()
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            self?.audioService?.pause()
            return .success
        }

        center.stopCommand.isEnabled = true
        center.stopCommand.addTarget { [weak self] _ in
            self?.audioService?.stop()
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.audioService?.togglePlayPause()
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                await self?.playerViewModel?.playNext()
            }
            return .success
        }

        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                await self?.playerViewModel?.playPrevious()
            }
            return .success
        }

        center.likeCommand.isEnabled = true
        center.likeCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.handleLikeCommand()
            }
            return .success
        }
    }

    private func handleLikeCommand() {
        guard let station = audioService?.currentStation,
              let favoritesVM = favoritesViewModel else { return }

        Task {
            if favoritesVM.isFavorite(stationuuid: station.stationuuid) {
                await favoritesVM.removeFavorite(stationuuid: station.stationuuid)
            } else {
                await favoritesVM.addFavorite(station: station)
            }
            updateLikeCommandState(stationuuid: station.stationuuid)
        }
    }
}
