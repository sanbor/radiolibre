import Foundation

enum PlaybackContextSource: Equatable {
    case favorites
    case recent
    case search
    case browse(title: String)
    case homeFavorites
    case homeRecent
    case homeLocal
    case homeTopClicks
    case homeTopVotes
    case homeRecentlyChanged
    case homeCurrentlyPlaying
    case standalone
}

struct PlaybackContext {
    let source: PlaybackContextSource
    let stations: [StationDTO]
}
