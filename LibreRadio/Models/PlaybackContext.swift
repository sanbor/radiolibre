import Foundation

enum PlaybackContextSource: Equatable {
    case favorites
    case recent
    case search
    case browse(title: String)
    case discoverFavorites
    case discoverRecent
    case discoverLocal
    case discoverTopClicks
    case discoverTopVotes
    case discoverRecentlyChanged
    case discoverCurrentlyPlaying
    case standalone
}

struct PlaybackContext {
    let source: PlaybackContextSource
    let stations: [StationDTO]
}
