import Foundation

enum AppError: LocalizedError, Equatable {
    case networkUnavailable
    case serverDiscoveryFailed
    case serverError(statusCode: Int)
    case decodingFailed(message: String)
    case streamURLInvalid
    case audioSessionFailed(message: String)
    case playbackFailed(message: String)
    case noServersAvailable

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection"
        case .serverDiscoveryFailed:
            return "Could not discover radio servers"
        case .serverError(let statusCode):
            return "Server error (\(statusCode))"
        case .decodingFailed:
            return "Failed to read server response"
        case .streamURLInvalid:
            return "Invalid stream URL"
        case .audioSessionFailed:
            return "Audio session error"
        case .playbackFailed:
            return "Playback failed"
        case .noServersAvailable:
            return "No servers available"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .serverDiscoveryFailed, .noServersAvailable:
            return "The Radio Browser service may be temporarily unavailable. Try again later."
        case .serverError:
            return "Try again. If the problem persists, the server may be experiencing issues."
        case .decodingFailed:
            return "The server returned an unexpected response. Try again."
        case .streamURLInvalid:
            return "This station's stream URL is invalid. Try a different station."
        case .audioSessionFailed, .playbackFailed:
            return "Try playing the station again."
        }
    }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnavailable, .networkUnavailable),
             (.serverDiscoveryFailed, .serverDiscoveryFailed),
             (.streamURLInvalid, .streamURLInvalid),
             (.noServersAvailable, .noServersAvailable):
            return true
        case (.serverError(let a), .serverError(let b)):
            return a == b
        case (.decodingFailed(let a), .decodingFailed(let b)):
            return a == b
        case (.audioSessionFailed(let a), .audioSessionFailed(let b)):
            return a == b
        case (.playbackFailed(let a), .playbackFailed(let b)):
            return a == b
        default:
            return false
        }
    }
}
